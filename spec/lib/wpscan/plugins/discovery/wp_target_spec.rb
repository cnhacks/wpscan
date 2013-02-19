# encoding: UTF-8

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

  it_should_behave_like 'WpReadme'
  it_should_behave_like 'WpConfigBackup'
  it_should_behave_like 'WpFullPathDisclosure'
  it_should_behave_like 'WpLoginProtection'
  it_should_behave_like 'Malwares'

  describe '#debug_log_url' do
    it "should return 'http://example.localhost/wp-content/debug.log" do
      @wp_target.stub(wp_content_dir: 'wp-content')
      @wp_target.debug_log_url.should === 'http://example.localhost/wp-content/debug.log'
    end
  end

  describe '#has_debug_log?' do
    let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_WP_TARGET_DIR + '/debug_log' }

    after :each do
      @wp_target.stub(wp_content_dir: 'wp-content')
      stub_request_to_fixture(url: @wp_target.debug_log_url(), fixture: @fixture)
      @wp_target.has_debug_log?.should === @expected
    end

    it 'should return false' do
      @fixture  = SPEC_FIXTURES_DIR + '/empty-file'
      @expected = false
    end

    it 'should return true' do
      @fixture  = fixtures_dir + '/debug.log'
      @expected = true
    end

    it 'should also detect it if there are PHP notice' do
      @fixture  = fixtures_dir + '/debug-notice.log'
      @expected = true
    end
  end

  describe '#search_replace_db_2_url' do
    it 'should return the correct url' do
      @wp_target.search_replace_db_2_url.should == 'http://example.localhost/searchreplacedb2.php'
    end
  end

  describe '#search_replace_db_2_exists?' do
    it 'should return true' do
      stub_request(:any, @wp_target.search_replace_db_2_url).to_return(status: 200, body: 'asdf by interconnect asdf')
      @wp_target.search_replace_db_2_exists?.should be_true
    end

    it 'should return false' do
      stub_request(:any, @wp_target.search_replace_db_2_url).to_return(status: 500)
      @wp_target.search_replace_db_2_exists?.should be_false
    end

    it 'should return false' do
      stub_request(:any, @wp_target.search_replace_db_2_url).to_return(status: 500, body: 'asdf by interconnect asdf')
      @wp_target.search_replace_db_2_exists?.should be_false
    end
  end

  describe '#registration_url' do
    it 'should return the correct url (multisite)' do
      # set to multi site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 200)
      @wp_target.registration_url.to_s.should == 'http://example.localhost/wp-signup.php'
    end

    it 'should return the correct url (not multisite)' do
      # set to single site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 302, headers: { 'Location' => 'wp-login.php?action=register' })
      @wp_target.registration_url.to_s.should == 'http://example.localhost/wp-login.php?action=register'
    end
  end

  describe '#registration_enabled?' do
    it 'should return false (multisite)' do
      # set to multi site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 200)
      stub_request(:any, @wp_target.registration_url.to_s).to_return(status: 302, headers: { 'Location' => 'wp-login.php?registration=disabled' })
      @wp_target.registration_enabled?.should be_false
    end

    it 'should return true (multisite)' do
      # set to multi site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 200)
      stub_request(:any, @wp_target.registration_url.to_s).to_return(status: 200, body: %{<form id="setupform" method="post" action="wp-signup.php">})
      @wp_target.registration_enabled?.should be_true
    end

    it 'should return false (not multisite)' do
      # set to single site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 302, headers: { 'Location' => 'wp-login.php?action=register' })
      stub_request(:any, @wp_target.registration_url.to_s).to_return(status: 302, headers: { 'Location' => 'wp-login.php?registration=disabled' })
      @wp_target.registration_enabled?.should be_false
    end

    it 'should return true (not multisite)' do
      # set to single site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 302, headers: { 'Location' => 'wp-login.php?action=register' })
      stub_request(:any, @wp_target.registration_url.to_s).to_return(status: 200, body: %{<form name="registerform" id="registerform" action="wp-login.php"})
      @wp_target.registration_enabled?.should be_true
    end

    it 'should return false' do
      # set to single site
      stub_request(:any, 'http://example.localhost/wp-signup.php').to_return(status: 302, headers: { 'Location' => 'wp-login.php?action=register' })
      stub_request(:any, @wp_target.registration_url.to_s).to_return(status: 500)
      @wp_target.registration_enabled?.should be_false
    end
  end

  describe '#is_multisite?' do
    before :each do
      @url = @wp_target.uri.merge('wp-signup.php').to_s
    end

    it 'should return false' do
      stub_request(:any, @url).to_return(status: 302, headers: { 'Location' => 'wp-login.php?action=register' })
      @wp_target.is_multisite?.should be_false
    end

    it 'should return true' do
      stub_request(:any, @url).to_return(status: 302, headers: { 'Location' => 'http://example.localhost/wp-signup.php' })
      @wp_target.is_multisite?.should be_true
    end

    it 'should return true' do
      stub_request(:any, @url).to_return(status: 200)
      @wp_target.is_multisite?.should be_true
    end

    it 'should return false' do
      stub_request(:any, @url).to_return(status: 500)
      @wp_target.is_multisite?.should be_false
    end
  end

end
