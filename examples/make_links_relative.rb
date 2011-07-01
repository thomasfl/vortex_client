# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'vortex_client'
require 'pathname'
require 'json'

def make_links_relative(dav_url)
  vortex = Vortex::Connection.new(dav_url, :osx_keychain => true)
  vortex.cd(URI.parse(dav_url).path.to_s)
  count = 0
  vortex.find('.', :recursive => true, :filename=>/\.html$/) do |item|
    count = count + 1
    puts "Checking    : " + count.to_s + ": " + item.url.to_s

    json_data = JSON.parse(item.content)
    content = json_data["properties"]["content"]
    dirty = false
    doc = Nokogiri::HTML(content)
    doc.css('a').each do |element|
      href = element['href']
      if(href and href[/^\//])then
        pathname_from = Pathname.new( URI.parse(item.url.to_s).path.to_s )
        pathname_to   = Pathname.new( URI.parse(href.to_s).path.to_s )
        new_href = pathname_to.relative_path_from(pathname_from.parent).to_s
        element['href'] = new_href
        puts "              " + href + " => " + new_href
        dirty = true
      end
    end
    if(dirty)then
      json_data["properties"]["content"] = doc.to_s
      item.content = json_data.to_json
      puts "Updating    : " + item.url.to_s
      puts
    end
  end

end

url = ARGV[0]
if(not(url))then
  puts "Usage: make_links_relative URL"
  puts
  puts "Example: make_links_relative https://www-dav.vortex-demo.uio.no/tmp/relativiser/ "
  puts "Looks for links in vortex documents stored as json. Takes a vortex webdav url as"
  puts "parameter. Searches recursively through subfolders."
else
  make_links_relative(url)
end
