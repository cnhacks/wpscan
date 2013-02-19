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

LIB_DIR              = File.dirname(__FILE__)
ROOT_DIR             = File.expand_path(LIB_DIR + '/..') # expand_path is used to get "wpscan/" instead of "wpscan/lib/../"
DATA_DIR             = ROOT_DIR + '/data'
CONF_DIR             = ROOT_DIR + '/conf'
CACHE_DIR            = ROOT_DIR + '/cache'
WPSCAN_LIB_DIR       = LIB_DIR + '/wpscan'
WPSTOOLS_LIB_DIR     = LIB_DIR + '/wpstools'
UPDATER_LIB_DIR      = LIB_DIR + '/updater'
COMMON_LIB_DIR       = LIB_DIR + '/common'
LOG_FILE             = ROOT_DIR + '/log.txt'
# Plugins directories
COMMON_PLUGINS_DIR   = COMMON_LIB_DIR + '/plugins'
WPSCAN_PLUGINS_DIR   = WPSCAN_LIB_DIR + '/plugins'
WPSTOOLS_PLUGINS_DIR = WPSTOOLS_LIB_DIR + '/plugins'

# Data files
PLUGINS_FILE        = DATA_DIR + '/plugins.txt'
PLUGINS_FULL_FILE   = DATA_DIR + '/plugins_full.txt'
PLUGINS_VULNS_FILE  = DATA_DIR + '/plugin_vulns.xml'
THEMES_FILE         = DATA_DIR + '/themes.txt'
THEMES_FULL_FILE    = DATA_DIR + '/themes_full.txt'
THEMES_VULNS_FILE   = DATA_DIR + '/theme_vulns.xml'
WP_VULNS_FILE       = DATA_DIR + '/wp_vulns.xml'
WP_VERSIONS_FILE    = DATA_DIR + '/wp_versions.xml'
LOCAL_FILES_FILE    = DATA_DIR + '/local_vulnerable_files.xml'
VULNS_XSD           = DATA_DIR + '/vuln.xsd'
WP_VERSIONS_XSD     = DATA_DIR + '/wp_versions.xsd'
LOCAL_FILES_XSD     = DATA_DIR + '/local_vulnerable_files.xsd'

WPSCAN_VERSION       = '2.0'

$LOAD_PATH.unshift(LIB_DIR)

require 'environment'

# TODO : add an exclude pattern ?
def require_files_from_directory(absolute_dir_path, files_pattern = '*.rb')
  files = Dir[File.join(absolute_dir_path, files_pattern)]

  # Files in the root dir are loaded first, then thoses in the subdirectories
  files.sort_by { |file| [file.count("/"), file] }.each do |f|
    f = File.expand_path(f)
    #puts "require #{f}" # Used for debug
    require f
  end
end

require_files_from_directory(COMMON_PLUGINS_DIR, '**/*.rb')

# Add protocol
def add_http_protocol(url)
  url =~ /^https?:/ ? url : "http://#{url}"
end

def add_trailing_slash(url)
  url =~ /\/$/ ? url : "#{url}/"
end

# Gets the string all elements in stringarray ends with
def get_equal_string_end(stringarray = [''])
  already_found = ''
  looping = true
  counter = -1
  if stringarray.kind_of? Array and stringarray.length > 1
    base = stringarray[0]
    while looping
      character = base[counter, 1]
      stringarray.each do |s|
        if s[counter, 1] != character
          looping = false
          break
        end
      end
      if looping == false or (counter * -1) > base.length
        break
      end
      already_found = "#{character if character}#{already_found}"
      counter -= 1
    end
  end
  already_found
end

# Since ruby 1.9.2, URI::escape is obsolete
# See http://rosettacode.org/wiki/URL_encoding#Ruby and http://www.ruby-forum.com/topic/207489
if RUBY_VERSION >= '1.9.2'
  module URI
    def self.escape(str)
      URI.encode_www_form_component(str).gsub('+', '%20')
    end
  end
end

if RUBY_VERSION < '1.9'
  class Array
    # Fix for grep with symbols in ruby <= 1.8.7
    def _grep_(regexp)
      matches = []
      self.each do |value|
        value = value.to_s
        matches << value if value.match(regexp)
      end
      matches
    end

    alias_method :grep, :_grep_
  end
end

# our 1337 banner
def banner
  puts '____________________________________________________'
  puts ' __          _______   _____                  '
  puts ' \\ \\        / /  __ \\ / ____|                 '
  puts '  \\ \\  /\\  / /| |__) | (___   ___  __ _ _ __  '
  puts '   \\ \\/  \\/ / |  ___/ \\___ \\ / __|/ _` | \'_ \\ '
  puts '    \\  /\\  /  | |     ____) | (__| (_| | | | |'
  puts "     \\/  \\/   |_|    |_____/ \\___|\\__,_|_| |_| v#{WPSCAN_VERSION}"
  puts
  puts '    WordPress Security Scanner by the WPScan Team'
  puts ' Sponsored by the RandomStorm Open Source Initiative'
  puts '_____________________________________________________'
  puts
  if RUBY_VERSION < '1.9'
    puts '[WARNING] Ruby < 1.9 not officially supported, please upgrade.'
    puts
  end
end

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text)
  colorize(text, 31)
end

def green(text)
  colorize(text, 32)
end

def get_metasploit_url(module_path)
  # remove leading slash
  module_path = module_path.sub(/^\//, '')
  "http://www.metasploit.com/modules/#{module_path}"
end

# Override for puts to enable logging
def puts(o = '')
  # remove color for logging
  if o.respond_to?('gsub')
    temp = o.gsub(/\e\[\d+m(.*)?\e\[0m/, '\1')
    File.open(LOG_FILE, 'a+') { |f| f.puts(temp) }
  end
  super(o)
end
