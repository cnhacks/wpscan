# encoding: UTF-8
#--
# WPScan - WordPress Security Scanner
# Copyright (C) 2012-2013
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class WpTarget < WebSite
  include WpUsernames
  include WpTimthumbs
  include WpPlugins
  include WpThemes
  include BruteForce

  attr_reader :verbose

  def initialize(target_url, options = {})
    super(target_url)

    @verbose        = options[:verbose]
    @wp_content_dir = options[:wp_content_dir]
    @wp_plugins_dir = options[:wp_plugins_dir]
    @multisite      = nil

    #Browser.instance(options.merge(:max_threads => options[:threads]))
  end

  # check if the target website is
  # actually running wordpress.
  def wordpress?
    wordpress = false

    response = Browser.instance.get(
      @uri.to_s,
      { follow_location: true, max_redirects: 2 }
    )

    if response.body =~ /["'][^"']*\/wp-content\/[^"']*["']/i
      wordpress = true
    else
      response = Browser.instance.get(
        xml_rpc_url,
        { follow_location: true, max_redirects: 2 }
      )

      if response.body =~ %r{XML-RPC server accepts POST requests only}i
        wordpress = true
      else
        response = Browser.instance.get(
          login_url,
          { follow_location: true, max_redirects: 2 }
        )

        if response.body =~ %r{WordPress}i
          wordpress = true
        end
      end
    end

    wordpress
  end

  def login_url
    url = @uri.merge('wp-login.php').to_s

    # Let's check if the login url is redirected (to https url for example)
    redirection = redirection(url)
    if redirection
      url = redirection
    end

    url
  end

  # Valid HTTP return codes
  def self.valid_response_codes
    [200, 301, 302, 401, 403, 500, 400]
  end

  def wp_content_dir
    unless @wp_content_dir
      index_body = Browser.instance.get(@uri.to_s).body
      # Only use the path because domain can be text or an ip
      uri_path = @uri.path

      if index_body[/\/wp-content\/(?:themes|plugins)\//i]
        @wp_content_dir = 'wp-content'
      else
        domains_excluded = '(?:www\.)?(facebook|twitter)\.com'
        @wp_content_dir  = index_body[/(?:href|src)\s*=\s*(?:"|').+#{Regexp.escape(uri_path)}((?!#{domains_excluded})[^"']+)\/(?:themes|plugins)\/.*(?:"|')/i, 1]
      end
    end
    @wp_content_dir
  end

  def wp_plugins_dir
    unless @wp_plugins_dir
      @wp_plugins_dir = "#{wp_content_dir}/plugins"
    end
    @wp_plugins_dir
  end

  def wp_plugins_dir_exists?
    Browser.instance.get(@uri.merge(wp_plugins_dir)).code != 404
  end

end
