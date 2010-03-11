require 'rubygems'
require 'vortex_client'
include Vortex

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")
vortex.cd('/brukere/thomasfl/events/')
event = HtmlEvent.new(:title => "My Sample Event 1",
                      :introduction => "Sample event introduction",
                      :body => "<p>Hello world</p>",
                      :startDate => "19.06.2010 17:56",
                      :endDate =>  "19.06.2010 19:00",
                      :location => "Forskningsveien 3B",
                      :mapUrl => "http://maps.google.com/123",
                      :tags => ["vortex","testing","ruby"],
                      :publishedDate => Time.now )
path = vortex.publish(event)
puts "published " + path

