# -*- coding: utf-8 -*-
require 'helper'

class TestVortexClient < Test::Unit::TestCase

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      @vortex = Vortex::Connection.new("https://vortex-dav.uio.no/",user, pass)
    end
  end

  should "open connection" do
    user = ENV['DAVUSER']
    pass = ENV['DAVPASS']
    vortex = Vortex::Connection.new("https://vortex-dav.uio.no/",user, pass)
    assert vortex
    vortex.cd('/brukere/thomasfl/')
  end

  should "read content from webdav server" do
    content = @vortex.get('https://vortex-dav.uio.no/brukere/thomasfl/test/test_1.html')
    assert content.match('html.*body')
  end

  should "detect that a resource (file) exists or not" do
    assert @vortex.exists?('https://vortex-dav.uio.no/brukere/thomasfl/test/test_1.html')
    assert @vortex.exists?('https://vortex-dav.uio.no/brukere/thomasfl/test/test_1.html_not_exists') == false
  end

  should "turn normal sentences into readable valid filenames" do
    require 'vortex_client/string_utils'
    assert_equal  "a-small-test-aeoa", Vortex::StringUtils.create_filename("a small test æøå?")
  end

  should "publish articles" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/sample-title-1.html'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    article = Vortex::HtmlArticle.new(:title => "Sample Title 1", :introduction => "Introduction",
                                      :body => "<p>Hello world</p>")
    @vortex.publish(article)
    assert @vortex.exists?(url)
  end

end
