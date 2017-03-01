require 'nokogiri'
require 'open-uri'
class Search
  TPB_URL="https://thepiratebay.org"

  def initialize(query)
    @query = query
    @search = {}
  end

  def tpb
    # Returns a hash containing name => [name, url, detail_page]
    resp = {}
    rank = 0
    begin
      tpb_resp = Nokogiri::HTML(open("#{TPB_URL}/search/#{@query}"))
      # Iterate through every row in the search result table except the header row (always first)
      tpb_resp.css("tr:not(:first-child)").each do |link|
        # Get Size
        size= link.css(".detDesc").text.match("[0-9]+\\.[0-9]+.*,").to_s.sub(",","")
        # Get seeders
        seeders = link.css("td[align=right]")[0].text
        # Get leachers
        leechers = link.css("td[align=right]")[1].text
        # Get the magnet link URL using the title tag
        magnet = link.css("a[title='Download this torrent using magnet']").attribute("href").text
        # Grab the title of the torrent
        name= link.css("a.detLink").text
        # Grab the link to the detail page
        detail_page = link.css('.detLink').attribute('href').text
        detail_page="#{TPB_URL}#{detail_page}"
        resp.store(name, [rank, magnet, detail_page, seeders, leechers, size])
        rank+=1
      end
      resp
    rescue => explode
      "ERROR: #{explode}" # Just throw any ol' error in explode
    end
  end

  def search
    # Contains the search object which contains the response objects
    # Search object: { source => response_object }
    # Response Object: { torret_name => torrent_attributes }
    response_object_tpb = tpb
    @search.store("TPB", tpb)
    @search
  end
end

