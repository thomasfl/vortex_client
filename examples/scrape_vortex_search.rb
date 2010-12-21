require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'pp'
require 'uri'

# Search a vortex host for a query string by scraping search results
# Regexp filter for url's is optional.
#
# Usage:
#
#   result = vortex_search("www.hf.uio.no", "Ansettelsesforhold ved UiO")
#   => ["http://www.hf.uio.no/ifikk/for-ansatte/ansettelsesforhold/index.html",
#        "http://www.hf.uio.no/imv/for-ansatte/ansettelsesforhold/",
#        "http://www.hf.uio.no/iln/for-ansatte/ansettelsesforhold/"]
def vortex_search(host, query)
  uri = URI.parse(host)
  if(uri.host)then
    host = uri.host
  end
  q = CGI::escape(query)
  search_results = {}
  prev_page = nil
  current_page = ""
  i = 1
  # Manage paging of search results
  while(prev_page != current_page)do
    prev_page = current_page
    url = "http://#{host}/?vrtx=search&page=#{i}&query=#{q}"
    doc = Nokogiri::HTML(open(url))
    doc.css('span.url').each do |link|
      search_results[link.content] = true
    end
    current_page = doc.to_s
    i = i + 1
  end

  result = []
  search_results.keys.each do |link|
    result << link
  end
end

