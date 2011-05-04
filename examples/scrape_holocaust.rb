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
#  ok - Kopiere over flere bilder
#  ok - Få logging til fil til å fungere
# - Logg publisering til fil
# - Hvorfor konverteres og publiseres /konv/kunnskapsbasen/-a-hrefhttp-.html
# - Håndtere /konv/kunnskapsbasen/hl-senterets-kunnskapsbase.html spesielt?

@vortex = Vortex::Connection.new("https://nyweb4-dav.uio.no", :use_osx_keychain => true)

# Simple logger
def log(str)
  puts str
  File.open("scrape_holocaust.log", 'a') do |f|
    f.write( Time.now.iso8601 + ";" + str + "\n" )
  end
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

def scrape_folder_title(url)
  begin
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
  rescue
  end
  return title
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

        title = scrape_folder_title( 'http://' + uri.host + destination_path.gsub('/konv','') )

        if(title)then
          title = title[0..0].upcase + title[1..title.length]
          puts "Mappetittel: " + title.to_s
        end

        @vortex.mkdir(destination_path)
        @vortex.proppatch(destination_path,'<v:collection-type xmlns:v="vrtx">article-listing</v:collection-type>')
        if(title)then
          @vortex.proppatch(destination_path,'<v:userTitle xmlns:v="vrtx">' + title.to_s +  '</v:userTitle>')
        end
      end
    end
  end
end


# Return an array images and captions
def scrape_images(doc)
  images = []
  i = 0
  doc.css(".imageSeriesImage").each do |item|
    url = item.attr("src")
    caption = doc.css(".imageText")[i].text
    images << { :url => url, :caption => caption }
    i = i + 1
  end
  return images
end


# Resize an image using the unix command line utility 'sips' available on osx
def resize_image(content, content_type, size)
  filename = "/tmp/" + (1 + rand(10000000)).to_s + "." + content_type
  filename_resized = "/tmp/" + (1 + rand(10000000)).to_s + "_resized." + content_type
  File.open(filename, 'w') do |f|
    f.write( content)
  end
  result = %x[sips --resampleWidth #{size} #{filename} --out #{filename_resized}]
  content_resized = IO.readlines(filename_resized,'r').to_s
  return content_resized
end


# Download graphic to dest_path and return absolute filename
def download_image(src_url,dest_path)
  src_url = src_url.gsub(/\?.*/,'')
  content_type = http_content_type(src_url)
  content_type = content_type.gsub("image/", "").gsub("jpeg","jpg")
  content = open(src_url).read
  basename = Pathname.new(src_url).basename.to_s.gsub(/\..*/,'')
  vortex_url = dest_path + basename + "." + content_type
  @vortex.put_string(vortex_url, content)

  # Store a resized image to vortex
  puts "Nedskalerer bilde: " + src_url
  content_resized = resize_image(content, content_type,300)
  vortex_url_resized = dest_path + basename + "_width_300." + content_type
  @vortex.put_string(vortex_url_resized, content_resized)
  return { :vortex_url_resized => vortex_url_resized, :vortex_url => vortex_url}
end


def publish_article(path, title, introduction, body, doc)
  # puts "Publishing..."
  dest_path = "/konv" + path.gsub(/\d*$/,'')
  puts dest_path
  create_path(dest_path)
  @vortex.cd(dest_path)

  images = scrape_images(doc)

  images.each do |image|
    filenames = download_image(image[:url], dest_path)
    image[:vortex_url] = filenames[:vortex_url_resized]
    image[:vortex_url_org] = filenames[:vortex_url]
  end

  attributes = {:title => title,
    :introduction => introduction,
    :body => body,
    :publishedDate => Time.now}

  if(images.first)then
    attributes[:picture] = images.first[:vortex_url]
  end

  article  = Vortex::StructuredArticle.new(attributes )
  url = @vortex.publish(article)

  # Add additional images to bottom of page
  images_html = ""
  if(images.size > 1)then
    images[1..images.size].each do |image|
      image_html = <<EOF
        <p>
          <div class="vrtx-introduction-image" style="width: 300px; ">
            <a title="Last ned bilde i full størrelse" href="#{image[:vortex_url_org]}">
              <img src="#{image[:vortex_url]}" style="width: 300px;" />
            </a>
            <div class="vrtx-imagetext">
              <div class="vrtx-imagedescription">
                #{image[:caption]}
              </div>
            </div>
          </div>
        </p>
EOF
      images_html = images_html + image_html
    end
  end

  # Reopen document and set caption on article image
  if(images.first)then
    @vortex.find(url) do |item|
      data = JSON.parse(item.content)

      caption = ""
      if(images.first[:caption])then
        caption = images.first[:caption]
      end
      caption = caption + " <a href=\"#{images.first[:vortex_url_org]}\">Last ned i full størrelse</a>"
      data["properties"]["caption"] = caption

      # Add addiitional images at bottom
      data["properties"]["content"] = data["properties"]["content"] + images_html
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

  # puts title
  # puts
  # puts url
  uri = URI.parse(url)
  path = uri.path
  # puts path
  published_path = publish_article(path, title, introduction, body, doc)
  log = path + ";" + URI.parse(published_path).path
  # puts
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

  if( http_status_code(url) == 404)then
    puts "Advarsel: Status code 404: " + url
    return
  end

  # Ad-hoc rule to ignore path
  if(url =~ /\/kunnskapsbasen\/Presse/)then
    puts "Advarsel: Ignorerer pressesidene har for store bilder for vortex: url"
    return
  end

  doc = Nokogiri::HTML.parse(open(url))
  doc.encoding = 'utf-8'

  if(doc.css(".folder .list").size > 0 )then
    puts "Scraping article listing page: " + url
    doc.css(".folder .list .article").each do |article|
      href = article.css(".title a").attr("href").text
      begin
        href = href.gsub("%20","")
      rescue
      end
      scrape_article_listing(href)
    end
  else
    # Pages without .folder .list is articles
    puts "Scraping article: " + url
    scrape_article(url)
  end

end

if @vortex.exists?('/konv/kunnskapsbasen/aktor') then
  @vortex.delete('/konv/kunnskapsbasen/aktor')
end
@url = "http://www.hlsenteret.no/kunnskapsbasen/"

# scrape_article_listing(@url + "aktor/")
# exit

# Denne har 4 bilder
# scrape_article("http://www.hlsenteret.no/kunnskapsbasen/folkemord/armenerne/1334")

# Denne har ingen tittel og skal ignoreres
# scrape_article('http://www.hlsenteret.no/kunnskapsbasen/tradisjoner/86')

# Denne returnerer 404
# scrape_article_listing("http://www.hlsenteret.no/kunnskapsbasen/tema/kunst")

# Denne har bilder som er for store vortex
# scrape_article_listing("http://www.hlsenteret.no/kunnskapsbasen/Presse/")


# scrape_article('http://www.hlsenteret.no/kunnskapsbasen/tema/relpol/10129')

scrape_article_listing(@url)

# url = "http://www.hlsenteret.no/kunnskapsbasen/ideologi/nazisme/1143"
# url = "http://www.hlsenteret.no/kunnskapsbasen/aktor/diktatorer/1595"
# scrape_article(url)

