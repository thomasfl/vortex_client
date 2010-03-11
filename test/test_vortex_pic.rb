# -*- coding: utf-8 -*-
require 'helper'

class TestVortexPictures < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      @vortex = Vortex::Connection.new("https://vortex-dav.uio.no/",user, pass)
    end
  end

  should "publish articles with main image" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/my-sample-title.html'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    article = Vortex::HtmlArticle.new(:title => "My Sample Title", :introduction => "Introduction",
                                      :body => "<p>Hello world</p>", :picture => "/brukere/thomasfl/nyheter/fysikkstand.jpg")
    published_url = @vortex.publish(article)
    assert @vortex.exists?(published_url)
    assert published_url == url

    props =  @vortex.propfind(published_url)
    # assert props =~ /v:picture/
  end

end
