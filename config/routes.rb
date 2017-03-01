Rails.application.routes.draw do
  root 'searches#show'
  resource :searches
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
