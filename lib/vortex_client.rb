# -*- coding: utf-8 -*-
require 'net/dav'
require 'vortex_client/string_utils'
require 'highline/import'
require 'time'



# Utilities for managing content in the web content management system Vortex.
# All calls are done with the webdav protocol.
module Vortex

  class Connection < Net::DAV

    # Create a new connection to Vortex. Prompts for username and password if not
    # supplied. Overrides Net::DAV.initialize()
    #
    # Examples:
    #
    #   vortex = Vortex::Connection.new("https://www-dav.server.com",user,pass)
    #
    #   vortex = Vortex::Connection.new("https://www-dav.server.com") =>
    #   Username: tiger
    #   Password: *****
    def initialize(uri, *args)
      @uri = uri
      @uri = URI.parse(@uri) if @uri.is_a? String
      @have_curl = false # This defaults to true in Net::DAV
      @handler = NetHttpHandler.new(@uri)
      @handler.verify_server = false # This defaults to true in Net::DAV
      if(args != [])
        @handler.user = args[0]
        @handler.pass = args[1]
      else
        @handler.user = ask("Username: ") {|q| q.echo = true}
        @handler.pass = ask("Password: ") {|q| q.echo = "*"} # false => no echo
      end
      return @handler
    end

    # Returns true if resource or collection exists.
    #
    # Example:
    #
    #    vortex.exists?("https://www-dav.server.com/folder/index.html")
    def exists?(uri)
      uri = URI.parse(uri) if uri.is_a? String
      begin
        self.propfind(uri.path)
      rescue Net::HTTPServerException => e
        return false if(e.to_s =~ /404/)
      end
      return true
    end

    # Publish a document object to the web.
    #
    # Publishes a object by performing a PUT request to object.url with object.content
    # and then performing a PROPPATCH request to object.url with object.properties
    #
    # Example:
    #
    #   vortex = Vortex::Connection.new("https://www-dav.server.com")
    #   article = Vortex::StructuredArticle(:title=>"My title")
    #   vortex.publish(article)
    def publish(object)
      if(object.is_a? HtmlArticle or object.is_a? HtmlEvent or object.is_a? StructuredArticle)
        uri = @uri.merge(object.url)
        # puts "DEBUG: '" + object.class.to_s + "=" + object.properties
        self.put_string(uri, object.content)
        self.proppatch(uri, object.properties)
        return uri.to_s
      else
        warn "Unknown vortex resource: " + object.class.to_s
      end
    end

    # Creates collections
    #
    # Example:
    #
    #   connection = Connection.new('https://host.com')
    #   collecion = ArticleListingCollection.new(:url => '/url')
    #   connection.create(collection)
    def create(object)
      if(object.is_a? Collection)
        uri = @uri.merge(object.url)
        self.mkdir(uri)
        self.proppatch(uri, object.properties)
        return uri.to_s
      end
    end

    private

    # Disable Net::DAV.credentials
    def credentials(user, pass)
    end

  end

  # Gimmick the internal resource hierarchy in Vortex as class hierarchy in ruby
  # with resource as the root class.
  class Resource
  end

  # PlainFile: This is the same as 'File' in Vortex.
  class PlainFile < Resource
    # Named PlainFile so it won't get mixed up with standard File class.
  end

  # HtmlArticle: Plain HTML files with title, introduction and keywords set as WebDAV properties.
  #
  # Examples:
  #
  #   article = HtmlArticle.new(:title => "Sample Title",
  #                             :introduction => "Introduction",
  #                             :body => "<p>Hello world</p>")
  #   vortex.publish(article)
  class HtmlArticle < PlainFile

    attr_accessor :title, :introduction, :body, :filename, :modifiedDate, :publishedDate, :owner, :url, :author, :date, :tags, :picture

    # Create a new article of type html-article: plain html file with introduction stored as a webdav property.
    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}
    end

    def to_s
      "#<Vortex::HtmlArticle "+instance_variables.collect{|var|var+": "+instance_variable_get(var).to_s}.join(",")+">"
    end

    def url
      if(@url)
        @url
      else
        if(filename)
          filename
        end
        if(title)
          StringUtils.create_filename(title) + ".html"
        else
          warn "Article must have either a full url or title. "
        end
      end
    end

    def escape_html(str)
      new_str = str.gsub("&#xD;","")        #remove line break
      new_str = new_str.gsub("\"","&quot;") #swaps " to html-encoding
      new_str = new_str.gsub("'","&#39;")   #swaps ' to html-encoding
      new_str = new_str.gsub("<","&lt;")
      new_str = new_str.gsub(">","&gt;")
      new_str = new_str.gsub(/'/, "\"") # Fnutter gir "not valid xml error"
      new_str = new_str.gsub("&nbsp;", " ") # &nbsp; gir også "not valid xml error"
      new_str = new_str.gsub("", "-") # Tankestrek til minustegn
      new_str = new_str.gsub("","&#39;")  # Fnutt
      new_str = new_str.gsub("","&#39;")  # Fnutt
      new_str = new_str.gsub("","&#39;")  # Fnutt
      new_str = new_str.gsub("","&#39;")  # Fnutt
      new_str = new_str.gsub("”","&#39;")  # Norske gåseøyne til fnutt
      return new_str
    end

    def properties
      props = '<v:resourceType xmlns:v="vrtx">article</v:resourceType>' +
        '<v:xhtml10-type xmlns:v="vrtx">article</v:xhtml10-type>' +
        '<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>'

      if(@publishedDate and @publishedDate != "")
        if(@publishedDate.kind_of? Time)
          @publishedDate = @publishedDate.httpdate.to_s
        end
        props += '<v:published-date xmlns:v="vrtx">' + @publishedDate + '</v:published-date>'
      end

      if(date and date != "")
        if(date.kind_of? Time)
          date = @date.httpdate.to_s
        end
        if(@publishedDate == nil or @publishedDate != "")
          props += '<v:published-date xmlns:v="vrtx">' + date + '</v:published-date>'
        end
        props += '<d:getlastmodified>' + date + '</d:getlastmodified>' +
        '<v:contentLastModified xmlns:v="vrtx">' + date + '</v:contentLastModified>' +
        '<v:propertiesLastModified xmlns:v="vrtx">' + date + '</v:propertiesLastModified>' +
        '<v:creationTime xmlns:v="vrtx">' + date + '</v:creationTime>'
      end

      if(picture)
        props += '<v:picture xmlns:v="vrtx">' + picture + '</v:picture>'
      end

      if(title)
        props += '<v:userTitle xmlns:v="vrtx">' + title + '</v:userTitle>'
      end
      if(owner)
        props += '<owner xmlns="vrtx">' + owner + '</owner>'
      end
      if(introduction and introduction != "")
        props += '<introduction xmlns="vrtx">' + escape_html(introduction) + '</introduction>'
      end
      if(author and author != "")
        props += '<v:authors xmlns:v="vrtx">' +
          '<vrtx:values xmlns:vrtx="http://vortikal.org/xml-value-list">' +
             '<vrtx:value>' + author + '</vrtx:value>' +
           '</vrtx:values>' +
        '</v:authors>'
      end

      if(tags and tags.kind_of?(Array) and tags.size > 0)
        props += '<v:tags xmlns:v="vrtx">' +
          '<vrtx:values xmlns:vrtx="http://vortikal.org/xml-value-list">'
        tags.each do |tag|
            props += "<vrtx:value>#{tag}</vrtx:value>"
        end
        props += '</vrtx:values></v:tags>'
      end
      return props
    end

    def content
      content = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" ' +
        '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
        '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>' + title + '</title>' +
        ' <link href="http://www.uio.no/profil/kupu/kupucontentstyles.css" type="text/css" rel="stylesheet"/>' +
        '</head><body>'
      if(body)
        content += body
      end
      content += '</body></html>'
    end

  end



  # HtmlEvent: Event document. Article with location, map url, start and end dates.
  #
  # Examples:
  #
  #     event = Vortex::HtmlEvent.new(:title => "Sample Event 1",
  #                                   :introduction => "Sample event introduction",
  #                                   :body => "<p>Hello world</p>",
  #                                   :startDate => Time.now, ## "22.01.2010 12:15",
  #                                   :endDate =>  Time.now + 60*60, ## "22.01.2010 13:00",
  #                                   :location => "Forskningsveien 3B",
  #                                   :mapUrl => "http://maps.google.com/123",
  #                                   :tags => ["vortex","testing"],
  #                                   :publishedDate => "05.01.2010 12:00")
  #    vortex.publish(event)
  class HtmlEvent < PlainFile

    attr_accessor :title, :introduction, :body, :filename, :modifiedDate, :publishedDate, :date,
    :owner, :url, :tags, :startDate, :endDate, :location, :mapUrl

    # Create a new article of type html-article: plain html file with
    # introduction stored as a webdav property.
    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}
    end

    def to_s
      "#<Vortex::HtmlEvent "+instance_variables.collect{|var|var+": "+instance_variable_get(var).to_s}.join(",")+">"
    end

    def url
      if(@url)
        @url
      else
        if(filename)
          filename
        end
        if(title)
          StringUtils.create_filename(title) + ".html"
        else
          warn "Article must have either a full url or title. "
        end
      end
    end

    def properties
      props = '<v:resourceType xmlns:v="vrtx">event</v:resourceType>' +
        '<v:xhtml10-type xmlns:v="vrtx">event</v:xhtml10-type>' +
        '<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>'

      if(@publishedDate and @publishedDate != "")
        if(@publishedDate.kind_of? Time)
          @publishedDate = @publishedDate.httpdate.to_s
        end
        props += '<v:published-date xmlns:v="vrtx">' + @publishedDate + '</v:published-date>'
      end

      if(@date and @date != "")
        if(@date.kind_of? Time)
          @date = @date.httpdate.to_s
        end
        if(@publishedDate == nil or @publishedDate != "")
          props += '<v:published-date xmlns:v="vrtx">' + date + '</v:published-date>'
        end
        props += '<d:getlastmodified>' + date + '</d:getlastmodified>' +
        '<v:contentLastModified xmlns:v="vrtx">' + date + '</v:contentLastModified>' +
        '<v:propertiesLastModified xmlns:v="vrtx">' + date + '</v:propertiesLastModified>' +
        '<v:creationTime xmlns:v="vrtx">' + date + '</v:creationTime>'
      end
      if(title)
        props += '<v:userTitle xmlns:v="vrtx">' + title + '</v:userTitle>'
      end
      if(owner)
        props += '<owner xmlns="vrtx">' + owner + '</owner>'
      end
      if(introduction and introduction != "")
        props += '<introduction xmlns="vrtx">' + introduction + '</introduction>'
      end

      if(tags and tags.kind_of?(Array) and tags.size > 0)
        props += '<v:tags xmlns:v="vrtx">' +
          '<vrtx:values xmlns:vrtx="http://vortikal.org/xml-value-list">'
        tags.each do |tag|
            props += "<vrtx:value>#{tag}</vrtx:value>"
        end
        props += '</vrtx:values></v:tags>'
      end


      if(@startDate and @startDate != "")
        if(@startDate.kind_of? Time)
          @startDate = @startDate.httpdate.to_s
        end
        props += '<v:start-date xmlns:v="vrtx">' + @startDate + '</v:start-date>'
      end

      if(@endDate and @endDate != "")
        if(@endDate.kind_of? Time)
          @endDate = @endDate.httpdate.to_s
        end
        props += '<v:end-date xmlns:v="vrtx">' + @endDate + '</v:end-date>'
      end

      if(@location and @location != "")
        props += '<v:location xmlns:v="vrtx">' + @location + '</v:location>'
      end
      if(@mapUrl and @mapUrl != "")
        props += '<v:mapurl xmlns:v="vrtx">' + @mapUrl + '</v:mapurl>'
      end
      return props
    end

    # TODO: Samme kode som i article... Bruk arv!
    def content
      content = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" ' +
        '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
        '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>' + title + '</title>' +
        ' <link href="http://www.uio.no/profil/kupu/kupucontentstyles.css" type="text/css" rel="stylesheet"/>' +
        '</head><body>'
      if(body)
        content += body
      end
      content += '</body></html>'
    end

  end


  # Vortex article stored as JSON data.
  # TODO: Fill out the stub.
  class StructuredArticle <  HtmlArticle

    attr_accessor :title, :introduction, :content, :filename, :modifiedDate, :publishedDate, :owner, :url, :picture

    # Create an article
    # Options:
    #
    #   :title => "Title" mandatory
    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}
    end


    def url
      if(@url)
        @url
      else
        if(filename)
          filename
        end
        if(title)
          StringUtils.create_filename(title) + ".html"
        else
          warn "Article must have either a full url or title. "
        end
      end
    end

    def to_s
      "#<Vortex::StructuredArticle "+instance_variables.collect{|var|var+": "+instance_variable_get(var).to_s}.join(",")+">"
    end


    def content
      json = <<-EOF
      {
         "resourcetype": "structured-article",
         "properties": {
      EOF
      if(body and body.size > 0)
        tmp_body = body
        # Escape '"' and line shifts so html will be valid json data.
        tmp_body = body.gsub(/\r/,"\\\r").gsub(/\n/,"\\\n").gsub(/\"/,"\\\"")
        json += "           \"content\": \"#{tmp_body}\",\n"
      end
      if(author and author.size > 0)
        json += "           \"author\": [\"#{author}\"],\n"
      end
      json += "           \"title\": \"#{title}\",\n"
      if(introduction and introduction.size > 0)
        tmp_introduction = introduction
        tmp_introduction = tmp_introduction.gsub(/\r/,"\\\r")
        tmp_introduction = tmp_introduction.gsub(/\n/,"\\\n")
        tmp_introduction = tmp_introduction.gsub(/\"/,"\\\"")
        json += "           \"introduction\": \"#{tmp_introduction}\",\n"
      end
      if(picture)
        json += "           \"picture\": \"#{picture}\",\n"
      end
      json += <<-EOF
           "hideAdditionalContent": "false"
         }
      }
      EOF
      return json
    end

    def properties
      props = '<v:resourceType xmlns:v="vrtx">structured-article</v:resourceType>' +
    #     '<v:xhtml10-type xmlns:v="vrtx">structured-article</v:xhtml10-type>' +
        '<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>' +
        '<d:getcontenttype>application/json</d:getcontenttype>'

      if(@publishedDate and @publishedDate != "")
        if(@publishedDate.kind_of? Time)
          @publishedDate = @publishedDate.httpdate.to_s
        end
        props += '<v:published-date xmlns:v="vrtx">' + @publishedDate + '</v:published-date>'
      end

      if(date and date != "")
        if(date.kind_of? Time)
          date = @date.httpdate.to_s
        end
        if(@publishedDate == nil or @publishedDate != "")
          props += '<v:published-date xmlns:v="vrtx">' + date + '</v:published-date>'
        end
        props += '<d:getlastmodified>' + date + '</d:getlastmodified>' +
        '<v:contentLastModified xmlns:v="vrtx">' + date + '</v:contentLastModified>' +
        '<v:propertiesLastModified xmlns:v="vrtx">' + date + '</v:propertiesLastModified>' +
        '<v:creationTime xmlns:v="vrtx">' + date + '</v:creationTime>'
      end

      if(picture)
