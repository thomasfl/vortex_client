# Search and replace a set of sentences in a set of folders on vortex webdav server.
#
# Author: Thomas Flemming thomasfl@usit.uio.no

require 'rubygems'
require 'vortex_client'
require 'json'

replacements =  {
  "<h2>Teaching</h2>" => "<h2>Courses taught</h2>",
  "<h2>Higher education and employment history</h2>" => "<h2>Background</h2>",
  "<h2>Honoraria</h2>" => "<h2>Awards</h2>",
  "<h2>Appointments</h2>" => "<h2>Positions held</h2>",
  "<h2>Cooperation</h2>" => "<h2>Partners</h2>"
}

folders = [
  "/isv/english/people/aca/",
  "/iss/english/people/aca/",
  "/psi/english/people/aca/",
  "/sai/english/people/aca/",
  "/econ/english/people/aca/",
  "/arena/english/people/aca/",
  "/tik/english/people/aca/"
]

vortex = Vortex::Connection.new("https://nyweb1-dav.uio.no/",:use_osx_keychain => true)

folders.each do |folder|

  vortex.find(folder,:recursive => true,:filename=>/\.html$/) do |item|
    puts item.uri.to_s
    data = JSON.parse(item.content)
    content = data["properties"]["content"]
    replacements.each do |key,val|
      content = content.gsub(key,val)
    end
    data["properties"]["content"] = content
    item.content = data.to_json
  end

end
