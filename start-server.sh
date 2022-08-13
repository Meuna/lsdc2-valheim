#!/bin/bash
export HOME=$VALHEIM_HOME
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=$VALHEIM_APPID

shutdown() {
    kill -INT $pid
}

./update-server.sh

trap shutdown SIGINT SIGTERM

./valheim_server.x86_64 -nographics -batchmode -savedir "$SAVEDIR" -name "$SERVER_NAME" -port "$SERVER_PORT" -world "$WORLD_NAME" -public "$SERVER_PUBLIC" -password "$SERVER_PASS" &
pid=$!
wait $pid
