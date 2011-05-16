# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'pry'
require 'net/http'
require 'pathname'
require 'json'
require 'pp'

# The method String.cleanpath seems to be missing in my version of ruby
# Since it is not important to us, we can define it:
class String
  def cleanpath
    return self
  end
end

# Relativize url's
def relative_url(from,to)
  pn = Pathname.new(to)
  return  pn.relative_path_from(from).to_s.gsub(/^\.\.\//,'')
end

# Read link database from file. Return hashmaps
def read_linkbase_from_file
  old_pages = { }
  File.open('scrape_holocaust.log').each do |line|
    line = line.chop
    pages = line.split(/;/)
    if(pages[0])then
      old_pages[pages[0]] = pages[1]
    end
  end
  return old_pages
end

# Generate html content for right column box in vortex:
def generate_related_content(old_url,new_url)
  related_content_html = ""
  doc = Nokogiri::HTML.parse(open(old_url))
  doc.encoding = 'utf-8'
  doc.css(".related .title").each do |related_title|
    related_content_html += "<p><b>#{related_title.text}</b></p>\n"
    # puts "  Title:   '" + related_title.text + "'"
    # # puts "Old url :'" + old_url + "'"
    # #  puts "    url :'" + new_url + "'"
    next_element = related_title.next_element
    related_content_html += "<ul>\n"
    while(next_element)
      href = next_element.css("a").attr("href").to_s
      text = next_element.css("a").text
      link_to = href
      if(@old_pages[href])
        # puts " New: '" + @old_pages[href] + "'"
        # puts " Relt:'" + relative_url(new_url,@old_pages[href])
        link_to = relative_url(new_url,@old_pages[href])
      else
        # puts "    Warning: Extern url: " + href
      end
      next_element = next_element.next_element
      related_content_html += " <li><a href=\"#{link_to}\">#{text}</a>\n"
    end
    related_content_html += "</ul>\n\n"
  end
  return related_content_html
end

def update_links_in_tekst(html,new_url)
  doc = Nokogiri::HTML.parse(html)
  doc.css("a").each do |link|
    if(link.attributes["href"])
      href = link.attr("href")
      if(@old_pages[href])then
        link_to = relative_url(new_url,@old_pages[href])
        puts " Replace link in body:" + link_to
        html = html.gsub(href,link_to)
      end
    end
  end
  return html
end


# # Debugg code
# @vortex = Vortex::Connection.new("https://nyweb4-dav.uio.no", :use_osx_keychain => true)
# @old_pages = read_linkbase_from_file
# old_url = "http://www.hlsenteret.no/kunnskapsbasen/tradisjoner/buddhisme/1049"
# new_url = "https://nyweb4-dav.uio.no/konv/kunnskapsbasen/tradisjoner/buddhisme/hellige-skrifter-i-buddhismen.html"

# # old_url = "http://www.hlsenteret.no/kunnskapsbasen/tema/religionsfrihet"
# # new_url = "https://nyweb4-dav.uio.no/konv/kunnskapsbasen/tema/religionsfrihet/religions-og-livssynsfrihet.html"

# src = @vortex.get(URI.parse(new_url).path)
# data = JSON.parse(src)
# data['properties']['hideAdditionalContent'] = "false"
# # data['properties']['related-content'] = related_content_html
# content = data['properties']['content']
# content = update_links_in_tekst(content,new_url)
# puts content
# exit

# update_links_in_tekst("http://www.hlsenteret.no/kunnskapsbasen/Holocaust_og_andre_folkemord",nil)
# exit


@vortex = Vortex::Connection.new("https://nyweb4-dav.uio.no", :use_osx_keychain => true)

@old_pages = read_linkbase_from_file
count = 1
@old_pages.each do |old_url, new_url|
  puts count
  puts old_url
  puts new_url
  puts "Url: '" + URI.parse(new_url).path.to_s + "'"
  related_content_html = generate_related_content(old_url,new_url)


  src = @vortex.get(URI.parse(new_url).path)
  data = JSON.parse(src)
  data['properties']['hideAdditionalContent'] = "false"
  data['properties']['related-content'] = related_content_html

  content = data['properties']['content']
  content = update_links_in_tekst(content,new_url)
  data['properties']['content'] = content
  @vortex.put_string(URI.parse(new_url).path, data.to_json)
  puts "-------"

  count += 1
  # exit if count > 10
end
