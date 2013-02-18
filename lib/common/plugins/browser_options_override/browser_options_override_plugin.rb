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

class BrowserOptionsOverridePlugin < Plugin

  def initialize
    super(author: 'WPScanTeam - @erwan_lr')

    register_options(
      ['--config-file FILE', '-c', 'Use the specified config file'],
      ['--threads NUMBER_OF_THREADS', '-t', Integer, 'The number of threads to use when multi-threading requests'],
      ['--proxy [PROTOCOL://]HOST:PORT', 'Supply a proxy. Supported protocols: HTTP, HTTPS, SOCKS4, SOCKS4A and SOCKS5. Default protocol: HTTP'],
      ['--proxy-auth USERNAME:PASSWORD', 'Supply the proxy login credentials'],
      ['--basic-auth LOGIN:PASSWORD', 'Set the HTTP Basic authentication']
    )
  end

  def run(options = {})
    Browser.instance(options.merge(max_threads: options[:threads]))
  end

end
