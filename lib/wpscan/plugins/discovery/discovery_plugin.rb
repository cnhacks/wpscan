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

class DiscoveryPlugin < WpscanPlugin

  def initialize
    super(author: 'WPScanTeam')
  end

  def run(wp_target, options = {})

    # core method from WebSite
    if wp_target.has_robots?
      puts green('[+]') + " robots.txt available under '#{wp_target.robots_url}'"
    end

    if wp_target.has_readme?
      puts red('[!]') + " The WordPress '#{wp_target.readme_url}' file exists"
    end

    if wp_target.has_full_path_disclosure?
      puts red('[!]') + " Full Path Disclosure (FPD) in '#{wp_target.full_path_disclosure_url}'"
    end

    if wp_target.has_debug_log?
      puts red('[!]') + " Debug log file found : #{wp_target.debug_log_url}"
    end

    wp_target.config_backup.each do |file_url|
      puts red("[!] A wp-config.php backup file has been found '#{file_url}'")
    end

    if wp_target.search_replace_db_2_exists?
      puts red("[!] searchreplacedb2.php has been found '#{wp_target.search_replace_db_2_url}'")
    end

    if wp_target.is_multisite?
      puts green('[+]') + ' This site seems to be a multisite (http://codex.wordpress.org/Glossary#Multisite)'
    end

    if wp_target.registration_enabled?
      puts green('[+]') + ' User registration is enabled'
    end

    # core method from WebSite
    if wp_target.has_xml_rpc?
      puts green('[+]') + " XML-RPC Interface available under #{wp_target.xml_rpc_url}"
    end

    if wp_target.has_malwares?
      malwares = wp_target.malwares
      puts red('[!]') + " #{malwares.size} malware(s) found :"

      malwares.each do |malware_url|
        puts
        puts ' | ' + red("#{malware_url}")
      end
      puts
    end

    wp_version = wp_target.version
    if wp_version
      puts green('[+]') + " WordPress version #{wp_version.number} identified from #{wp_version.discovery_method}"

      version_vulnerabilities = wp_version.vulnerabilities

      unless version_vulnerabilities.empty?
        puts
        puts red('[!]') + " We have identified #{version_vulnerabilities.size} vulnerabilities from the version number :"
        output_vulnerabilities(version_vulnerabilities)
      end
    end

    wp_theme = wp_target.theme
    if wp_theme
      puts
      # Theme version is handled in wp_item.to_s
      puts green('[+]') + " The WordPress theme in use is #{wp_theme}"
      output_item_details(wp_theme)
    end

  end

end
