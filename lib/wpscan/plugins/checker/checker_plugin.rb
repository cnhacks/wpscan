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

class CheckerPlugin < WpscanPlugin

  def initialize
    super(author: 'WPScanTeam')
  end

  def run(wp_target, options = {})

    # Let's check the proxy response to detect invalid credentials etc
    if Browser.instance.proxy
      proxy_response = Browser.instance.get(wp_target.url)

      unless WpTarget::valid_response_codes.include?(proxy_response.code)
        raise "Proxy Error :\n\n#{proxy_response.headers}"
      end
    end

    # Remote website up?
    unless wp_target.online?
      raise "The WordPress URL supplied '#{wp_target.uri}' seems to be down."
    end

    # Redirection
    if redirection = wp_target.redirection
      if options[:follow_redirection]
        puts "Following redirection #{redirection}"
        puts
      else
        puts "The remote host tried to redirect us to #{redirection}"
        puts 'Do you want follow the redirection ? [y/n]'
      end

      if options[:follow_redirection] or Readline.readline =~ /^y/i
        wp_target.url = redirection
      else
        puts 'Scan aborted'
        exit
      end
    end

    # Basic auth detected but no credentials supplied
    if wp_target.has_basic_auth? && options[:basic_auth].nil?
      raise 'Basic authentication is required, please provide it with --basic-auth <login:password>'
    end

    # Remote website is wordpress?
    unless options[:force]
      unless wp_target.wordpress?
        raise 'The remote website is up, but does not seem to be running WordPress.'
      end
    end

    unless wp_target.wp_content_dir
      raise 'The wp_content_dir has not been found, please supply it with --wp-content-dir'
    end

    unless wp_target.wp_plugins_dir_exists?
      puts "The plugins directory '#{wp_target.wp_plugins_dir}' does not exist."
      puts 'You can specify one per command line option (don\'t forget to include the wp-content directory if needed)'
      puts 'Continue? [y/n]'
      unless Readline.readline =~ /^y/i
        exit
      end
    end

  end

end
