require 'nokogiri'
require 'open-uri'
require 'socksify/http'

class Search
  TPB_URL="https://thepiratebay.org"
  EXTRA_TORRENT_URL="http://extratorrent.cc"
  KICKASS_TORRENTS_URL="http://kickasstorrents.to"
  EZTV_URL="https://eztv.ag"
  BITSNOOP_URL="https://bitsnoop.com"
  YTS_URL="https://yts.ag"

  def initialize(query)
    @query = query
    @search = {}
  end
  def bytes_to_biggest_unit(size)
    if size % 1000000000000 < size
      converted_size = size.to_f / 1000000000000.00
      conversion = "TB"
    elsif size % 1000000000 < size
      converted_size = size.to_f / 1000000000.00
      conversion = "GB"
    elsif size % 1000000 < size
      converted_size = size.to_f / 1000000.00
      conversion = "MB"
    elsif size % 1000 < size
      converted_size = size.to_f	 / 1000.00
      conversion = "KB"
    else
      return "Invalid entry"
    end
    "#{converted_size} #{conversion}"
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
        detail_page="#{EZTV_URL}#{detail_page}"
        if not torrent.css("a.magnet").to_s.empty?
          magnet=torrent.css("a.magnet").attribute("href").text
        elsif not torrent.css("a.download_2").to_s.empty?
          magnet=torrent.css("a.download_2").attribute("href").text
        elsif not torrent.css("a.download_1").to_s.empty?
          magnet=torrent.css("a.download_1").attribute("href").text
        else
          return false
        end
        size=torrent.text.split("\n").grep(/^([0-9]+\.[0-9]|[0-9])+ ([A-Z]|[a-z]){2,3}$/)[0]
        seeders=torrent.text.split("\n").grep(/^[0-9]+$/)[0]
        leechers=""
        resp.store(name, [rank, magnet, detail_page, seeders, leechers, size])
        rank+=1
      end
      resp
    rescue => explode
      p "ERROR: #{explode}" # Just throw any ol' error in explode
      false
  end

  def parse_name_from_rss(item_enum)
    # Pass a Nokogiri element that represents a torrent and this will try to identify a title by trying several things
    if not item_enum.css("title").text.empty?
      title=item_enum.css("title").text
    elsif not item_enum.css("description").css("img").none? # This happens on YTS
      title=item_enum.css("description").css("img").attribute("alt").text
    else         # If we still don't have a title then we'll just parse one out of the URL.. this happens on ExtraTorrent
      title=URI.decode(item_enum.css("enclosure")
                          .attribute("url")
                          .text.split("/")
                          .last.gsub(".torrent", "")
                          .gsub("+", " "))
    end
    title
  end

  def parse_size_from_rss(item_enum)
    # Pass a Nokogiri element that represents a torrent and this will try to identify the size by trying several things
    if not item_enum.text.match(/Size: [0-9]+\.[0-9]+ [A-Z][A-Z]/).to_s.sub("Size: ", "").empty? # YTS
      size=item_enum.text.match(/Size: [0-9]+\.[0-9]+ [A-Z][A-Z]/).to_s.sub("Size: ", "")
    else
      size=item_enum.css("enclosure").attribute("length").text # Most everything else
    end
    if size.match(/^[0-9]+$/) # If size is in bytes
      size=bytes_to_biggest_unit(size.to_i)
    end
    size
  end

  def parse_rss(searchurl, baseurl, baseurl_included_in_detail_page_links)
    # Parses RSS feeds and returns a response object
    # searchurl = the full URL to the search results
    # baseurl = the CONSTANT url of the site
    # baseurl_included_in_detail_page_links = true/false depending on if the detail_page links
    #                                         on the page are relative or absolute
    resp = {}
    rank = 0
    rss_torrents=getUrl(searchurl)
    if rss_torrents
      rss_torrents.xpath("//item").each do |item|
        seeders=item.css("seeders").text.to_i # Converting to int should make it 0 if no data is found (empty string)
        leechers=item.css("leechers").text.to_i
        magnet=item.css("enclosure").attribute("url").text
        size=parse_size_from_rss(item)
        detail_page=item.css("guid").text
        detail_page="#{baseurl}#{detail_page}" if baseurl_included_in_detail_page_links
        name=parse_name_from_rss(item)
        resp.store(name, [rank, magnet, detail_page, seeders, leechers, size])
        rank+=1
      end
      resp
    else
      false
    end
  end

  def kickass_torrents
    # Deprecated by generic parse_rss
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
    # Response Object: { torret_name => torrent_attributes
    response_object_kat = parse_rss("#{KICKASS_TORRENTS_URL}/usearch/#{@query}/?rss=1", KICKASS_TORRENTS_URL, true)
    # https://bitsnoop.com/search/all/test/?fmt=rss
    response_object_bitsnoop = parse_rss("#{BITSNOOP_URL}/search/all/#{@query}/?fmt=rss", BITSNOOP_URL, false)
    # http://extratorrent.cc/rss.xml?type=search&search=test
    response_object_extratorrent = parse_rss("#{EXTRA_TORRENT_URL}/rss.xml?type=search&search=#{@query}", EXTRA_TORRENT_URL, false)
    # https://yts.ag/rss/test/all/all/0
    response_object_yts = parse_rss("#{YTS_URL}/rss/#{@query}/all/all/0", YTS_URL, false)
    response_object_tpb = tpb
    response_object_eztv = eztv
    @search.store("TPB", response_object_tpb) if response_object_tpb
    @search.store("KickAss Torrents", response_object_kat) if response_object_kat
    @search.store("EZTV", response_object_eztv) if response_object_eztv
    @search.store("Bitsnoop", response_object_bitsnoop) if response_object_bitsnoop
    @search.store("Extra Torrent", response_object_extratorrent) if response_object_extratorrent
    @search.store("YTS", response_object_yts) if response_object_yts
    @search
  end
end

