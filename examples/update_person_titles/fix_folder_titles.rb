require 'rubygems'
require 'vortex_client'
require 'ldap_util'
require 'nokogiri'
require 'open-uri'
require 'pp'
require 'json'
require 'uri'

# Ex. log('logfilename.log','Message'
def log(filename, message)
  open(filename, 'a') do |f|
    f.puts message
  end
  # puts message
end


# Description: Changes title names used for folders containing personal
#              presentations if it's different from the real name found
#              in ldap
#
# Examaple:    Folder title "Group lead Even Halvorsen" will be changed
#              to "Even Halvorsen"

class FixFolderTitles

  attr :vortex, :url

  def initialize(url)
    @url = url
    @vortex = Vortex::Connection.new(url, :use_osx_keychain => true)
  end

  def get_username(path)
    json = JSON.parse( @vortex.get(path) )
    return json["properties"]["username"]
  end

  def get_realname(username)
    return ldap_realname(username)
  end

  def get_folder_title(path)
    title = nil
    path = path.sub(/[^\/]*$/,'')
    begin
      doc = @vortex.propfind( path )
      title = doc.xpath('//v:collectionTitle', "v" => "vrtx").last.children.first.inner_text
    rescue
      puts "Warning: Folder title not set: " + path
      title = ""
    end
    return title
  end

  def scrape_page(url)
    result = []
    doc = Nokogiri::HTML(open(url))
    doc.xpath('//td[@class="vrtx-person-listing-name"]/a[@class="vrtx-link-check"]').each do |link|
      result << link['href']
    end
    return result
  end

  def normal_url()
    return @url.sub('www-dav','www').sub(/^https/,'http')
  end

  def crawler(path)
    url = normal_url + path
    result = []
    page = 1
    links = scrape_page(url + "?page=" + page.to_s)
    while(links.size > 0) do
      result = result + links
      page = page + 1
      links = scrape_page(url + "?page=" + page.to_s)
    end
    puts "Found " + result.size.to_s + " persons in " + url
    return result
  end

  def check_realname_and_folder_title(path)
    path = path.gsub(/\s/, '%20')
    folder_title = get_folder_title(path).to_s.strip
    username = get_username(path).to_s
    realname = get_realname(username).to_s.strip

    if(realname == "")then
      log('personpresentasjoner_med_feil.txt',
          "Username: '" + username + "' Presentation: '" + @url + path + "' Name:'" + folder_title + "'")
    end

    if(folder_title != realname and realname != "")then
      puts "rename_folder('" + @url + path.sub("index.html","") + "','" + realname + "') #" + folder_title
    end

  end

end

def find_persons_not_in_ldap(url)
  uri = URI.parse(url)
  dav_url = 'https://' + uri.host.sub(/(\.)/,'-dav.')
  fixer = FixFolderTitles.new(dav_url)

  links = fixer.crawler(uri.path)
  links.each do |link|
    fixer.check_realname_and_folder_title(link)
  end
end

if __FILE__ == $0 then
  puts "Start"

  #  www.odont.uio.no, www.sv.uio.no, www.hf.uio.no og www.uio.no
  #  www.jus.uio.no, www.tf.uio.no, www.uv.uio.no og www.ub.uio.no

  hosts = [
           # 'http://www.odont.uio.no/personer/',
           # 'http://www.sv.uio.no/personer/',
           # 'http://www.hf.uio.no/personer/',
           # 'http://www.uio.no/personer/adm/',
           # 'http://www.jus.uio.no/personer/',
           # 'http://www.tf.uio.no/personer/',
           # 'http://www.ub.uio.no/personer/',
           # 'http://www.mn.uio.no/personer/',
           # 'http://www.mn.uio.no/english/people/',
           # 'http://www.sv.uio.no/english/people/',
           # 'http://www.hf.uio.no/english/people/',
           # 'http://www.uio.no/english/people/adm/',
           # 'http://www.jus.uio.no/english/people/',
           'http://www.tf.uio.no/english/people/',
           'http://www.ub.uio.no/english/people/'
           # 'http://www.usit.uio.no/english/people/',
           # 'http://www.usit.uio.no/personer'
          ]

  hosts.each do |url|
    find_persons_not_in_ldap(url)
  end
end
