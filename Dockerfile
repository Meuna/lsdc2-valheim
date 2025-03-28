FROM docker.io/steamcmd/steamcmd:ubuntu

ENV LSDC2_USER=lsdc2 \
    LSDC2_HOME=/lsdc2 \
    LSDC2_UID=2000 \
    LSDC2_GID=2000

WORKDIR $LSDC2_HOME

COPY update-server.sh $LSDC2_HOME
RUN groupadd -g $LSDC2_GID -o $LSDC2_USER \
    && useradd -g $LSDC2_GID -u $LSDC2_UID -d $LSDC2_HOME -o --no-create-home $LSDC2_USER \
    && chown -R $LSDC2_USER:$LSDC2_USER $LSDC2_HOME \
    && chmod u+x update-server.sh \
    && su $LSDC2_USER ./update-server.sh \
    && rm -rf /root/.steam

ADD https://github.com/Meuna/lsdc2-serverwrap/releases/download/v0.4.2/serverwrap /usr/local/bin
COPY start-server.sh $LSDC2_HOME
RUN chown $LSDC2_USER:$LSDC2_USER start-server.sh \
    && chmod +x /usr/local/bin/serverwrap start-server.sh

ENV GAME_SAVEDIR=$LSDC2_HOME/savedir \
    GAME_SAVENAME=lsdc2 \
    GAME_PORT=2456

ENV LSDC2_SNIFF_IFACE="eth0" \
    LSDC2_SNIFF_FILTER="udp port $GAME_PORT" \
    LSDC2_PERSIST_FILES="$GAME_SAVENAME.db;$GAME_SAVENAME.fwl" \
    LSDC2_ZIPFROM=$GAME_SAVEDIR/worlds_local

ENTRYPOINT ["serverwrap"]
CMD ["./start-server.sh"]
