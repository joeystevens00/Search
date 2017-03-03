class DelugedIntegrationController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def new
    if not params[:torrent].nil?
      data = params[:torrent]
      @response = DelugedIntegration.new(data).add_torrent
      if @response
        render json: @response, status: :created
      else
        render json: @response.errors, status: :unprocessable_entity
      end
    end
  end
end