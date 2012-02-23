# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'uri'
require 'pry'
require 'paint'

def get_collection_title(url)
  title = nil
  path = url
  path = path.sub(/[^\/]*$/,'')
  begin
    doc = @vortex.propfind( path )
    title = doc.xpath('//v:collectionTitle', "v" => "vrtx").last.children.first.inner_text
  rescue
    puts "Warning: Unable to read folder title: " + path
    title = ""
  end
end

def set_collection_title(url,title)
  uri = URI.parse( url.sub(/[^\/]*$/,'') )
  @vortex.proppatch(uri.path,'<v:userTitle xmlns:v="vrtx">' + title + '</v:userTitle>')
end

@dav_connections = { }

def rename_folder(url, title)
  host = URI.parse(url).host.to_s
  if(not(@dav_connections[host]))
    puts "Connecting to #{host}..."
    @vortex = Vortex::Connection.new(url, :use_osx_keychain => true)
    @dav_connections[host] = @vortex
  else
    @vortex = @dav_connections[host]
  end

  # if( @vortex == nil)
  #   puts "Connecting..."
  #   @vortex = Vortex::Connection.new(url, :use_osx_keychain => true)
  # end

  old_title = get_collection_title(url)
  begin
    set_collection_title(url,title)
  rescue
    puts "Warning: Unable to change title for #{url} (#{title})"
  end
  new_title = get_collection_title(url)
  if(new_title != title) then
    puts "Warning! Unable to update title: " + url + " => " + title
  else
    puts url + " => " + title
  end

end
