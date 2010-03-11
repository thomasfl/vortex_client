# -*- coding: utf-8 -*-
require 'rubygems'
require 'open-uri'
require 'hpricot'
# require 'webdavtools'
require 'vortex_client'
include Vortex

# Convert vortex xml faq til html faq:
# Example:
#
#   ruby convert_faq.rb  https://www-dav.uio.no/faq/studier/fronter.xml  https://www-dav.usit.uio.no/it/fronter/faq.html
#
# Author: Thomas Flemming, 2010
#

ARTICLE_HEADER = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>##title##</title>
  <meta http-equiv="Content-type" content="text/html;charset=utf-8" />

</head>
<body>
<style type="text/css">
.vrtx-published-date {
       display: none;
}
</style>
<br />
${resource:toc}
EOF

ARTICLE_FOOTER = <<EOF
</body>
</html>
EOF


# Parsing av HTML koden til FAQ med 2 nivåer
def scrape_faq_2_levels(url)
  html = ""
  doc = Hpricot(open(url))
  doc.search(".faqOverskrift") do |item|
    html += "<h2 class=\"faqOverskrift\">" + item.inner_html + "</h2>\n"
    item = item.next_sibling
    while item and item.name != "h2" and item.name != "br"

      if item.attributes["class"] and item.attributes["class"] =~ /faqOverskrift/  then
        puts "Parse error: Unwanted item: " + item.to_s
      end

      if not( item.name == "a" and item.inner_text == "") then
        if item.attributes["class"] and item.attributes["class"] =~ /faqSporsmal/ then
          html += "<h3 class=\"faqSporsmal\">" + item.inner_html + "</h3>\n"
        else
          html += item.to_s + "\n"
        end
      end
      item = item.next_sibling
    end

  end
  return html
end


def scrape_faq_1_level(url)
  doc = Hpricot(open(url))
  html = ""
  doc.search(".faqSporsmal") do |item|
    html += "<h2 class=\"faqSporsmal\">" + item.inner_html + "</h2>\n"
    item = item.next_sibling
    while item and ((item.attributes["class"] =~ /faqSporsmal/) == nil) and item.name != "h2" and item.name != "br"
      item = item.next_sibling if(item.name == "a" and item.inner_html == "")
      if(item.attributes["class"] =~ /faqSvar/) then
        html += item.inner_html.to_s + "\n"
      else
        html += item.to_s + "\n"
      end

      item = item.next_sibling
    end
  end
  return html
end

# Skrap html kode til faq og konverter til nytt format
def scrape_faq_html(url)

  doc = Hpricot(open(url))

  if( doc.search(".faqOverskrift").size == 0 ) then
    puts "Konverting FAQ with 1 level..."
    return scrape_faq_1_level(url)
  else
    puts "Konverting FAQ with 2 levels..."
    return scrape_faq_2_levels(url)
  end
end

def davUrl2webUrl(url)
  if(url =~ /^https:\/\/([^\/]*)-dav(\..*)/)then
    return "http://" + $1 + $2
  end
end

