# -*- coding: utf-8 -*-
require 'uri'

module Vortex

  # Publish Person presentations on Vortex enabled web servers.
  #
  # Examples:
  #
  #     person = Vortex::Person.new(:user => 'thomasfl',
  #                                 :image => '/images/thomasfl.jpg',
  #                                 :language => :english,
  #                                 :scientific => true)
  #                                 :publishedDate => "05.01.2010 12:00")
  #    vortex.publish(person)
  #
  # Mandatory parameters:
  #    :user  => username
  #    :image => path to image ex. '/user
  #
  # Optional parameters:
  #     :language => :english or :norwegian (defaults)
  #     :scientific => false (default). Get list of publications
  #     :administrative = true (default). Same as :scientific => false
  #     :html => json encoded html. Ex
  #     :url  => path to presentation. Ex. '/persons/thomas.html'
  #     :publishedDate => date to be published. Defaults to now. Ex. "05.01.2010 12:00"
  #     :filename => filename ex. 'index.html'
  #
  # Author: Thomas Flemming, thomasfl(at)usit.uio.no 2010
  #
  class Person

    attr_accessor :user, :html, :url, :publishedDate, :language, :scientific, :administrative, :image, :filename

    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}

      if(not(@user))then
        raise Exception.new("missing mandatory parameter :user")
      end
      if(not(@image))then
        raise Exception.new("missing mandatory parameter :image ")
      end

      # Set defaults
      if(@language == nil)then
        @language = :norwegian
      end

      if(@scientific == nil)then
        @scientific = false
      end

      if(@administrative == nil and not(@scientific))then
        @administrative = true
      end

    end

    def url
      if(@url)
        return @url
      else
        if(@filename)
          return @filename
        else
          return @user + ".html"
        end
      end
    end

    def content
      image_path = @image
      image_path = image_path.sub(/^https?:\/\/[^\/]*/i,'')
      image_path = File.basename(image_path)

      if(@html)then
        html = @html
      else
        if(@scientific)then
          html_template = :scientific
        else
          html_template = :administrative
        end
        html = create_html(:html_template => html_template, :language => @language)
      end

    json = <<EOF
{
   "resourcetype": "person",
   "properties":    {
      "getExternalPersonInfo": "true",
      "picture": "#{image_path}",
      "content": "#{html}",
      "getExternalScientificInformation": "#{@scientific}",
      "username": "#{@user}",
      "getRelatedGroups": "true",
      "getRelatedProjects": "true"
   }
}
EOF
      return json
    end


    def properties
      properties = '<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>' +
              '<d:getcontenttype>application/json</d:getcontenttype>' +
              '<v:resourceType xmlns:v="vrtx">person</v:resourceType>'

      if(@publishedDate and @publishedDate != "")
        if(@publishedDate.kind_of? Time)
          @publishedDate = @publishedDate.httpdate.to_s
        end
        props += '<v:published-date xmlns:v="vrtx">' + @publishedDate + '</v:published-date>'
      else
        time = Time.now.httpdate.to_s
        properties += '<v:publish-date xmlns:v="vrtx">' + time + '</v:publish-date>'
      end

      if(language == :english) then
        properties += '<v:contentLocale xmlns:v="vrtx">en</v:contentLocale>'
      else
        properties += '<v:contentLocale xmlns:v="vrtx">no_NO</v:contentLocale>'
      end
      return properties
    end

    # Generate html for person presentation. Defaults to presentation
    # for administrative employees in norwegian
    #
    # Examples:
    #
    #    create_html()
    #    create_html(:language => :english, :html_template => :scientific)
    #    create_html(:language => :norwegian, :html_template => :administrative)
    #
    def create_html(options)
      if(options[:html_template] && options[:html_template] == :scientific) then

        if(options[:language] && options[:language] == :english) then
          html = '<h2>Academic Interests<\/h2>\r\n' +
            '<p>Add information about academic fields of interest.<\/p>\r\n' +
            '<h2>Teaching<\/h2>\r\n' +
            '<ul>\r\n' +
            '    <li>&lt;Link to programme of study/course&gt;<\/li>\r\n' +
            '    <li>&lt;Link to programme of study/course&gt;<\/li>\r\n' +
            '    <li>...<\/li>\r\n' +
            '<\/ul>\r\n' +
            '<h2>Higher education and employment history<\/h2>\r\n' +
            '<p>Brief introduction to previous education and employment.<\/p>\r\n' +
            '<h2>Honoraria<\/h2>\r\n' +
            '<ul>\r\n' +
            '    <li>&lt;Name of prize and (if applicable) link 1&gt;<\/li>\r\n' +
            '    <li>&lt;Name of prize and (if applicable) link 2&gt;<\/li>\r\n' +
            '    <li>...<\/li>\r\n' +
            '<\/ul>\r\n' +
            '<h2>Appointments<\/h2>\r\n' +
            '<ul>\r\n' +
            '    <li>&lt;Title and (if applicable) link 1&gt;<\/li>\r\n' +
            '    <li>&lt;Title and (if applicable) link 2&gt;<\/li>\r\n' +
            '    <li>...<\/li>\r\n' +
            '<\/ul>\r\n' +
            '<h2>Cooperation<\/h2>\r\n' +
            '<p>&nbsp;<\/p>'
        else
          html = '<h2>Faglige interesser<\/h2>\r\n' +
            '<p>Her kan du skrive om faglige interesser.<\/p>\r\n' +
            '<h2>Undervisning<\/h2>\r\n<p>' +
            '&lt;Lenke til studieprogram/emne&gt; <br />\r\n' +
            '&lt;Lenke til studieprogram/emne&gt; <br />\r\n...<\/p>\r\n' +
            '<h2>Bakgrunn<\/h2>\r\n' +
            '<p>Kort om tidligere arbeidserfaring og utdanning<\/p>\r\n' +
            '<h2>Priser<\/h2>\r\n' +
            '<p>&lt;Navn og eventuelt lenke til pris 1&gt; <br />\r\n'  +
            '&lt;Navn og eventuelt lenke til pris 2&gt; <br />\r\n' +
            '...<\/p>\r\n' +
            '<h2>Verv<\/h2>\r\n<p>' +
            '&lt;Navn og eventuelt lenke til verv 1&gt; <br />\r\n' +
            '&lt;Navn og eventuelt lenke til verv 2&gt; <br />\r\n...' +
            '<\/p>\r\n' +
            '<h2>Samarbeid<\/h2>\r\n' +
            '<p>&nbsp;<\/p>'
        end
      else

        if(options[:language] && options[:language] == :english) then
          html = '<h2>Tasks performed<\/h2>\r\n' +
            '<p>Add information about job duties, as a short text or a bulleted list:<\/p>' +
            '\r\n<ul>\r\n' +
            '  <li>&lt;Task 1&gt;<\/li>\r\n' +
            '  <li>&lt;Task 1&gt;<\/li>\r\n' +
            '  <li>...<\/li>\r\n' +
            '<\/ul>\r\n' +
            '<h2>Background<\/h2>\r\n' +
            '<p>Add information about previous education and employment.<\/p>'
        else
          html = '<h2>Arbeidsomr&aring;der<\/h2>\r\n' +
            '<p>Her kan du skrive om arbeidsomr&aring;der, ' +
            'enten som kort tekst eller som listepunkter:</p>' +
            '\r\n' +
            '<ul>\r\n' +
            '    <li>&lt;Arbeidsomr&aring;de 1&gt;</li>\r\n' +
            '    <li>&lt;Arbeidsomr&aring;de 1&gt;</li>\r\n' +
            '    <li>...</li>\r\n' +
            '</ul>' +
            '\r\n' +
            '<h2>Bakgrunn</h2>\r\n' +
            '<p>Eventuelt kort om tidligere arbeidserfaring og utdanning.</p>'
        end
      end
      return html
    end


    def to_s
      "#<Vortex::Person "+instance_variables.collect{|var|var+": "+instance_variable_get(var).to_s}.join(",")+">"
    end


  end

end
