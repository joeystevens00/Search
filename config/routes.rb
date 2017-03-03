Rails.application.routes.draw do
  root 'searches#show'
  post '/api/new_torrent', to: 'deluged_integration#new'
  resource :searches
end
