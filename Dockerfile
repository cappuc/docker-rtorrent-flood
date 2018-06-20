FROM arm64v8/alpine:3.7

ARG RTORRENT_VER=0.9.7
ARG LIBTORRENT_VER=0.13.7
ARG MEDIAINFO_VER=18.05
ARG FLOOD_VER=master
ARG BUILD_CORES

ENV UID=991 GID=991 \
    FLOOD_SECRET=supersecret \
    WEBROOT=/ \
    RTORRENT_SCGI=0 \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \
    && apk -U upgrade \
    && apk add -t build-dependencies \
    build-base \
    git \
    libtool \
    automake \
    autoconf \
    wget \
    tar \
    xz \
    zlib-dev \
    cppunit-dev \
    libressl-dev \
    ncurses-dev \
    curl-dev \
    binutils \
    linux-headers \
    && apk add \
    ca-certificates \
    curl \
    ncurses \
    libressl \
    gzip \
    zip \
    zlib \
    s6 \
    su-exec \
    python \
    nodejs \
    nodejs-npm \
    unrar \
    findutils 

RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \
    && wget -O /tmp/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' \
    && wget -O /tmp/config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' \
    && cd /tmp && mkdir libtorrent rtorrent \
    && cd libtorrent && wget -qO- https://github.com/rakshasa/libtorrent/archive/v${LIBTORRENT_VER}.tar.gz | tar xz --strip 1 \
    && cd ../rtorrent && wget -qO- https://github.com/rakshasa/rtorrent/releases/download/v${RTORRENT_VER}/rtorrent-${RTORRENT_VER}.tar.gz | tar xz --strip 1 \
    && cd /tmp \
    && git clone https://github.com/mirror/xmlrpc-c.git \
    && git clone https://github.com/Rudde/mktorrent.git \
    && cd /tmp/mktorrent && make -j ${NB_CORES} && make install \
    && ls -l /tmp/xmlrpc-c/stable ./ 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/xmlrpc-c/stable && cp /tmp/config.guess config.guess && cp /tmp/config.sub config.sub  && ./configure && make -j ${NB_CORES} && make install 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/libtorrent && ./autogen.sh && ./configure && make -j ${NB_CORES} && make install 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/rtorrent && ./autogen.sh && ./configure --with-xmlrpc-c && make -j ${NB_CORES} && make install 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp \
    && wget -q http://mediaarea.net/download/binary/mediainfo/${MEDIAINFO_VER}/MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
    && wget -q http://mediaarea.net/download/binary/libmediainfo0/${MEDIAINFO_VER}/MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
    && tar xzf MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
    && tar xzf MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.gz 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/MediaInfo_DLL_GNU_FromSource && ./SO_Compile.sh 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/MediaInfo_DLL_GNU_FromSource/ZenLib/Project/GNU/Library && make install 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library && make install 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/MediaInfo_CLI_GNU_FromSource && ./CLI_Compile.sh 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && cd /tmp/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI && make install 
RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \ 
    && strip -s /usr/local/bin/rtorrent \
    && strip -s /usr/local/bin/mktorrent \
    && strip -s /usr/local/bin/mediainfo \
    && ln -sf /usr/local/bin/mediainfo /usr/bin/mediainfo \
    && mkdir /usr/flood && cd /usr/flood && wget -qO- https://github.com/jfurrow/flood/archive/${FLOOD_VER}.tar.gz | tar xz --strip 1 \
    && npm install && npm cache clean --force 
RUN cd / \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && find -name '/tmp/*' -delete

COPY rootfs /

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/* \
    && cd /usr/flood/ && npm run build

VOLUME /data /flood-db

EXPOSE 3000 49184 49184/udp

LABEL description="BitTorrent client with WebUI front-end" \
    rtorrent="rTorrent BiTorrent client v$RTORRENT_VER" \
    libtorrent="libtorrent v$LIBTORRENT_VER" \
    maintainer="Wonderfall <wonderfall@targaryen.house>"

CMD ["run.sh"]
