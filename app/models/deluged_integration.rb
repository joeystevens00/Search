require 'deluge'
class DelugedIntegration
  def initialize(torrent)
    @torrent = torrent
    @response = {:response => 'No Content'}
  end

  def add_torrent
    begin
      deluge = Deluge::Rpc::Client.new(host: ENV["DELUGED_HOST"],
                                     port: ENV["DELUGED_PORT"],
                                     login: ENV["DELUGED_USERNAME"],
                                     password: ENV["DELUGED_PASSWORD"])
     deluge.connect
     if @torrent.slice(0,6) == "magnet"
       resp = deluge.core.add_torrent_magnet(@torrent, "")
     else
       resp = deluge.core.add_torrent_url(@torrent, "")
     end
      resp.nil? ? response_str="Error: Likely a duplicate request" : response_str=resp
        rescue => explode
      @response=explode # Just throw any ol' error in explode
    end
    @response[:response]=response_str
    @response.to_json
  end
end
