# -*- coding: utf-8 -*-
require 'helper'

class TestVortexClientUtils < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      @vortex = Connection.new("https://vortex-dav.uio.no/",user, pass)
    end
  end

  should "publish articles" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/sample-title-2.html'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    article = Vortex::HtmlArticle.new(:title => "Sample Title 2",
                                      :introduction => "Sample introduction",
                                      :body => "<p>Hello world</p>",
                                      ## :date => Time.now,
                                      :publishedDate => "05.01.2010 12:00",
                                      :author => "Thomas Flemming")

    @vortex.publish(article)
    assert @vortex.exists?(url)
  end

end

