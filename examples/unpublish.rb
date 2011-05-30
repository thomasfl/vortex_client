require 'rubygems'
require 'vortex_client'

# Hides documents for visitors by setting the documents unpublish-date to current time and date.
#
# Find all files recursively under '/people' with name 'index.html', and set "unpublished-date" to now.

@vortex = Vortex::Connection.new("https://nyweb2-dav.uio.no/", :osx_keychain => true)
@vortex.find('/people/', :recursive => true, :filename=>/\.html$/) do |item|
  item.proppatch('<v:unpublish-date xmlns:v="vrtx">'+Time.now.httpdate.to_s+'</v:unpublish-date>')
end
