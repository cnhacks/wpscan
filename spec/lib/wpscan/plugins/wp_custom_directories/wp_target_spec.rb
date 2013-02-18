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

require File.expand_path(File.dirname(__FILE__) + '/../../wpscan_helper')

describe WpTarget do

  before :each do
    Browser.reset
    @options =
    {
      config_file:    SPEC_FIXTURES_CONF_DIR + '/browser/browser.conf.json',
      cache_timeout:  0,
      wp_content_dir: 'wp-content',
      wp_plugins_dir: 'wp-content/plugins'
    }
    @wp_target = WpTarget.new('http://example.localhost/', @options)
  end

  describe '#wp_content_dir' do
    let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_WP_TARGET_DIR + '/wp_content_dir' }

    after :each do
      @wp_target = WpTarget.new(@target_url) if @target_url
      stub_request_to_fixture(url: @wp_target.url, fixture: @fixture) if @fixture

      @wp_target.wp_content_dir.should === @expected
    end

    it 'should return the string set in the initialize method' do
      @wp_target = WpTarget.new('http://example.localhost/', @options.merge(wp_content_dir: 'hello-world'))
      @expected  = 'hello-world'
    end


    it "should return 'wp-content'" do
      @target_url = 'http://lamp/wordpress-3.4.1'
      @fixture    = fixtures_dir + '/wordpress-3.4.1.htm'
      @expected   = 'wp-content'
    end

    it "should return 'wp-content' if url has trailing slash" do
      @target_url = 'http://lamp/wordpress-3.4.1/'
      @fixture    = fixtures_dir + '/wordpress-3.4.1.htm'
      @expected   = 'wp-content'
    end

    it "should find the default 'wp-content' dir even if the target_url is not the same (ie : the user supply an IP address and the url used in the code is a domain)" do
      @target_url = 'http://192.168.1.103/wordpress-3.4.1/'
      @fixture    = fixtures_dir + '/wordpress-3.4.1.htm'
      @expected   = 'wp-content'
    end

    it "should return 'custom-content'" do
      @target_url = 'http://lamp/wordpress-3.4.1-custom'
      @fixture    = fixtures_dir + '/wordpress-3.4.1-custom.htm'
      @expected   = 'custom-content'
    end

    it "should return 'custom content spaces'" do
      @target_url = 'http://lamp/wordpress-3.4.1-custom'
      @fixture    = fixtures_dir + '/wordpress-3.4.1-custom-with-spaces.htm'
      @expected   = 'custom content spaces'
    end

    it "should return 'custom-dir/subdir/content'" do
      @target_url = 'http://lamp/wordpress-3.4.1-custom'
      @fixture    = fixtures_dir + '/wordpress-3.4.1-custom-subdirectories.htm'
      @expected   = 'custom-dir/subdir/content'
    end

    it 'should also check in src attributes' do
      @target_url = 'http://lamp/wordpress-3.4.1'
      @fixture    = fixtures_dir + '/wordpress-3.4.1-in-src.htm'
      @expected   = 'wp-content'
    end

    it 'should find the location even if the src or href goes in the plugins dir' do
      @target_url = 'http://wordpress-3.4.1-in-plugins.htm'
      @fixture    = fixtures_dir + '/wordpress-3.4.1-in-plugins.htm'
      @expected   = 'wp-content'
    end

    it 'should not detect facebook.com as a custom wp-content directory' do
      @target_url = 'http://lamp.localhost/'
      @fixture    = fixtures_dir + '/facebook-detection.htm'
      @expected   = nil
    end
  end

  describe '#wp_plugins_dir' do
    after :each do
      @wp_target.stub(wp_plugins_dir: @stub_value) if @stub_value

      @wp_target.wp_plugins_dir.should === @expected
    end

    it 'should return the string set in the initialize method' do
      @wp_target = WpTarget.new('http://example.localhost/', @options.merge(wp_content_dir: 'asdf', wp_plugins_dir: 'custom-plugins'))
      @expected  = 'custom-plugins'
    end

    it "should return 'plugins'" do
      @stub_value = 'plugins'
      @expected   = 'plugins'
    end

    it "should return 'wp-content/plugins'" do
      @wp_target = WpTarget.new('http://example.localhost/', @options.merge(wp_content_dir: 'wp-content', wp_plugins_dir: nil))
      @expected  = 'wp-content/plugins'
    end
  end

  describe '#wp_plugins_dir_exists?' do
    it 'should return true' do
      target = WpTarget.new('http://example.localhost/', @options.merge(wp_content_dir: 'asdf', wp_plugins_dir: 'custom-plugins'))
      url    = target.uri.merge(target.wp_plugins_dir).to_s
      stub_request(:any, url).to_return(status: 200)
      target.wp_plugins_dir_exists?.should == true
    end

    it 'should return false' do
      target = WpTarget.new('http://example.localhost/', @options.merge(wp_content_dir: 'asdf', wp_plugins_dir: 'custom-plugins'))
      url    = target.uri.merge(target.wp_plugins_dir).to_s
      stub_request(:any, url).to_return(status: 404)
      target.wp_plugins_dir_exists?.should == false
    end
  end

end
