# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'uri'

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

def rename_folder(url, title)
  if( @vortex == nil)then
    puts "Connecting..."
    @vortex = Vortex::Connection.new(url, :use_osx_keychain => true)
  end

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
