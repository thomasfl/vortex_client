require 'rubygems'
require 'vortex_client'

# Upload a binary file to Vortex

def get_file_as_string(filename)
  data = ''
  f = File.open(filename, "r")
  f.each_line do |line|
    data += line
  end
  return data
end

vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")
vortex.cd('/brukere/thomasfl/')
content = get_file_as_string("dice.gif")
vortex.put_string("dice_6.gif", content)
