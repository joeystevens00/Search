require 'nokogiri'
require 'open-uri'
require 'socksify/http'

class Search
  TPB_URL="https://thepiratebay.org"
  EXTRA_TORRENT_URL="http://extratorrent.cc"
  KICKASS_TORRENTS_URL="http://kickasstorrents.to"
  EZTV_URL="https://eztv.ag"

  def initialize(query)
    @query = query
    @search = {}
  end

  def getUrl(url)
    # Expects a url and returns a Nokogiri::HTML object
    begin
      if ENV["SEARCHER_PROXY_HOST"].nil?
       html=Nokogiri::HTML(open(url))
      else
        if ENV['SEARCHER_PROXY_TYPE'] == 'socks'
         http = Net::HTTP::SOCKSProxy(ENV['SEARCHER_PROXY_HOST'], ENV['SEARCHER_PROXY_PORT'])
          html = http.get(URI(url))
         html = Nokogiri::HTML(html)
        elsif ENV['SEARCHER_PROXY_TYPE'] == 'http'
         Nokogiri::HTML(open(url), :proxy => "#{ENV['SEARCHER_PROXY_HOST']}:#{ENV['SEARCHER_PROXY_PORT']}")
        else
         return 'FATAL: INVALID PROXY TYPE. CANNOT RISK CONTINUING'
       end
      end
      html
    rescue
      false
    end
  end

  def eztv
      resp = {}
      rank = 0
      eztv_torrents=getUrl("#{EZTV_URL}/search/#{@query}")
      eztv_torrents.css("tr.forum_header_border").each do |torrent|
        name=torrent.css("a.epinfo").text
        detail_page=torrent.css(".epinfo").attribute("href").text
        detail_page="#{EZTV_URL}#{detail_page}}"
        if not torrent.css("a.magnet").to_s.empty?
          magnet=torrent.css("a.magnet").attribute("href").text
        elsif not torrent.css("a.download_2").to_s.empty?
          magnet=torrent.css("a.download_2").attribute("href").text
        elsif not torrent.css("a.download_1").to_s.empty?
          magnet=torrent.css("a.download_1").attribute("href").text
        else
          return false
        end
        size=torrent.text.split("\n").grep(/^[0-9].*/)[0]
        seeders=torrent.text.split("\n").grep(/^[0-9]+$/)[0]
        seeders
        leechers=""
        resp.store(name, [rank, magnet, detail_page, seeders, leechers, size])
        rank+=1
      end
      resp
    rescue => explode
      p "ERROR: #{explode}" # Just throw any ol' error in explode
      false
    end

  def kickass_torrents
    resp = {}
    rank = 0
    ka_torr=getUrl("#{KICKASS_TORRENTS_URL}/usearch/#{@query}/?rss=1")
    if ka_torr
      ka_torr.xpath("//item").each do |item|
       seeders=""
       leechers=""
       magnet=item.css("enclosure").attribute("url").text
       size=item.css("enclosure").attribute("length").text
       detail_page=item.css("guid").text
       detail_page="#{KICKASS_TORRENTS_URL}#{detail_page}"
       name=item.css("title").text
       resp.store(name, [rank, magnet, detail_page, seeders, leechers, size])
       rank+=1
      end
      resp
    else
      false
    end
  end

  def tpb
    # Returns a hash containing name => [name, url, detail_page]
    resp = {}
    rank = 0

    begin
      tpb_resp = getUrl("#{TPB_URL}/search/#{@query}")
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
    response_object_kat = kickass_torrents
    response_object_tpb = tpb
    response_object_eztv = eztv
    @search.store("TPB", response_object_tpb) if response_object_tpb
    @search.store("KickAss Torrents", response_object_kat) if response_object_kat
    @search.store("EZTV", response_object_eztv) if response_object_eztv
    @search
  end
end

