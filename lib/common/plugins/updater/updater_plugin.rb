# encoding: UTF-8
#
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

class UpdaterPlugin < Plugin

  def initialize
    super(author: 'WPScanTeam')

    register_options(
      ['--update', 'Update to the latest revision'],
      ['--revision', 'Show the current revision']
    )
  end

  def run(options = {})
    if options[:update] || options[:revision]
      updater = UpdaterFactory.get_updater(ROOT_DIR)

      if options[:update]
        if !updater.nil?
          if updater.has_local_changes?
            puts "#{red('[!]')} Local file changes detected, an update will override local changes, do you want to continue updating? [y/n]"
            Readline.readline =~ /^y/i ? updater.reset_head : raise('Update aborted')
          end
          puts updater.update()
        else
          puts 'Svn / Git not installed, or wpscan has not been installed with one of them.'
          puts 'Update aborted'
        end
      elsif options[:revision]
        puts "Revision: #{updater.local_revision_number}"
      end
    end
  end
end
