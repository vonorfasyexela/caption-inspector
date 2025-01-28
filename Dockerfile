# Обновил версию образа и исправил регистр слова AS.
# FROM debian:9-slim as base
FROM debian:stable-slim AS base

# install dependencies
RUN apt-get update && \
    apt-get install -y git mediainfo make curl gcc g++ clang nasm yasm \
    opencl-dev vim libass-dev uuid-dev zlib1g-dev 

# TODO: Попробовать обновить FFmpeg.
ENV FFMPEG_VERSION=4.0.2 LD_LIBRARY_PATH=/usr/local/lib

# build ffmpeg libraries    
RUN DIR=$(mktemp -d) && cd ${DIR} && \
    # Изначально здесь была ссылка на HTTP, но сейчас архивы доступны по HTTPS.
    # curl -s http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | \
    curl -s https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | \
    tar zxvf - -C . && \
    cd ffmpeg-${FFMPEG_VERSION} && \
    ./configure  --enable-version3 --enable-hardcoded-tables --enable-shared \
    --enable-static --enable-small --enable-libass --enable-postproc \
    --enable-avresample --enable-libfreetype --disable-lzma --enable-opencl \
    --enable-pthreads && \
    # Ускорение сборки.
    # make && \
    make -j$(nproc) && \
    make install && \
    make distclean && \
    rm -rf ${DIR}

# install git, make, and gcc to build gpac
COPY .git/ /app/.git/

# pull and build gpac
RUN git clone https://github.com/Comcast/gpac-caption-extractor.git && \
    cp -r /gpac-caption-extractor/include/gpac /usr/local/include && \
    cd gpac-caption-extractor && make gpac && cp libgpac.so /usr/local/lib

# build /app/caption-inspector executable
COPY src/ /app/src/
COPY include/ /app/include/
COPY Makefile /app/Makefile
WORKDIR /app
RUN mkdir obj && mkdir python; cd src && make ci_with_gpac

RUN ldd /usr/bin/mediainfo

#
# Runtime Container
#
# Обновил версию образа и исправил регистр слова AS.
# FROM debian:9-slim as slim
FROM debian:stable-slim AS slim

ENV FFMPEG_VERSION=4.0.2 LD_LIBRARY_PATH=/usr/local/lib

# TODO: Вот это не очень красиво. Приходится руками всё отслеживать.
# TODO: Можно сделать более кросс-платформенный вариант, если заменить x86_64 
# на константу, как это сделано в форке svlobanov.
COPY --from=base /app/caption-inspector /usr/local/bin/
# copy required libraries from base to the slim image
COPY --from=base /usr/local/lib/libavformat.so.* /usr/local/lib/
COPY --from=base /usr/local/lib/libavcodec.so.* /usr/local/lib/
COPY --from=base /usr/local/lib/libavutil.so.* /usr/local/lib/
COPY --from=base /usr/local/lib/libswresample.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libOpenCL.so.* /usr/local/lib/
COPY --from=base /usr/local/lib/libgpac.so /usr/local/lib/

# ensure all required libraries are installed
RUN if ldd /usr/local/bin/caption-inspector | grep "not found"; then false; fi

COPY --from=base /usr/bin/mediainfo /usr/local/bin/mediainfo
# copy required libraries from base to the slim image
COPY --from=base /usr/lib/x86_64-linux-gnu/libmediainfo.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libzen.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libmms.so.* /usr/local/lib/
COPY --from=base /lib/x86_64-linux-gnu/libglib-2.0.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libtinyxml2.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libnghttp2.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libidn2.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/librtmp.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libssh2.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libpsl.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libnettle.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgnutls.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libkrb5.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libk5crypto.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/liblber-2.4.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libldap_r-2.4.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libunistring.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libhogweed.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgmp.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libunistring.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libp11-kit.so.* /usr/local/lib/
COPY --from=base /lib/x86_64-linux-gnu/libidn.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libtasn1.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libhogweed.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgmp.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libkrb5support.so.* /usr/local/lib/
COPY --from=base /lib/x86_64-linux-gnu/libkeyutils.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libkrb5support.so.* /usr/local/lib/
COPY --from=base /lib/x86_64-linux-gnu/libkeyutils.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libkrb5support.so.* /usr/local/lib/
COPY --from=base /lib/x86_64-linux-gnu/libkeyutils.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libsasl2.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libffi.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libldap-2.5.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/liblber-2.5.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libbrotlidec.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libcrypto.so.* /usr/local/lib/
COPY --from=base /usr/lib/x86_64-linux-gnu/libbrotlicommon.so.* /usr/local/lib/

# ensure all required libraries are installed
RUN if ldd /usr/local/bin/mediainfo | grep "not found"; then false; fi

ENTRYPOINT ["/usr/local/bin/caption-inspector"]
