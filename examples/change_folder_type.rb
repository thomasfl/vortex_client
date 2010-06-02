require 'rubygems'
require 'vortex_client'

vortex = Vortex::Connection.new(ARGV[0])
vortex.find('.',:recursive => true,:suppress_errors => true) do |item|
  if(item.type == :directory) then
    puts "Converting "  +item.url.to_s
    item.proppatch('<v:collection-type xmlns:v="vrtx">person-listing</v:collection-type>')
  end
end
