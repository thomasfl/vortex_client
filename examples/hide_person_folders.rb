# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'ldap_util'
require 'nokogiri'

# TODO
# - Fjerne personmapper fra navigasjon i venstremarg. Bare undernammper skal vises.
# - Endre navn på dette scriptet og refaktoriser litt

class MappeVasking

  def initialize
    @vortex = Vortex::Connection.new("https://www-dav.uio.no", :osx_keychain => true)
    @logfile = "hidden_person_folders_usit.log"
    @dirty_logfile = false
  end

  def log(string)
    # Empty logfile first:
    if(@dirty_logfile == false)then
      File.open(@logfile, 'w') do |f|
        f.write('')
      end
    end

    File.open(@logfile, 'a') do |f|
      f.write( "#{string}\n" )
    end

    @dirty_logfile = true
  end

  def start
    @person_folder_count = 1
    @vortex.find('/personer/adm/usit/.',:recursive => true,:suppress_errors => true) do |item|
      if(item.type == :directory and @vortex.exists?(item.url.to_s + 'index.html'))

        begin
          props = @vortex.propfind(item.url.to_s)
          response = props.xpath('//d:href[text()="' + item.url.to_s + 'index.html"]/..','d'=>'DAV:')
          resource_type = response.xpath(".//v:resourceType", "v" => "vrtx").last.text
          if(resource_type == "person")
            puts @person_folder_count.to_s + " folder: " + item.url.path.to_s
            @person_folder_count += 1

            response = props.xpath('//d:href[text()="' + item.url.to_s + '"]/..','d'=>'DAV:')
            value = response.xpath("//a:hidden","a" => "http://www.uio.no/navigation").last
            if(value == nil or value.text == "false")
              puts "  Hiding folder..."

              vortex_error = false
              begin
                item.proppatch('<hidden xmlns="http://www.uio.no/navigation">true</hidden>')
              rescue
                vortex_error = true
              end

              if(vortex_error)
                log("error:" + item.url.path.to_s)
              else
                log(item.url.path.to_s)
              end
            else
              puts "  *** Folder is hidden. ***"
            end

          end
        rescue
          log("forbidden-error:" + item.url.path.to_s)
        end
      end
    end
  end

end

if __FILE__ == $0 then
  vasking = MappeVasking.new
  vasking.start
end
