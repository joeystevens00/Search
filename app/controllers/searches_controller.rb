class SearchesController < ApplicationController
    def show
      if not params[:search].nil?
        data = URI.escape(params[:search]["search"])
        @results = Search.new(data).search
      end
    end
end

