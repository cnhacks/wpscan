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

class PluginGeneratorPlugin < Plugin

  #attr_reader :plugin_type, :plugin_name

  def initialize
    super(author: 'WPScanTeam - @erwan_lr')

    register_options(
      ['--generate-plugin PLUGIN_TYPE:PLUGIN_NAME', 'Generate the files & directories for the specified plugin. Available PLUGIN_TYPE : common, wpscan, wpstools'],
      # TODO
      #['--gnerate-plugin-spec PLUGIN_TYPE:PLUGIN_NAME', 'Only generate the rspec files & directories for the specified plugin']
    )
  end

  def run(options = {})
    if options[:generate_plugin]
      argument = options[:generate_plugin]

      if PluginGeneratorPlugin.valid_argument_format?(argument)
        self.plugin_type, self.plugin_name = argument.split(':')

        # Generating plugin
        PluginGeneratorPlugin.generate(plugin_directory, plugin_file)

        # Generating spec
        PluginGeneratorPlugin.generate(plugin_spec_directory, plugin_spec_file)
      else
        raise "Invalid argument format '#{argument}', expected PLUGIN_TYPE:PLUGIN_NAME"
      end
    end
  end

  def self.valid_argument_format?(argument)
    argument.index(':') != nil
  end

  def plugin_type=(type)
    valid_types = %w{common wpscan wpstools}
    type        = type.downcase

    if valid_types.include?(type)
      @plugin_type = type
    else
      raise "Invalid plugin type '#{type}', expected #{valid_types.join(', ')}"
    end
  end

  def plugin_name=(name)
    if !name.nil?
      @plugin_name = name.downcase
    else
      raise "No PLUGIN_NAME supplied"
    end
  end

  def plugin_directory
    File::join(LIB_DIR, @plugin_type, 'plugins', @plugin_name)
  end

  def plugin_file
    File::join(plugin_directory, "#{@plugin_name}_plugin.rb")
  end

  def plugin_spec_directory
    File::join(ROOT_DIR, 'spec', 'lib', @plugin_type, 'plugins', @plugin_name)
  end

  def plugin_spec_file
    File::join(plugin_spec_directory, "#{@plugin_name}_plugin_spec.rb")
  end

  def self.generate(directory, file)
    puts "Creating #{directory}"
    Dir::mkdir(directory)

    puts "Creating #{file}"
    File.open(file, 'w+') do |f|
      f.write('# encoding: UTF-8')
    end
  end

end
