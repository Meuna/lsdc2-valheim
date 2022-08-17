from steamcmd/steamcmd:ubuntu

ENV VALHEIM_SERVER_APPID=896660 \
    VALHEIM_APPID=892970 \
    VALHEIM_HOME=/valheim/

ENV SAVEDIR=$VALHEIM_HOME/savedir \
    WORLD_NAME=lsdc2 \
    SERVER_NAME="Le serveur des copains" \
    SERVER_PORT=2456 \
    SERVER_PASS=valheim \
    SERVER_PUBLIC=0

ENV LSDC2_SNIFF_IFACE="eth0" \
    LSDC2_SNIFF_FILTER="udp port $SERVER_PORT" \
    LSDC2_CWD=$VALHEIM_HOME \
    LSDC2_UID=1000 \
    LSDC2_GID=1000 \
    LSDC2_PERSIST_FILES="$WORLD_NAME.db;$WORLD_NAME.fwl" \
    LSDC2_ZIP=1 \
    LSDC2_ZIPFROM=$SAVEDIR/worlds_local

WORKDIR $VALHEIM_HOME

ADD https://github.com/Meuna/lsdc2-serverwrap/releases/download/v0.1.0/serverwrap /serverwrap

COPY start-server.sh update-server.sh $VALHEIM_HOME
RUN groupadd -g $LSDC2_GID -o valheim \
    && useradd -g $LSDC2_GID -u $LSDC2_UID -d $VALHEIM_HOME -o --no-create-home valheim \
    && chmod u+x /serverwrap update-server.sh start-server.sh \
    && chown -R valheim:valheim $VALHEIM_HOME \
    && su valheim ./update-server.sh \
    && rm -rf /root/.steam

EXPOSE 2456-2457/udp
ENTRYPOINT ["/serverwrap"]
CMD ["./start-server.sh"]
