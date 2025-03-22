#!/bin/bash
export HOME=$LSDC2_HOME
valheim_server_appid=896660
steamcmd +force_install_dir $LSDC2_HOME +login anonymous +app_update $valheim_server_appid +quit