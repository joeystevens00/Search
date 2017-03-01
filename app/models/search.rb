require 'nokogiri'
require 'open-uri'
class Search
  TPB_URL="https://thepiratebay.org"

  def initialize(search)
    @search = search
  end

  def search
    # Returns a hash containing name => [name, url, detail_page]
    resp = {}
    begin
      tpb_resp = Nokogiri::HTML(open("#{TPB_URL}/search/#{@search}"))
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
        resp.store(name, [name, magnet, detail_page, seeders, leechers, size])
      end
      resp
    rescue => explode
      "ERROR: #{explode}" # Just throw any ol' error in explode
    end
  end
end

p Search.new("test").search