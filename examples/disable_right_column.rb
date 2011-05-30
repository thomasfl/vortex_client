require 'rubygems'
require 'vortex_client'

vortex = Vortex::Connection.new('https://nyweb2-dav.uio.no/', :osx_keychain => true)
# url = 'https://nyweb2-dav.uio.no/for-ansatte/aktuelt/hf-aktuelt-mod/utg2/index.html'
url = '/for-ansatte/aktuelt/hf-aktuelt-mod/utg2/index.html'
snippet = '<hideAdditionalContent xmlns="http://www.uio.no/vrtx/__vrtx/ns/structured-resources">true</hideAdditionalContent>'
vortex.proppatch(url, snippet)
