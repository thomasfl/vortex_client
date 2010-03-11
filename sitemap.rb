# -*- coding: utf-8 -*-
# Generate sitemap from WebDAV tree:
#
# Example:
#
# $ruby generate_vortex_sitemap.rb http://www.iss.uio.no/
#
# Author: Thomas Flemming, thomas.flemming@usit.uio.no 2010
#
require "net/https"
require "uri"

require 'rubygems'
require 'vortex_client'
require 'open-uri'

user = ask("Username : ") {|q| q.echo = true}
pwd  = ask("Pssword  : ") {|q| q.echo = false}


# Returns "200" if everything's ok.
def responseCode(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  if(uri.scheme == "https")
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  return response.code
end


def property(item, xpath)
  namespaces = {'v' => "vrtx",'d' => "DAV:"}
  xml = item.propfind
  xml.xpath(xpath, namespaces).inner_text
end

def dav_url2http_url(url)
  if(url =~ /\/vortex-dav\./)
    url = url.sub( /\/vortex-dav\./, '/vortex.' )
  else
    url = url.sub(/https:\/\/www-dav\./,'http://www.')
  end
  return url
end

def http_url2dav_url(url)
  url = url.sub(/^http:\/\//i,'https://')
  url = url.sub(/^https?:\/\/www\./i,'https://www-dav.')
  return url
end

def outline_number(url)
  @numbering = [] if(@numbering == nil)
  @prev_url = "" if(@prev_url == nil)

  size = url.split(/\//).size
  prev_size = @prev_url.split(/\//).size

  if(size > prev_size)
    @numbering << 1
  end

  if(size < prev_size)
    index = size - 1
    # index = @numbering.size - 2
    @numbering = @numbering[0..index]
    @numbering[index] = @numbering.last + 1
  end

  if(prev_size == size)
    index = @numbering.size - 1
    @numbering[index] = @numbering.last + 1
  end

  @prev_url = url
  return @numbering.join(".")
end


url = ARGV[0]
dav_url = http_url2dav_url(url)

vortex = Vortex::Connection.new(dav_url,user,pwd)

vortex.find('.',:recursive => true,:suppress_errors => true) do |item|
  url = item.url.to_s
  if(url =~ /\/$/ ) # Print folders onlye
    collectionTitle = property(item,'.//v:collectionTitle') # Vortex folder title
    resourceType = property(item,'.//v:resourceType') # Vortex folder type
    http_url = dav_url2http_url(url)
    responseCode = responseCode(http_url)
    path = URI.parse(url).path
    foldername = path[/\/([^\/]*)\/$/,1]

    if(responseCode == "200" and not(foldername =~ /^[\.|_]/ or path =~ /^\/vrtx\// ) )
      number = outline_number(path)
      puts "#{number};#{foldername};#{http_url};#{collectionTitle}"
    end

  end
end

