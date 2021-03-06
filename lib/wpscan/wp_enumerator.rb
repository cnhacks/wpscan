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

# Enumerate over a given set of items and check if they exist
class WpEnumerator

  # Enumerate the given Targets
  #
  # ==== Attributes
  #
  # * +targets+ - targets to enumerate
  # * * +:base_url+ - Base URL
  # * * +:wp_content+ - wp-content directory
  # * * +:path+ - Path to plugin
  # * +type+ - "plugins" or "themes", item to enumerate
  # * +filename+ - filename in the data directory with paths
  # * +show_progression+ - Show a progress bar during enumeration
  def self.enumerate(options = {}, items = nil)

    WpOptions.check_options(options)

    targets = self.generate_items(options)

    unless items == nil
      items.each do |i|
        targets << i
      end
    end

    found            = []
    queue_count      = 0
    request_count    = 0
    enum_browser     = Browser.instance
    enum_hydra       = enum_browser.hydra
    enumerate_size   = targets.size
    exclude_regexp   = options[:exclude_content_based] ? %r{#{options[:exclude_content_based]}} : nil
    show_progression = options[:show_progression] || false

    targets.each do |target|
      url = target.get_full_url

      request = enum_browser.forge_request(url, cache_ttl: 0, followlocation: true)
      request_count += 1

      request.on_complete do |response|
        page_hash = Digest::MD5.hexdigest(response.body)

        print "\rChecking for #{enumerate_size} total #{options[:type]}... #{(request_count * 100) / enumerate_size}% complete." if show_progression

        if WpTarget.valid_response_codes.include?(response.code)
          if page_hash != options[:error_404_hash] and page_hash != options[:homepage_hash]
            if options[:exclude_content_based]
              unless response.body[exclude_regexp]
                found << target
              end
            else
              found << target
            end
          end
        end
      end

      enum_hydra.queue(request)
      queue_count += 1

      if queue_count == enum_browser.max_threads
        enum_hydra.run
        queue_count = 0
      end
    end

    enum_hydra.run
    found
  end

  protected

  def self.generate_items(options = {})
    only_vulnerable   = options[:only_vulnerable_ones]
    file              = options[:file]
    vulns_file        = options[:vulns_file]
    wp_content_dir    = options[:wp_content_dir]
    url               = options[:base_url]
    type              = options[:type]
    plugins_dir       = options[:wp_plugins_dir]
    targets_url       = []

    unless only_vulnerable
      # Open and parse the 'most popular' plugin list...
      File.open(file, 'r') do |f|
        f.readlines.collect do |line|
          l = line.strip
          targets_url << WpItem.new(
            base_url:       url,
            path:           l,
            wp_content_dir: wp_content_dir,
            name:           l =~ /.+\/.+/ ? File.dirname(l) : l.sub(/\/$/, ''),
            vulns_file:     vulns_file,
            type:           type,
            wp_plugins_dir: plugins_dir
          )
        end
      end
    end

    # Timthumbs have no XML file
    unless type =~ /timthumbs/i
      xml = xml(vulns_file)

      # We check if the plugin name from the plugin_vulns_file is already in targets, otherwise we add it
      xml.xpath(options[:vulns_xpath_2]).each do |node|
        name = node.attribute('name').text
        targets_url << WpItem.new(
          base_url:       url,
          path:           name,
          wp_content_dir: wp_content_dir,
          name:           name,
          vulns_file:     vulns_file,
          type:           type,
          wp_plugins_dir: plugins_dir
        )
        end
    end

    targets_url.flatten! { |t| t.name }
    targets_url.uniq! { |t| t.name }
    # randomize the plugins array to *maybe* help in some crappy IDS/IPS/WAF detection
    targets_url.sort_by! { rand }
  end
end
