#!/usr/bin/env ruby
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
$: << '.'

require File.dirname(__FILE__) + '/lib/wpscan/wpscan_helper'

def output_vulnerabilities(vulns)
  vulns.each do |vulnerability|
    puts
    puts ' | ' + red("* Title: #{vulnerability.title}")
    vulnerability.references.each do |r|
      puts ' | ' + red("* Reference: #{r}")
    end
    vulnerability.metasploit_modules.each do |m|
      puts ' | ' + red("* Metasploit module: #{get_metasploit_url(m)}")
    end
  end
end

def output_item_details(item)
  puts
  puts " | Name: #{item}" #this will also output the version number if detected
  puts " | Location: #{item.get_url_without_filename}"
  puts " | WordPress: #{item.wp_org_url}"  if item.wp_org_item?
  puts ' | Directory listing enabled: Yes' if item.directory_listing?
  puts " | Readme: #{item.readme_url}" if item.has_readme?
  puts " | Changelog: #{item.changelog_url}" if item.has_changelog?

  output_vulnerabilities(item.vulnerabilities)

  if item.error_log?
    puts ' | ' + red('[!]') + " A WordPress error_log file has been found : #{item.error_log_url}"
  end
end

# delete old logfile, check if it is a symlink first.
File.delete(LOG_FILE) if File.exist?(LOG_FILE) and !File.symlink?(LOG_FILE)

banner()

