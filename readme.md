My first rails app

ENV variables   
```
export DELUGED_HOST="localhost"
export DELUGED_PORT="58846" # set to defualt deluged port 
export DELUGE_WEB_URL="http://localhost:3001/" # Default port is 8112 
export DELUGED_USERNAME="localclient" # cat ~/.config/deluge/auth | cut -d: -f1
export DELUGED_PASSWORD="password" # cat ~/.config/deluge/auth | cut -d: -f2 
export SEARCHER_PROXY_HOST="localhost"
export SEARCHER_PROXY_PORT="9050"
export SEARCHER_PROXY_TYPE="socks"
```