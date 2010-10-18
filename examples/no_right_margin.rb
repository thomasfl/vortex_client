require 'rubygems'
require 'vortex_client'

vortex = Vortex::Connection.new("https://www-dav.uio.no/")

no_right_margin = '<hideAdditionalContent ' +
  'xmlns="http://www.uio.no/vrtx/__vrtx/ns/structured-resources">true</hideAdditionalContent>'

vortex.find('/konv/om/profil/', :recursive=>true)do|item|
  item.proppatch(no_right_margin)
end
