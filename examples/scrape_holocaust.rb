# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'pry'
require "net/http"
require 'pathname'
require 'json'

# Scrape content from the Norwegian Center for Studies of Holocaust and Religious Minorities'
# website http://www.hlsenteret.no/ and re-publish content to University of Oslo's CMS
# using the WebDAV API.

# TODO
#  ok - Hente ut tittel på mappen
#  ok - Hente ut content/type på bilder
#  ok - Kopiere over ingress bilde
#  ok - Luke ut rare tegn i overskriftene
#  ok - Kjøre alle dokumenter uten kræsj
#  - Kopiere over flere bilder
#  ok - Få logging til fil til å fungere
# - Hvorfor konverteres og publiseres /konv/kunnskapsbasen/-a-hrefhttp-.html
# - Håndtere /konv/kunnskapsbasen/hl-senterets-kunnskapsbase.html spesielt?

@vortex = Vortex::Connection.new("https://nyweb4-dav.uio.no", :use_osx_keychain => true)

# Log to file
def log(str)
  puts str
  log_str = Time.now.iso8601 + ";" + str + "\n"
  File.open("scrape_holocaust.log", 'a') {|f| f.write(log_str) }
end

def http_content_type(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Get.new(uri.request_uri)
  request["User-Agent"] = "My Ruby Script"
  request["Accept"] = "*/*"

  response = http.request(request)
  return response['content-type']
end

def create_path(dest_path)
  destination_path = "/"
  dest_path.split("/").each do |folder|
    if(folder != "")then
      folder = folder.downcase
      destination_path = destination_path + folder + "/"

      if( not(@vortex.exists?(destination_path)) )then

        puts "Creating folder " + destination_path

        uri = URI.parse(@url)
        scrape_url = 'http://' + uri.host + destination_path.gsub('/konv','')
        doc = Nokogiri::HTML.parse(open(scrape_url))
        doc.encoding = 'utf-8'

        title = nil
        begin
          title = doc.css(".folder .title").first.inner_html
        rescue
        end
        if(title == nil)then
          title = doc.css(".article .title").first.inner_html
        end

        if(title == nil)then
          title = "Ingen tittel"
        end
        title = title[0..0].upcase + title[1..title.length]

        puts "Mappetittel: " + title.to_s

        @vortex.mkdir(destination_path)
        @vortex.proppatch(destination_path,'<v:collection-type xmlns:v="vrtx">article-listing</v:collection-type>')
        @vortex.proppatch(destination_path,'<v:userTitle xmlns:v="vrtx">' + title.to_s +  '</v:userTitle>')
      end
    end
  end
end

def publish_article(path, title, introduction, body, doc)
  puts "Publishing..."
  dest_path = "/konv" + path.gsub(/\d*$/,'')
  puts dest_path
  create_path(dest_path)
  @vortex.cd(dest_path)

  new_image_url = nil
  article_image_url = nil
  caption = nil
  begin
    article_image_url = doc.css(".imageSeriesImage").first.attr("src")
    caption = doc.css(".imageText").first.text
    puts "Bildetekst:" + caption

    image_count = doc.css(".articleImageText").size
    puts "DEBUG: antall bilder: " + image_count.to_s
    if(image_count == 2)then

    end
    if(image_count > 2)then
      puts "Flere enn 2 bilder!"
      # exit
    end

  rescue
  end
  if(article_image_url)then
    image_content = open(article_image_url)
    article_image_url = article_image_url.gsub(/\?.*/,'')
    content_type = http_content_type(article_image_url)

    content_type = content_type.gsub("image/", "").gsub("jpeg","jpg")
    article_image_content = open(article_image_url).read
    basename = Pathname.new(article_image_url).basename.to_s.gsub(/\..*/,'')
    new_image_url = dest_path + basename + "." + content_type
    @vortex.put_string(new_image_url, article_image_content)
  end

  attributes = {:title => title,
    :introduction => introduction,
    :body => body,
    :publishedDate => Time.now}

  if(new_image_url)then
    attributes[:picture] = new_image_url
  end

  article  = Vortex::StructuredArticle.new(attributes )
  url = @vortex.publish(article)

  if(caption)then
    @vortex.find(url) do |item|
      data = JSON.parse(item.content)
      data["properties"]["caption"] = caption
      item.content = data.to_json
    end
  end

  return url

end

def scrape_article(url)
  puts "Scraping article: " + url
  doc = Nokogiri::HTML.parse(open(url))
  doc.encoding = 'utf-8'
  if(doc.css(".article .title").size() == 0)then
    puts "Warning. No title. Ignoring: " + url
    return
  end
  title = doc.css(".article .title").first.inner_html
  introduction = ""
  begin
    introduction = doc.css(".article .abstract").first.inner_html
  rescue
  end

    body = ""
  doc.css(".article .text").each do |p|
    body = body + "<p>" + p.inner_html + "</p>"
  end

  title = title.gsub('','–') # Fjern bindestrek

  puts title
  # puts "DEBUG: BODY:" + body
  # puts "DEBUG: INTRODUCTION:" + introduction


  puts
  puts url
  uri = URI.parse(url)
  path = uri.path
  puts path
  published_path = publish_article(path, title, introduction, body,doc)
  log = path + ";" + URI.parse(published_path).path
  puts
  File.open("scrape_holocaust.log", 'w') {|f| f.write(log) }
  puts title + " => " + published_path

  # binding.pry
end

def http_status_code(url)
  uri = URI.parse(url)
  Net::HTTP.start(uri.host, uri.port) do |http|
    return http.head(uri.request_uri).code.to_i
  end
end

def scrape_article_listing(url)
  puts "Scraping article listing: " + url
  if( http_status_code(url) == 404)then
    puts "Advarsel: Status code 404: " + url
    return
  end

  if(url =~ /\/kunnskapsbasen\/Presse/)then
    puts "Advarsel: Ignorerer pressesidene har for store bilder for vortex: url"
    return
  end

  doc = Nokogiri::HTML.parse(open(url))

  doc.encoding = 'utf-8'
  doc.css("div .list .article").each do |article|
    href = article.css(".title a").attr("href").text
    begin
      href = href.gsub("%20","")
    rescue
    end
    title = article.css(".title a").text
    # puts title + " => " + href
    if(href =~ /\d$/)then
      scrape_article(href)
    else
      scrape_article_listing(href)
    end
  end
end

if @vortex.exists?('/konv/kunnskapsbasen/aktor/diktatorer/') then
  @vortex.delete('/konv/kunnskapsbasen/aktor/diktatorer/')
end
@url = "http://www.hlsenteret.no/kunnskapsbasen/"

scrape_article("http://www.hlsenteret.no/kunnskapsbasen/folkemord/armenerne/1334")
exit


# Denne har ingen tittel og skal ignoreres
# scrape_article('http://www.hlsenteret.no/kunnskapsbasen/tradisjoner/86')
# exit

# Denne returnerer 404
# scrape_article_listing("http://www.hlsenteret.no/kunnskapsbasen/tema/kunst")

# Denne har bilder som er for store vortex
# scrape_article_listing("http://www.hlsenteret.no/kunnskapsbasen/Presse/")
# exit


# scrape_article('http://www.hlsenteret.no/kunnskapsbasen/tema/relpol/10129')
# exit

scrape_article_listing(@url)

# url = "http://www.hlsenteret.no/kunnskapsbasen/ideologi/nazisme/1143"
# url = "http://www.hlsenteret.no/kunnskapsbasen/aktor/diktatorer/1595"
# scrape_article(url)

