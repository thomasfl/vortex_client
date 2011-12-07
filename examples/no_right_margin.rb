# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'json'
require 'nokogiri'

vortex = Vortex::Connection.new('https://www-dav.usit.uio.no', :osx_keychain => true)

# Skru av "Vis relatert innhold" på alle filer under en mappe.
vortex.find('/om/organisasjon/sapp/dba/dokumentasjon/.', :recursive=>true)do|item|
  if(item.type == :file and item.url.to_s[/\.html$/])
    begin
      data = JSON.parse(item.content)
      data["properties"]["showAdditionalContent"] = "false"
      item.content = data.to_json
      puts "Updating: #{item.url.to_s}"
    rescue Exception => exception
      puts "Error: #{item.url.to_s} : #{exception.to_s}"
    end
  end
end
