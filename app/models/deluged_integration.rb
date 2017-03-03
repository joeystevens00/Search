require 'deluge'
class DelugedIntegration
  def initialize(torrent)
    @torrent = torrent
    @response = {:response => 'No Content', :success => '1'}
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
      if resp.nil?
        response_str="Error: Likely a duplicate request"
        success_val=1
      else
        response_str=resp
        success_val=0
      end
        rescue => explode
      response_str=explode # Just throw any ol' error in explode
      success_val=1
    end
    @response[:response]=response_str
    @response[:success]=success_val
    @response.to_json
  end
end
