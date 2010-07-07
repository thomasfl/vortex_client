# -*- coding: utf-8 -*-
require 'helper'

class TestVortexPerson < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      # puts "JSON testene kan foreløpig ikke kjøres på vortex.uio.no?"
      @vortex = Connection.new("https://nyweb1-dav.uio.no/",user, pass)

      if(@vortex.exists?("/konv/personer_test/thomasfl.html"))then
        @vortex.delete("/konv/personer_test/thomasfl.html")
      end
    end
  end

  should "publish person presentation" do
    @vortex.cd('/konv/personer_test/')

    person = Vortex::Person.new(:user => 'thomasfl',
                                :image => '/brukere/thomasfl/thomasfl.jpg',
                                :language => :english,
                                :scientific => false)

    assert @vortex.exists?("/konv/personer_test/thomasfl.html") == false
    url = @vortex.publish(person)
    assert @vortex.exists?("/konv/personer_test/thomasfl.html")
    puts "Published: " + url
    # puts person.content
  end

  should "publish default person presentation for scientists" do
    @vortex.cd('/konv/personer_test/')

    collection = Vortex::PersonListingCollection.new(:foldername => '/konv/personer_test/scientific')

    created_path = @vortex.create(collection)
    @vortex.cd(created_path)
    person = Vortex::Person.new(:user => 'herman',
                                :image => '/konv/personer_test/placeholder.jpg',
                                :language => :english,
                                :url =>  '/konv/personer_test/scientific/index.html',
                                :scientific => true)

    # puts person.content
    url = @vortex.publish(person)
    puts "Published: " + url
  end

end

