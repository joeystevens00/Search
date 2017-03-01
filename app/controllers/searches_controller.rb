class SearchesController < ApplicationController
    def show
      if not params[:search].nil?
        data = params[:search]["search"]
        @results = Search.new(data).search
        p @results
      end
    end
end

