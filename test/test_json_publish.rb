# -*- coding: utf-8 -*-
require 'helper'

class TestJSONPublish < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      # puts "JSON testene kan foreløpig ikke kjøres på vortex.uio.no?"
      @vortex = Connection.new("https://nyweb1-dav.uio.no",user, pass)
    end
  end

  should "publish JSON articles" do
    # url = 'https://vortex-dav.uio.no/bloggimport/json-test.html'
    url = 'bloggimport/json-test.html'
    if(@vortex.exists?(url))
      @vortex.delete(url)
    end

    body = "<p>&nbsp;Bla bla<\/p>\r\n<p>Mer &quot;Bla&quot; bla<\/p>\r\n<p>"+
      "<strong>Enda<\/strong> <a href=\"http://www.vg.no\">mer<\/a> bla bla<\/p>\r\n<p>&nbsp;<\/p>"

    @vortex.cd('/bloggimport/')
    article = Vortex::StructuredArticle.new(:title => "JSON test",
                                            :introduction => "Sample introduction",
                                            :body => body, # .to_json, # "<p>Hello world</p><p>Bla bla</p>",
                                            :publishedDate => "05.01.2010 12:00",
                                            :author => "Thomas Flemming",
                                            :picture => "/bloggimport/forskning/arrangementer/disputaser/2008/01/gran_boe.jpg" )

    url = @vortex.publish(article)
    puts "For å fullføre testen: Se på denne siden i en nettleser: " + url
    assert @vortex.exists?(url)
  end

end

