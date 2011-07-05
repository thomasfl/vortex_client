require 'rubygems'
require 'vortex_client'
require 'open-uri'
require 'uri'
require 'pathname'

# Download and upload a binary file to Vortex

url = 'http://www.hlsenteret.no/248/267/Bakgrunn_Rwanda.pdf'
content = open(url).read

filename = Pathname.new( URI.parse(url).path ).basename.to_s

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")
vortex.cd('/brukere/thomasfl/')
vortex.put_string(filename, content)
