# -*- coding: utf-8 -*-
require 'helper'

class TestVortexTags < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      @vortex = Vortex::Connection.new("https://vortex-dav.uio.no/",user, pass)
    end
  end

  should "publish articles with tags" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/my-sample-title.html'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    article = Vortex::HtmlArticle.new(:title => "My Sample Title", :introduction => "Introduction",
                                      :body => "<p>Hello world</p>", :tags => ['tag 1','tag 2','tag 3'])
    published_url = @vortex.publish(article)
    assert @vortex.exists?(published_url)
    assert  published_url == url
  end

end
