# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'open-uri'
require 'time'
## require 'ldap_util'

class PersonPresentasjon

  def initialize(uri,user,pwd)
    @vortex = Vortex::Connection.new(uri,user,pwd)
  end


  def find_pictures(src_url, dest_url, language)
    count = 0
    @vortex.find('.',:recursive => true,:suppress_errors => true) do |item|
      url = item.url.to_s
      if(item.type == :directory) then
        new_url = url.gsub(src_url,dest_url)
        create_person_listing_folder(new_url)
      elsif(url.match(/\.jpg$|\.png$/i)) then
        dest_folder = url.gsub(src_url,dest_url)
        dest_folder = dest_folder.sub(/\.jpg$|\.png$/i,'/')
        create_person_presentation(url, dest_folder, language)
      end

      # exit if(count > 6) # TODO Remove this
      count += 1
    end

    puts
    puts "Done creating " + count.to_s + " presentations."
  end

  def create_person_listing_folder(new_url)
    mkdir(new_url)
    puts "Reading folder: " + new_url
    props = '<v:collection-type xmlns:v="vrtx">person-listing</v:collection-type>' +
      '<v:resourceType xmlns:v="vrtx">person-listing</v:resourceType>'
    begin
      @vortex.proppatch(new_url, props )
    rescue
      puts "Warning: problems patching folder: " + new_url
    end
  end

  def create_person_presentation(url, dest_folder, language)
    username = dest_folder.sub(/\/$/,'')[/([^\/]*)$/,1]
    dest_image_url = dest_folder + url[/([^\/]*)$/,1]
    mkdir(dest_folder)
    copy(url,dest_image_url)
    create_json_doc(username, dest_folder, dest_image_url, language)
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

  def person_presentation_json(args)
    image_path = args[:image_path]
    image_path = image_path.sub(/^https?:\/\/[^\/]*/i,'')
    image_path = File.basename(image_path)
    if(args[:language] && args[:language] == :english) then
      html_xxx = '<h2>Tasks performed<\/h2>\r\n<p>Add information about job duties, as a short text or a bulleted list:<\/p>' +
        '\r\n<ul>\r\n' +
        '<li>&lt;Task 1&gt;<\/li>\r\n' +
        '<li>&lt;Task 1&gt;<\/li>\r\n' +
        '<li>...<\/li>\r\n<\/ul>\r\n<h2>Background<\/h2>\r\n<p>Add information about previous education and employment.<\/p>'
      html = ''
    else
      html = '<h2>Arbeidsomr&aring;der<\/h2>\r\n<p>Her kan du skrive om arbeidsomr&aring;der, ' +
        'enten som kort tekst eller som listepunkter:</p>' +
        '\r\n' +
        '<ul>\r\n    <li>&lt;Arbeidsomr&aring;de 1&gt;</li>\r\n    '+
        '<li>&lt;Arbeidsomr&aring;de 1&gt;</li>\r\n    <li>...</li>\r\n</ul>' +
        '\r\n<h2>Bakgrunn</h2>\r\n<p>Eventuelt kort om tidligere arbeidserfaring og utdanning.</p>'
    end

    json = ''
  json = <<EOF
{
   "resourcetype": "person",
   "properties":    {
      "getExternalPersonInfo": "true",
      "picture": "#{image_path}",
      "content": "#{html}",
      "getExternalScientificInformation": "false",
      "username": "#{args[:username]}",
      "getRelatedGroups": "true",
      "getRelatedProjects": "true"
   }
}
EOF
    return json
  end

  def proppatch_person_presentasjon(json_url,language)
    time = Time.now.httpdate.to_s
    properties = '<v:publish-date xmlns:v="vrtx">' + time + '</v:publish-date>' +
            '<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>' +
            '<d:getcontenttype>application/json</d:getcontenttype>' +
            '<v:resourceType xmlns:v="vrtx">person</v:resourceType>'
    if(language == :english) then
      properties += '<d:getcontentlanguage>en</d:getcontentlanguage>'
    else
      ## properties += '<d:getcontentlanguage>no</d:getcontentlanguage>'
    end

    begin
      @vortex.proppatch(json_url, properties)
    rescue
      puts "Warning: error while proppatching: " + json_url
    end
  end

  def create_json_doc(username, path, image_path, language)
    json = person_presentation_json(:username => username, :image_path => image_path, :language => language)
    json_url = path + 'index.html'

    puts "Create person page: " + json_url
    @vortex.put_string(json_url,json)
    proppatch_person_presentasjon(json_url, language)

#    realname = ldap_realname(username)
#    if(realname) then
#      @vortex.proppatch(path, '<v:userTitle xmlns:v="vrtx">' + realname + '</v:userTitle>')
#    else
#      puts "Warning: Unable to get info from ldap on: " + username
#    end
  end

end

user = ask("Username : ") {|q| q.echo = true}
pass = ask("Password  : ") {|q| q.echo = false}
if(!pass)then
  puts "Usage: export DAVPASS=pass "
  exit
end

host = 'https://www2-dav.uio.no'

src_url = host + '/personer/person-bilder/'
dest_url = host + '/english/people/'  # 'personpresentasjoner/'

presentasjoner = PersonPresentasjon.new(src_url, user, pass)
presentasjoner.find_pictures(src_url, dest_url, :english)