#        props += '<v:picture xmlns:v="vrtx">' + picture + '</v:picture>'
      end

      if(title)
#        props += '<v:userTitle xmlns:v="vrtx">' + title + '</v:userTitle>'
      end
      if(owner)
        props += '<owner xmlns="vrtx">' + owner + '</owner>'
      end
      if(introduction and introduction != "")
#        props += '<introduction xmlns="vrtx">' + escape_html(introduction) + '</introduction>'
      end
      if(author and author != "")
#        props += '<v:authors xmlns:v="vrtx">' +
#          '<vrtx:values xmlns:vrtx="http://vortikal.org/xml-value-list">' +
#             '<vrtx:value>' + author + '</vrtx:value>' +
#           '</vrtx:values>' +
#        '</v:authors>'
      end

      if(tags and tags.kind_of?(Array) and tags.size > 0)
 #       props += '<v:tags xmlns:v="vrtx">' +
 #         '<vrtx:values xmlns:vrtx="http://vortikal.org/xml-value-list">'
 #       tags.each do |tag|
 #           props += "<vrtx:value>#{tag}</vrtx:value>"
 #       end
 #       props += '</vrtx:values></v:tags>'
      end
      return props
    end


  end



  # Collection (folder)
  class Collection < Resource
    attr_accessor :title, :url, :foldername, :name, :introduction, :navigationTitle, :sortByDate, :sortByTitle, :owner

    def url
      if(@url)
        return @url
      end
      if(@foldername)
        return @foldername
      end
      if(@name)
        return @name
      end
      if(@title)
        return StringUtils.create_filename(title)
      end
      return "no-name"
    end

    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}
    end

    def to_s
      "#<Vortex::Collection "+instance_variables.collect{|var|var+": "+instance_variable_get(var).to_s}.join(",")+">"
    end

    def properties()
      # props = "<v:resourceType xmlns:v=\"vrtx\">collection</v:resourceType>" +
      #  "<v:collection-type xmlns:v=\"vrtx\">article-listing</v:collection-type>"
      props = ""
      if(title and title != "")
        props += "<v:userTitle xmlns:v=\"vrtx\">#{title}</v:userTitle>"
      end
      if(navigationTitle and navigationTitle != "")
        props += "<v:navigationTitle xmlns:v=\"vrtx\">#{navigationTitle}</v:navigationTitle>"
      end
      if(owner and owner != "")
        props += "<owner xmlns=\"vrtx\">#{owner}</owner>"
      end
      return props
    end

  end

  # Article listing collection
  #
  # Examaple:
  #
  #   collection = ArticleListingCollection(:url => 'news')
  #   collection = ArticleListingCollection(:foldername => 'news')
  #   collection = ArticleListingCollection(:title => 'My articles')
  #   collection = ArticleListingCollection(:title => 'My articles',
  #                                         :foldername => 'articles',
  #                                         :navigationTitle => 'Read articles')
  class ArticleListingCollection < Collection

    def properties()
      props = super
      props += "<v:resourceType xmlns:v=\"vrtx\">article-listing</v:resourceType>" +
        "<v:collection-type xmlns:v=\"vrtx\">article-listing</v:collection-type>"
      return props
    end

  end


  class EventListingCollection < Collection

    def properties()
      props = super
      props += "<v:resourceType xmlns:v=\"vrtx\">event-listing</v:resourceType>" +
        "<v:collection-type xmlns:v=\"vrtx\">event-listing</v:collection-type>"
      return props
    end

  end



  # Utilities
  #
  # Convert norwegian date to Time object with a forgiven regexp
  #
  # TODO: Move this somewhere.
  #
  # Examples:
  #
  #   t = norwegian_date('1.1.2010')
  #   t = norwegian_date('22.01.2010')
  #   t = norwegian_date('22.01.2010 12:15')
  #   t = norwegian_date('22.01.2010 12:15:20')
  def norwegian_date(date)
    if /\A\s*
            (\d\d?).(\d\d?).(-?\d+)
            \s?
            (\d\d?)?:?(\d\d?)?:?(\d\d?)?
            \s*\z/ix =~ date
      year = $3.to_i
      mon = $2.to_i
      day = $1.to_i
      hour = $4.to_i
      min = $5.to_i
      sec = $6.to_i

      # puts "Debug: #{year} #{mon} #{day} #{hour}:#{min}:#{sec}"

      usec = 0
      usec = $7.to_f * 1000000 if $7
      if $8
        zone = $8
        year, mon, day, hour, min, sec =
          apply_offset(year, mon, day, hour, min, sec, zone_offset(zone))
        Time.utc(year, mon, day, hour, min, sec, usec)
      else
        Time.local(year, mon, day, hour, min, sec, usec)
      end
    else
      raise ArgumentError.new("invalid date: #{date.inspect}")
    end
  end


end




