# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'pry'
require "net/http"
require 'pathname'
require 'json'
require 'pp'

old_pages = { }
new_pages = { }
File.open('scrape_holocaust.log').each { |line|
  line = line.chop
  pages = line.split(/;/)
  old_pages[pages[0]] = pages[1]
  new_pages[pages[1]] = pages[0]
}

old_pages.each do |old_url, new_url|
  puts "Old URL :" + old_url
  puts "New URL :" + new_url

  doc = Nokogiri::HTML.parse(open(old_url))
  doc.encoding = 'utf-8'
  doc.css(".related .title").each do |related_title|
    puts related_title.text
    next_element = related_title.next_element
    while(next_element)
      href = next_element.css("a").attr("href")
      text = next_element.css("a").text
      puts " " + href
      puts " " + text

      puts
      # puts old_pages[href]
      puts
      next_element = next_element.next_element
    end
  end

  puts "----"
  # exit
end
