require 'rubygems'
require 'vortex_client'
require 'ldap_util'
require 'nokogiri'

class MappeVasking

  def initialize
    @vortex = Vortex::Connection.new("https://www-dav.uio.no", :osx_keychain => true)
    @logfile = "renamed_person_folders_usit.log"
    @dirty_logfile = false
  end

  def log_renaming(path, org_title, new_title)
    # Empty logfile first:
    if(@dirty_logfile == false)then
      File.open(@logfile, 'w') do |f|
        f.write('')
      end
    end

    File.open(@logfile, 'a') do |f|
      f.write( "#{path}:#{org_title}:#{new_title}\n" )
    end

    @dirty_logfile = true
  end

  def is_person_folder?(item)
    if(item.type == :directory)
      if(@vortex.exists?(item.url.to_s + 'index.html'))
        begin
          props = @vortex.propfind(item.url.to_s + 'index.html')
        rescue
          return false
        end
        if(props.xpath("//v:resourceType", "v" => "vrtx").first)
          return props.xpath("//v:resourceType", "v" => "vrtx").first.text == "person"
        end
      end
    end
    return false
  end

  def folder_title(url)
    props = @vortex.propfind(url)
    # puts props.to_s
    return props.xpath("//v:collectionTitle", "v" => "vrtx").last.text
  end

  def start
    @person_folder_count = 1
    @vortex.find('/personer/adm/usit/.',:recursive => true,:suppress_errors => true) do |item|
      if(is_person_folder?(item))
        puts @person_folder_count.to_s + " folder: " + item.url.path.to_s
        @person_folder_count += 1

        username = item.url.path.to_s[/([^\/]*)\/$/,1]
        username = Iconv.iconv('ascii//ignore//translit', 'utf-8', username).to_s
        puts "  User : " + username

        folder_title = folder_title(item.url.to_s)
        puts "  Title: " + folder_title

        realname = nil
        begin
          realname = ldap_realname(username)
        rescue

        end

        if(realname)
          puts "  Real : " + realname

          if(realname != folder_title)
            puts "  Renaming folder..."
            vortex_error = false
            begin
              item.proppatch('<v:userTitle xmlns:v="vrtx">' + realname + '</v:userTitle>')
            rescue
              vortex_error = true
            end
            if(vortex_error)
              realname = "vortex-feil"
            end
            log_renaming(item.url.path.to_s, folder_title, realname)

          end
        else
          log_renaming(item.url.path.to_s, folder_title, "ldap-feil:" + username)
          puts "  *** LDAP error for " + username + " ***"
        end
      end
    end
  end

end

if __FILE__ == $0 then
  vasking = MappeVasking.new
  vasking.start
end
