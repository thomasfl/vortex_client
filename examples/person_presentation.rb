# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'

@vortex = Vortex::Connection.new("https://nyweb1-dav.uio.no/")
@vortex.cd('/konv/personer_test/')

person = Vortex::Person.new(:user => 'herman',
                            :image => '/konv/personer_test/placeholder.jpg',
                            :language => :english,
                            :scientific => true)

url = @vortex.publish(person)
puts "Published: " + url
