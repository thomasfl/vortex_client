# -*- coding: utf-8 -*-
require 'rubygems'
require 'open-uri'
require 'vortex_client'
require 'uri'
require 'nokogiri'
require 'htmlentities'
require 'json'
require 'iconv'

class MigrateHeroPublications
  attr :vortex, :uri

  def initialize(url)
    @vortex = Vortex::Connection.new(url,:use_osx_keychain => true)
    @uri = URI.parse(url)
  end

  def migrate_publications(url)
    doc = Nokogiri::HTML.parse(open(url))
    doc.encoding = 'utf-8'
    doc.xpath("//td").each do |element|
      if(element.inner_text =~ /\d*:\d*/)then
        puts element.inner_text
        puts "-------"
      end
    end
  end

end

# Scrape all webpages found in src_url and store in dest_url
dest_url = 'https://nyweb1-dav.uio.no/konv/hero/publikasjoner'
# src_url = 'http://www.hero.uio.no/publicat/2003/'
# src_url = 'http://www.hero.uio.no/nyheter.html'
src_url = 'http://www.hero.uio.no/publications_all/publications10.html'
migration = MigrateHeroPublications.new(dest_url)
migration.migrate_publications(src_url)
