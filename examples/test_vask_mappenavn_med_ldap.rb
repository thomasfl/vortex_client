require 'rubygems'
require 'vask_mappenavn_med_ldap'
require 'vortex_client'
require 'test/unit'
require 'shoulda'

class TestMappeVasking < Test::Unit::TestCase

  def setup
    @vortex = Vortex::Connection.new("https://www-dav.uio.no/konv/usit/", :osx_keychain => true)
    @vasker = MappeVasking.new()
  end

  should "get correct foldername " do
    url = '/personer/adm/usit/web/wapp/thomasfl/'
    puts @vasker.folder_title(url)

    # /personer/adm/usit/web/harell/
  end

end



