require 'rubygems'
require 'vortex_client'

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")

vortex.cd('/brukere/thomasfl/nyheter/')
article  = Vortex::StructuredArticle.new(:title => "Hello world",
                           :introduction => "Short introduction",
                           :body => "<p>Longer body</p>",
                           :publishedDate => Time.now,
                           :author => "Thomas Flemming")
path = vortex.publish(article)
puts "published " + path

# => published https://vortex-dav.uio.no/brukere/thomasfl/nyheter/my-new-title.html
