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

  should "publish events" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/sample-event-1.html'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    event = HtmlEvent.new(:title => "Sample Event 1",
                          :introduction => "Sample event introduction",
                          :body => "<p>Hello world</p>",
                          :startDate => "19.06.2010 17:56",
                          :endDate =>  "19.06.2010 19:00",
                          :location => "Forskningsveien 3B",
                          :mapUrl => "http://maps.google.com/123",
                          :tags => ["vortex","testing","ruby"],
                          :publishedDate => "05.01.2010 12:00")
    @vortex.publish(event)
    assert @vortex.exists?(url)
  end

end

