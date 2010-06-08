require 'rubygems'
require 'vortex_client'
include Vortex

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")
vortex.cd('/brukere/thomasfl/events/')

collection = ArticleListingCollection.new(:url => 'my-collection', :title => 'My articles')
path = vortex.create(collection)
puts "Created folder: " + path


collection = EventListingCollection.new(:title => 'My events')
path = vortex.create(collection)
puts "Created folder: " + path