begin

  option_parser = CustomOptionParser.new('Usage: ./wpscan.rb [options]', 40)
  option_parser.separator ''
  option_parser.add(['-v', '--verbose', 'Verbose output'])
  option_parser.add(['-u', '--url TARGET_URL', 'The WordPress URL/domain to scan'])

  plugins = Plugins.new(option_parser)
  plugins.register(
    UpdaterPlugin.new,
    BrowserOptionsOverridePlugin.new,
    TargetCheckerPlugin.new,
    WpCustomDirectoriesPlugin.new
  )

  options = option_parser.results

  if options.empty?
    raise "No option supplied\n\n#{option_parser}"
  end

  plugins.each do |plugin|
    if plugin.is_a?(WpscanPlugin)
      wp_target ||= WpTarget.new(options[:url], options)

      plugin.run(wp_target, options)
    else
      plugin.run(options)
    end
  end

  exit(0)

  # Output runtime data
  start_time = Time.now
  puts "| URL: #{wp_target.url}"
  puts "| Started on #{start_time.asctime}"
  puts

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

  if wpscan_options.enumerate_plugins == nil and wpscan_options.enumerate_only_vulnerable_plugins == nil
    puts
    puts green('[+]') + ' Enumerating plugins from passive detection ... '

    plugins = wp_target.plugins_from_passive_detection(base_url: wp_target.uri, wp_content_dir: wp_target.wp_content_dir)
    if !plugins.empty?
      puts "#{plugins.size} plugins found :"

      plugins.each do |plugin|
        output_item_details(plugin)
      end
    else
      puts 'No plugins found :('
    end
  end

  # Enumerate the installed plugins
  if wpscan_options.enumerate_plugins or wpscan_options.enumerate_only_vulnerable_plugins or wpscan_options.enumerate_all_plugins
    puts
    puts green('[+]') + " Enumerating installed plugins #{'(only vulnerable ones)' if wpscan_options.enumerate_only_vulnerable_plugins} ..."
    puts

    options = {
      base_url:              wp_target.uri,
      only_vulnerable_ones:  wpscan_options.enumerate_only_vulnerable_plugins || false,
      show_progression:      true,
      wp_content_dir:        wp_target.wp_content_dir,
      error_404_hash:        wp_target.error_404_hash,
      homepage_hash:         wp_target.homepage_hash,
      wp_plugins_dir:        wp_target.wp_plugins_dir,
      full:                  wpscan_options.enumerate_all_plugins,
      exclude_content_based: wpscan_options.exclude_content_based
    }

    plugins = wp_target.plugins_from_aggressive_detection(options)
    if !plugins.empty?
      puts
      puts
      puts green('[+]') + " We found #{plugins.size.to_s} plugins:"

      plugins.each do |plugin|
        output_item_details(plugin)
      end
    else
      puts
      puts 'No plugins found :('
    end
  end

  # Enumerate installed themes
  if wpscan_options.enumerate_themes or wpscan_options.enumerate_only_vulnerable_themes or wpscan_options.enumerate_all_themes
    puts
    puts green('[+]') + " Enumerating installed themes #{'(only vulnerable ones)' if wpscan_options.enumerate_only_vulnerable_themes} ..."
    puts

    options = {
      base_url:              wp_target.uri,
      only_vulnerable_ones:  wpscan_options.enumerate_only_vulnerable_themes || false,
      show_progression:      true,
      wp_content_dir:        wp_target.wp_content_dir,
      error_404_hash:        wp_target.error_404_hash,
      homepage_hash:         wp_target.homepage_hash,
      full:                  wpscan_options.enumerate_all_themes,
      exclude_content_based: wpscan_options.exclude_content_based
    }

    themes = wp_target.themes_from_aggressive_detection(options)
    if !themes.empty?
      puts
      puts
      puts green('[+]') + " We found #{themes.size.to_s} themes:"

      themes.each do |theme|
        output_item_details(theme)
      end
    else
      puts
      puts 'No themes found :('
    end
  end

  if wpscan_options.enumerate_timthumbs
    puts
    puts green('[+]') + ' Enumerating timthumb files ...'
    puts

    options = {
      base_url:              wp_target.uri,
      show_progression:      true,
      wp_content_dir:        wp_target.wp_content_dir,
      error_404_hash:        wp_target.error_404_hash,
      homepage_hash:         wp_target.homepage_hash,
      exclude_content_based: wpscan_options.exclude_content_based
    }

    theme_name = wp_theme ? wp_theme.name : nil
    if wp_target.has_timthumbs?(theme_name, options)
      timthumbs = wp_target.timthumbs

      puts
      puts green('[+]') + " We found #{timthumbs.size.to_s} timthumb file/s :"
      puts

      timthumbs.each do |t|
        puts ' | ' + red('[!]') + " #{t.get_full_url.to_s}"
      end
      puts
      puts red(' * Reference: http://www.exploit-db.com/exploits/17602/')
    else
      puts
      puts 'No timthumb files found :('
    end
  end

  # If we haven't been supplied a username, enumerate them...
  if !wpscan_options.username and wpscan_options.wordlist or wpscan_options.enumerate_usernames
    puts
    puts green('[+]') + ' Enumerating usernames ...'

    usernames = wp_target.usernames(range: wpscan_options.enumerate_usernames_range)

    if usernames.empty?
      puts
      puts 'We did not enumerate any usernames :('
      puts 'Try supplying your own username with the --username option'
      puts
      exit(1)
    else
      puts
      puts green('[+]') + " We found the following #{usernames.length.to_s} username/s :"
      puts

      max_id_length = usernames.sort { |a, b| a.id.to_s.length <=> b.id.to_s.length }.last.id.to_s.length
      max_name_length = usernames.sort { |a, b| a.name.length <=> b.name.length }.last.name.length
      max_nickname_length = usernames.sort { |a, b| a.nickname.length <=> b.nickname.length }.last.nickname.length

      space = 1
      usernames.each do |u|
        id_string = "id: #{u.id.to_s.ljust(max_id_length + space)}"
        name_string = "name: #{u.name.ljust(max_name_length + space)}"
        nickname_string = "nickname: #{u.nickname.ljust(max_nickname_length + space)}"
        puts " | #{id_string}| #{name_string}| #{nickname_string}"
      end
    end

  else
    usernames = [WpUser.new(wpscan_options.username, -1, 'empty')]
  end

  # Start the brute forcer
  bruteforce = true
  if wpscan_options.wordlist
    if wp_target.has_login_protection?

      protection_plugin = wp_target.login_protection_plugin()

      puts
      puts "The plugin #{protection_plugin.name} has been detected. It might record the IP and timestamp of every failed login. Not a good idea for brute forcing !"
      puts '[?] Do you want to start the brute force anyway ? [y/n]'

      bruteforce = false if Readline.readline !~ /^y/i
    end

    if bruteforce
      puts
      puts green('[+]') + ' Starting the password brute forcer'
      puts
      wp_target.brute_force(usernames, wpscan_options.wordlist, {show_progression: true})
    else
      puts
      puts 'Brute forcing aborted'
    end
  end

  stop_time = Time.now
  puts
  puts green("[+] Finished at #{stop_time.asctime}")
  elapsed = stop_time - start_time
  puts green("[+] Elapsed time: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}")
  exit() # must exit!
rescue => e
  puts red("[ERROR] #{e.message}")
  puts red('Trace :')
  puts red(e.backtrace.join("\n"))
end
