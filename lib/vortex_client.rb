require 'net/dav'

module Vortex

  class Connection

    def initialize(uri)
      @dav = Net::DAV.new(uri, :curl => false)
      @dav.verify_server = false
      return @dav
    end

    def credentials(user,pass)
      @user = user
      @pass = pass
      @dav.credentials(user, pass)
    end


    def cd(uri)
      @dav.cd(uri)
    end

    def exists?(url)
      uri = URI.parse(url)
      # @dav = connect(url)
      if(!@dav)
        @dav = connect(url)
      end
      begin
        @dav.propfind(uri.path)
      rescue Net::HTTPServerException => e
        return false if(e.to_s =~ /404/)
      end
      return true
    end

    # Returns properties for webdav resource as xml
    def properties(url)
      uri = URI.parse(url)
      if(exists?(url))
        @dav.propfind(uri.path).to_s
      else
        throw "404 File not found"
      end
    end

    # Gets resource (file) from webdav server
    def get(url)
      uri = URI.parse(url)
      if(exists?(url))
        @dav.get(uri.path).to_s
      else
        throw "404 File not found"
      end
    end

    def publish(object)
      puts "DEBUG: publish object: " + object.class.to_s
      props = object.dav_properties
      content = object.dav_content
      puts props + " " + content + " " + @dav.content
    end

  end


  class Resource
  end

  # Vortex file. Named PlainFile so it won't get mixed up with standard File class.
  class PlainFile < Resource
  end

  class StructuredArticle < PlainFile

    attr_accessor :title, :introduction, :content, :filename, :modifiedDate, :publishedDate, :owner, :url

    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}
    end

    def dav_properties
      "<xml todo>"
    end

    def dav_content
      "<html todo>"
    end

  end

end




