#!/bin/bash
export HOME=$VALHEIM_HOME
steamcmd +force_install_dir $VALHEIM_HOME +login anonymous +app_update $VALHEIM_SERVER_APPID +quit