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
