require 'rubygems'
require 'vortex_client'

# Find all files recursively under '/people' with name 'index.html', and set them to "unpublished"
@vortex = Vortex::Connection.new("https://nyweb2-dav.uio.no/", :use_osx_keychain => true)
@vortex.find('/people/', :recursive => true, :filename=>/\.html$/) do |item|
  item.proppatch('<v:unpublish-date xmlns:v="vrtx">'+Time.now.httpdate.to_s+'</v:unpublish-date>')
end
