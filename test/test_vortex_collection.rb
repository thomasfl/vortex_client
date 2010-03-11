# -*- coding: utf-8 -*-
require 'helper'

class TestVortexCollection < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      @vortex = Vortex::Connection.new("https://vortex-dav.uio.no/",user, pass)
    end
  end

  should "create article listing collection (folder)" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/my-collection'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    collection = ArticleListingCollection.new(:url => 'my-collection', :title => 'My Collection')
    created_path = @vortex.create(collection)

    assert @vortex.exists?(created_path)
    assert created_path == url
  end


  should "create event listing collection (folder)" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/event-collection'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    collection = EventListingCollection.new(:url => 'event-collection', :title => 'Event Collection')

    created_path = @vortex.create(collection)

    assert @vortex.exists?(created_path)
    assert created_path == url
  end


  should "create collection name from title" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/event-collection'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    collection = EventListingCollection.new(:title => 'Event Collection')

    created_path = @vortex.create(collection)

    assert @vortex.exists?(created_path)
    assert created_path == url
  end


  should "create collection name from foldername" do
    url = 'https://vortex-dav.uio.no/brukere/thomasfl/nyheter/event-collection'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    @vortex.cd('/brukere/thomasfl/nyheter/')
    collection = EventListingCollection.new(:foldername => 'event-collection')

    created_path = @vortex.create(collection)

    assert @vortex.exists?(created_path)
    assert created_path == url
  end



end
