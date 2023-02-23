#!/bin/sh

# Start and wait ngrok config
ngrok http 80 >/dev/null &
until $(curl --output /dev/null --silent --head --fail http://localhost:4045); do
    echo 'waiting...'
    sleep 5
done
echo 'ngrok init'

# Get public URL
URL=$(curl -sS http://localhost:4045/api/tunnels | jq -r '.tunnels[0].public_url')
echo $URL

# Waiting changes from remote repository
cd /var/www/html
while :
do
	git remote update >/dev/null & 
	
	LOCAL=$(git rev-parse @)
	REMOTE=$(git rev-parse origin/master)
	BASE=$(git merge-base @ origin/master)
	
	if ([ $LOCAL != $REMOTE ] && [ $LOCAL = $BASE ]); # has diff from remote  
	then
	    git pull origin master >/dev/null &
	    sudo systemctl reload nginx
	    echo "Changes in: ${URL}" 
	fi
	sleep 5
done
