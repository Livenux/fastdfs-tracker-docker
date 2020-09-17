FROM debian as build
WORKDIR /src
ARG FASTDFS_VERSION=6.06 
ARG LIBFASTCOMMON=1.0.43

RUN sed -i 's/deb.debian.org/mirrors.cloud.tencent.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.cloud.tencent.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y gcc make wget && \
    wget -c https://github.com/happyfish100/fastdfs/archive/V${FASTDFS_VERSION}.tar.gz  -O - | tar -xz && \
    wget -c https://github.com/happyfish100/libfastcommon/archive/V${LIBFASTCOMMON}.tar.gz  -O - | tar -xz && \
    cd libfastcommon-${LIBFASTCOMMON} && sh make.sh && sh  make.sh install && \
    cd ../fastdfs-${FASTDFS_VERSION} && sh make.sh 


FROM debian

ENV  TZ='Asia/Shanghai'

COPY --from=build /src /src

ARG FASTDFS_VERSION=6.06 
ARG LIBFASTCOMMON=1.0.43

ENV TRACKER_SERVER='tracker_server = tracker0:22122\ntracker_server = tracker1:22122' \
    HTTP_DOMAIN='web'
    
WORKDIR /home/fdfs

RUN set -x \
    echo $TZ > /etc/timezone && \
    sed -i 's/deb.debian.org/mirrors.cloud.tencent.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.cloud.tencent.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y tzdata make  util-linux && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata  && \
    useradd -d /home/fdfs -s /bin/bash fdfs && \
    cd /src/libfastcommon-${LIBFASTCOMMON} && sh make.sh install && \
    cd /src/fastdfs-${FASTDFS_VERSION} && sh make.sh install && \
    mkdir -p /var/fdfs/store0 && \
    chown fdfs /etc/fdfs -R && chown fdfs /var/fdfs -R && \
    rm -rf /var/lib/apt/lists/* /src /etc/fdfs/*.simple

EXPOSE 22122    
COPY conf /etc/fdfs    
ADD startup.sh /home/fdfs/

HEALTHCHECK --interval=60s --timeout=5s --retries=3 \
    CMD fdfs_monitor /etc/fdfs/client.conf  || exit 1

ENTRYPOINT ["sh", "/home/fdfs/startup.sh"] 


