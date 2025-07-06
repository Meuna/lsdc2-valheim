#!/bin/bash
export HOME=$LSDC2_HOME
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

./update-server.sh

# Init the adminlist.txt file if $ADMIN_PLATFORMID is provided
if [ -n "$ADMIN_PLATFORMID" ]; then
    # Create the serveradmin.xml is it does not exists
    admin_file=$GAME_SAVEDIR/adminlist.txt
    if [ ! -f $admin_file ]; then
        mkdir -p $GAME_SAVEDIR
    fi
    if ! grep -Fxq "$ADMIN_PLATFORMID" "$admin_file"; then
        echo "$ADMIN_PLATFORMID" >> "$admin_file"
    fi
fi

SERVER_PASS=${SERVER_PASS:-password}

server_name="Le serveur des copains"
server_public=0

shutdown() {
    kill -INT $pid
}

trap shutdown SIGINT SIGTERM

./valheim_server.x86_64 -nographics -batchmode -savedir "$GAME_SAVEDIR" -name "$server_name" -port "$GAME_PORT" -world "$GAME_SAVENAME" -public "$server_public" -password "$SERVER_PASS" &
pid=$!
wait $pid
