# -*- coding: utf-8 -*-
#
# Create person presentations in vortex.
#
# Input is a vortex folder with images like this:
#
#    /person/
#       /adm/
#         username.jpg
#         user2.jpg
#
# For each image, the script creates a folder, a person presentation named index.html
# and moves the image file. After completion, the folder should look like this:
#
#    /person/
#       /adm/
#         username/
#           index.html
#           username.jpg
#         user2/
#           index.html
#           user2.jpg
#
# Author: Thomas Flemming   thomasfl (at) usit.uio.no

require 'rubygems'
require 'vortex_client'
require 'open-uri'
require 'time'
require 'ldap_util'

def create_person_listing_folder(new_url)
  mkdir(new_url)
  puts "Creating folder: " + new_url
  props = '<v:collection-type xmlns:v="vrtx">person-listing</v:collection-type>' +
    '<v:resourceType xmlns:v="vrtx">person-listing</v:resourceType>'
  begin
    @vortex.proppatch(new_url, props )
  rescue
    puts "Warning: problems patching folder: " + new_url
  end
end

def mkdir(url)
  begin
    @vortex.mkdir(url)
  rescue
    puts "Warning: mkdir(" + url + ") exists."
  end
end

def copy(src,dest)
  begin
    @vortex.copy(src,dest)
  rescue
    puts "Warning: cp(src," + dest + ") exists."
  end
end

def move(src,dest)
  begin
    @vortex.move(src,dest)
  rescue
    puts "Warning: move(src," + dest + ") exists."
  end
end


def delete(dest)
  begin
    @vortex.delete(dest)
  rescue
    puts "Warning: delete(" + dest + ") failed."
  end
end

def set_realname_as_title(username, path)
  realname = ldap_realname(username)
  if(realname) then
    @vortex.proppatch(path, '<v:userTitle xmlns:v="vrtx">' + realname + '</v:userTitle>')
  else
    puts "Warning: Unable to get info from ldap on: " + username
  end
end

def create_person_presentation(url, dest_folder, language)
  username = dest_folder.sub(/\/$/,'')[/([^\/]*)$/,1]
  dest_image_url = dest_folder + url[/([^\/]*)$/,1]
  mkdir(dest_folder)
  set_realname_as_title(username, dest_folder)

  copy(url,dest_image_url)

  if(url.to_s.match(/\/vit\//))then
    scientific = true
  else
    scientific = false
  end
  # scientific = true

  person = Vortex::Person.new(:user => username,
                            :image => dest_image_url,
                            :language => language,
                            :scientific => scientific,
                            :url => dest_folder + 'index.html')

  # Use the 'administrative' html template.
  # Override default html template used for scientific presentations.
  #    person.html = person.create_html(:language => language, :html_template => :administrative)

  @vortex.publish(person)
end


def create_presentations_from_images(src_url, dest_url, language)
  count = 0
  @vortex.find(src_url,:recursive => true,:suppress_errors => true) do |item|
    url = item.url.to_s
    if(item.type == :directory) then
      new_url = url.gsub(src_url,dest_url)
      create_person_listing_folder(new_url)
    elsif(url.match(/\.jpg$|\.png$/i)) then
      dest_folder = url.gsub(src_url,dest_url)
      dest_folder = dest_folder.sub(/\.jpg$|\.png$/i,'/')
      create_person_presentation(url, dest_folder, language)
    end
    count += 1
  end
  return count
end

# src_url = 'https://nyweb3-dav.uio.no/konv/ubo/'
src_url = 'https://nyweb1-dav.uio.no/personer/genererte-presentasjoner/econ/'
@vortex = Vortex::Connection.new(src_url, :osx_keychain => true)

# puts "Restore from backup..."
# delete(src_url)
# copy('https://nyweb3-dav.uio.no/konv/ubo_backup/', src_url)

dest_url = 'https://nyweb1-dav.uio.no/personer/genererte-presentasjoner/econ_generert/' ## https://nyweb3-dav.uio.no/konv/ubo_no/'
count = create_presentations_from_images(src_url, dest_url, :norwegian)
puts "\n\nDone. Created " + count.to_s + " presentations."

# dest_url = 'https://nyweb3-dav.uio.no/konv/ubo_en/'
# count = create_presentations_from_images(src_url, dest_url, :english)
# puts "\n\nDone. Created " + count.to_s + " presentations."

