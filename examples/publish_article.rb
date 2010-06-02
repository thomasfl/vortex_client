require 'rubygems'
require 'vortex_client'
include Vortex

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")

vortex.cd('/brukere/thomasfl/nyheter/')
article  = HtmlArticle.new(:title => "My new title",
                           :introduction => "Short introduction",
                           :body => "<p>Longer body</p>",
                           :publishedDate => Time.now,
                           :author => "Thomas Flemming")
path = vortex.publish(article)
puts "published " + path

# => published https://vortex-dav.uio.no/brukere/thomasfl/nyheter/my-new-title.html
