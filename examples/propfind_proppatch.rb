require 'rubygems'
require 'vortex_client'

vortex = Vortex::Connection.new("https://www-dav.vortex-demo.uio.no/", :osx_keychain => true)
props = vortex.propfind('/index.html')
puts props

vortex.proppatch('/index.html','<v:title xmlns:v="vrtx">Forside vortex demo</v:title>')
