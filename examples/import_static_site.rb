# -*- coding: utf-8 -*-
require 'rubygems'
require 'open-uri'
require 'vortex_client'
require 'uri'
require 'nokogiri'
require 'htmlentities'
require 'json'
require 'iconv'

class MigrateSuicidologi
  attr :vortex, :uri

  def initialize(url)
    @vortex = Vortex::Connection.new(url,:osx_keychain => true)
    @uri = URI.parse(url)
  end

  # Common regexp for title and introduction
  def clean_string(string)
    string = string.gsub(/\r|\n/,'').sub(/^ */,'').sub(/\s*$/,'').gsub(/ +/,' ')
    coder = HTMLEntities.new()
    string = coder.decode(string) # Remove html entities
    return string
  end

  # Return a list of all documents found, recursively.
  def crawler(url)
    result = []
    doc = Nokogiri::HTML.parse(open(url))
    row = doc.xpath("//tr[4]").first
    while(row)do
      row_doc = Nokogiri::HTML(row.to_s)
      link = row_doc.xpath("//a").first
      if(link)then
        href = url + link.attribute("href").value
        if(href =~ /\/$/)then
          result = result + crawler(href)
        else
          result << href
        end
      end
      row = row.next
    end
    return result
  end

  # Scrape an issue
  def scrape_periodical(url)
    html = open(url).read

    doc = Nokogiri::HTML.parse(html)

    # Detect encoding
    doc.encoding = 'iso-8859-1'

    if(doc.to_s =~ /æ|ø|å/)then
      puts "Encoding detected: iso-8859-1"
    else
      doc2 = Nokogiri::HTML.parse(html)
      doc2.encoding = 'utf-8'
      if(doc2.to_s =~ /æ|ø|å/)then  # This method only works for norwegian
        puts "Encoding detected: utf-8"
        doc = Nokogiri::HTML.parse(html)
        doc.encoding = 'utf-8'
      else
        puts "Encoding detected: unknown"
      end
    end

    issue = { }
    issue[:title] = clean_string( doc.css('.MenuHeading1').inner_text )
    issue[:title] =~ /,(.*)/
    folder_title = clean_string( $1 )
    folder_title = folder_title[0..0].upcase + folder_title[1..9999]
    issue[:folder_title] = folder_title
    issue[:introduction] = clean_string( doc.css('.MenuHeading2').inner_text )
    issue[:body] = clean_html(doc.xpath("//ul")).to_s

    url =~ /([^\/]*)-(.*)\..*$/
    issue[:year] = $1
    issue[:folder_name] = $2
    url =~ /([^\/|]*)\.html$/
    path = 'http://www.med.uio.no/ipsy/ssff/suicidologi/' + $1 + "/"
    issue[:files] = crawler(path)
    return issue
  end

  # Remove unwanted tags from body
  def clean_html(doc)

    # Remove font tags
    doc.xpath('//font').each do |node|
      node.children.each do |child|
        child.parent = node.parent
      end
      node.remove
    end

    # Remove path to links:
    doc.xpath('//a').each do |node|
      href = node.attr("href")
      href =~ /([^\/]*)$/
      node.set_attribute("href", $1)
    end

    # Remove <br> tags within li elements
    doc.xpath('//li').each do |li|
      li.xpath('//br').each do |br|
        br.remove
      end
    end

    # Remove <p> tags within li elements
    doc.xpath('//li').each do |li|
      li.xpath('//p').each do |p|
        p.children.each do |child|
          child.parent = p.parent
        end
        p.remove
      end
    end

    return doc
  end

  def create_folders(issue)
    puts "Creating folders?"
    year_folder = @uri.path + issue[:year]
    if(not(@vortex.exists?(year_folder)))then
      puts "  Creating folder #{year_folder}/"
      @vortex.mkdir(year_folder)
      @vortex.proppatch(year_folder, '<v:resourceType xmlns:v="vrtx">article-listing</v:resourceType>')
      @vortex.proppatch(year_folder, '<v:collection-type xmlns:v="vrtx">article-listing</v:collection-type>')
    end

    issue_folder = year_folder + "/" + issue[:folder_name]
    if(not(@vortex.exists?(issue_folder)))then
      puts "  Creating folder #{issue_folder}/"
      @vortex.mkdir(issue_folder)
      @vortex.proppatch(issue_folder, '<v:resourceType xmlns:v="vrtx">article-listing</v:resourceType>')
      @vortex.proppatch(issue_folder, '<v:collection-type xmlns:v="vrtx">article-listing</v:collection-type>')
      @vortex.proppatch(issue_folder, '<v:userTitle xmlns:v="vrtx">' + issue[:folder_title] + '</v:userTitle>')
    end

  end

  def copy_files(issue)
    puts "Copying pdf files."
    issue[:files].each do |url|
      url =~ /([^\/]*)$/
      basename = $1
      content = open(url).read
      path = @uri.path + issue[:year] + "/" + issue[:folder_name] + "/" + basename
      puts url + " => " + path
      @vortex.put_string(path,content)
    end
  end

  def publish_article(issue)
    puts "Publising article"
    pathname = @uri.path + issue[:year] + "/" + issue[:folder_name] + "/index.html"
    article  = Vortex::StructuredArticle.new(:title => issue[:title],
                           :introduction => issue[:introduction],
                           :body => issue[:body],
                           :url => pathname,
                           :publishedDate => Time.now ) #,
                           # :author => "Halvor Aarnes")
    path = @vortex.publish(article)
  end

  def migrate_issue(url)
    issue = scrape_periodical(url)
    debug = false
    if(debug)then
      puts "Year  : '#{issue[:year]}'"
      puts "folder: '#{issue[:folder_name]}' / '#{issue[:folder_title]}'"
      puts "Tittel: '#{issue[:title]}'"
      puts "Intro : '#{issue[:introduction]}'"
      puts "Body  : '#{issue[:body][0..110]}.."
    end
    # require 'pp'
    # pp issue[:files]
    # puts

    create_folders(issue)
    publish_article(issue)
    copy_files(issue)
  end

  def migrate_all_issues(url)
    files =crawler(url)
    files.each do |file|
      migrate_issue(file)
      puts file
    end
  end

end

# Scrape all webpages found in src_url and store in dest_url
dest_url = 'https://nyweb1-dav.uio.no/konv/ssff/suicidologi/'
src_url = 'http://www.med.uio.no/ipsy/ssff/suicidologi/innholdsfortegnelser/'
migration = MigrateSuicidologi.new(dest_url)
migration.migrate_all_issues(src_url)


# url = 'http://www.med.uio.no/ipsy/ssff/suicidologi/innholdsfortegnelser/2009-nr1.html'
# TODO
# - Sette publisert dato til år og ....?
# - Alle ingressene har tegnsettproblemer? Iconv?