# Extracts introduction from FAQ
def scrape_faq_introduction(url)
  introduction = ""
  doc = Hpricot(open(url))

  doc.search("h1") do |item|

    item = item.next_sibling

    while item and item.name != "h2" and item.name != "h3"
      introduction = introduction + item.inner_html # text
      item = item.next_sibling
    end

  end

  introduction = introduction.gsub(/</,"&lt;").gsub(/>/,"&gt;")
  introduction = introduction.gsub("&oslash;","ø").gsub("&aring;","å").gsub("&aelig;","æ")
  introduction = introduction.gsub("&Oslash;","Ø").gsub("&Aring;","Å").gsub("&Aelig;","Æ")
  introduction = introduction.gsub(/"/m,"&quot;")
  introduction = introduction.gsub(/'/m,"") #&rsquo;")
  introduction = introduction.sub(/\n/m," ").sub(/\r/m," ")
  introduction = introduction.sub(/^\s*/, "").chop!
  return introduction
end

# Konverterter WebDAV properties fra managed-xml dokumenter til article dokumenter.
def convert_dav_propes(dav_url)
  props_arr = []
  unwanted_properties =
    ["v:guessedcharacterencoding",
     "v:schema",
     # Example: <customdefined xmlns="http://www.uio.no/visual-profile">true</..
     # "customdefined",
     # Derived properties that dont' need to be set:
     "d:displayname",
     "d:getcontentlength",
     "d:getetag",
     "v:collection",
     "v:propertieslastmodified",
     "v:propertiesmodifiedby",
     "d:resourcetype",
     "v:title"
    ]
  props = Hpricot(  @vortex_source.propfind(dav_url).to_s )
  props.search("d:resourcetype/*") do |item|
    if item.is_a?(Hpricot::Elem) and (unwanted_properties.grep(item.name) == [] )
      prop =
        case item.name
        when "v:managedxmltitle"
          title = item.inner_html
          "<v:userTitle xmlns:v=\"vrtx\">#{title}</v:userTitle>"
        when "v:characterencoding"
          item.to_s.gsub(/UTF-/,"utf-") +
          "<v:userSpecifiedCharacterEncoding xmlns:v=\"vrtx\">utf-8</v:userSpecifiedCharacterEncoding>"
        when "v:resourcetype"
          "<v:resourceType xmlns:v=\"vrtx\">article</v:resourceType>" +
          "<v:xhtml10-type xmlns:v=\"vrtx\">article</v:xhtml10-type>"
        when "v:contentlastmodified"
          lastModifiedDate = item.inner_html
          # Articles needs published-date to be visible. Use lastModified:
          props_arr << "<v:published-date xmlns:v=\"vrtx\">#{lastModifiedDate}</v:published-date>"
          item.to_s
        when "customdefined"
          item.to_s.gsub(/customdefined/, "customDefined") # attribute name is camelCase in article
        when "editoremail"
          item.to_s.gsub(/editoremail/, "editorEmail") # attribute name is camelCase in article
        when "editorname"
          item.to_s.gsub(/editorname/, "editorName") # attribute name is camelCase in article
        else
          item.to_s
        end
      props_arr << prop
    end
  end
  return props_arr.sort().join("\n")
end

def convert_faq(dav_url, new_dav_url)
  url = davUrl2webUrl(dav_url)
  puts "Scraping html from: " + url

  # Scrape document title
  begin
    doc = Hpricot(open(url))
  rescue
    puts "Kunne ikke åpne url: " + url
    return
  end
  title = doc.search("title").inner_text
  new_html = ARTICLE_HEADER.gsub(/##title##/, title) + scrape_faq_html(url) + ARTICLE_FOOTER

  new_props = convert_dav_propes(dav_url)

  introduction = scrape_faq_introduction(url)
  if(introduction != nil and introduction != "") then
    new_props = new_props +  "<introduction>#{introduction}</introduction>"
  end

  # WebDAV.delete(new_dav_url)
  # WebDAV.publish(new_dav_url, new_html, new_props)
  begin
    @vortex_dest.delete(new_dav_url)
  rescue
  end
  # puts "DEBUG: " + new_dav_url +  new_html +  new_props
  @vortex_dest.put_string(new_dav_url, new_html)
  @vortex_dest.proppatch(new_dav_url, new_props)

end


#
# Generer rapport med oversikt over alle FAQ'er
#
HEADER = <<EOF
<table border="1">
<tbody>
<tr>
<th bgcolor="#c0c0c0" align="left" bordercolor="#FFFFFF">Tittel</th>
<th bgcolor="#c0c0c0" align="left" bordercolor="#FFFFFF">Orginal plassering</th>
<th bgcolor="#c0c0c0" align="left" bordercolor="#FFFFFF">Epost</th>
<th bgcolor="#c0c0c0" align="left" bordercolor="#FFFFFF">Status</th>
<th bgcolor="#c0c0c0" align="left" bordercolor="#FFFFFF">Skal konverteres til</th>
<th bgcolor="#c0c0c0" align="left" bordercolor="#FFFFFF">Er konvertert</th>
</tr>
EOF

def print_status_report(dav_url)
  arr = []
  count = 0
  @vortex_source.find(dav_url, :recursive => true) do |item|

    if( item.basename =~ /.xml$/ and (not(item.basename =~ /index.xml$/ )))then
      url = item.href
      url = url.sub(/^https/, "http").sub(/-dav\.uio\.no/,".uio.no")
      arr.push([item.title, url, item.basename])
    end
  end

  puts HEADER
  arr.sort.each do |item|
    # puts item[0] + item[1] + item[2]
    puts "<tr>"
    puts "  <td>" + item[0] + "</td><td><a href=\"#{item[1]}\">#{item[2]}</a></td>"
    puts "  <td> </td><td> </td><td> </td><td> </td>"
    puts "</tr>"
  end
  puts "</table>"
end

# Konverter alle FAQ dokumentene
def convert_recursively(url)
  @vortex_source.find(dav_url, :recursive => true) do |item|
    if( item.basename =~ /.xml$/ and (not(item.basename =~ /index.xml$/ )))then
      puts "Converterting: " + item.basename.ljust(40) + item.title
      dav_url = item.href
      new_dav_url = dav_url.sub(/\.xml$/,".html")
      convert_faq(dav_url, new_dav_url)
    end
  end
end


# Usage:
#
# convert_faq()
#
# convert_faq("https://www-dav.usit.uio.no/it/epost/faq/thunderbird-itansv.xml",
#            "https://vortex-dav.uio.no/brukere/thomasfl/thunderbird-itansv-faq.html")
# convert_faq("https://www-dav.uio.no/faq/studier/teologi-studentinfo.xml", "https://www-dav.tf.uio.no/studier/faq.html")
# convert_faq("https://www-dav.uio.no/faq/for_ansatte/usit-nyansatte.xml",
#            "https://www-dav.usit.uio.no/for-ansatte/ny-usit/nyansatt.html")
# exit



# Les inn gammel og ny url
src_url = ARGV[0]
dest_url = ARGV[1]
if(not(src_url and dest_url))
  puts "Usage: ruby convert src_dav_url destinatio_dav_url"
  exit
end

@vortex_source = Vortex::Connection.new(src_url, ENV['DAVUSER'], ENV['DAVPASS'])
@vortex_dest   = Vortex::Connection.new(dest_url, ENV['DAVUSER'], ENV['DAVPASS'])

convert_faq(src_url, dest_url)
puts "Published FAQ article to: " + dest_url
