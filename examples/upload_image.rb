require 'rubygems'
require 'vortex_client'

# Upload a binary file to Vortex
vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")
vortex.cd('/brukere/thomasfl/')
content = get_file_as_string("dice.gif")
content = open("dice.gif", "rb") {|io| io.read }
vortex.put_string("dice_6.gif", content)
