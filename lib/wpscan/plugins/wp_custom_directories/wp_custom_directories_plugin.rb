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

require File.dirname(__FILE__) + '/wp_target'

class WpCustomDirectoriesPlugin < WpscanPlugin

  def initialize
    super(author: 'WPScanTeam')

    register_options(
      ['--wp-content-dir WP_CONTENT_DIR', 'WPScan try to find the content directory (ie wp-content) by scanning the index page, however you can specified it. Subdirectories are allowed'],
      ['--wp-plugins-dir WP_PLUGINS_DIR', 'Same thing than --wp-content-dir but for the plugins directory. If not supplied, WPScan will use wp-content-dir/plugins. Subdirectories are allowed']
    )
  end

  def run(wp_target, options = {})

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
