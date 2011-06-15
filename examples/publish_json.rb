require 'rubygems'
require 'vortex_client'
require 'json'

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/", :osx_keychain => true)

data = {
  :resourcetype => "structured-article",
  :properties => {
    :title => "Hello world",
    :introduction => "Short introduction",
    :content => "<p>Longer body</p>",
    :author => "Thomas Flemming"}
}

uri = URI.parse('/brukere/thomasfl/nyheter/json_test.html')
vortex.put_string(uri,data.to_json)

vortex.proppatch(uri, '<v:publish-date xmlns:v="vrtx">' + Time.now.httpdate.to_s + '</v:publish-date>')

