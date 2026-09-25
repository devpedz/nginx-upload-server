FROM nginx:1.29.1-alpine AS builder

RUN apk add --no-cache \
    build-base \
    linux-headers \
    pcre2-dev \
    zlib-dev \
    openssl-dev \
    wget \
    tar \
    git

WORKDIR /build

RUN wget -q \
    https://nginx.org/download/nginx-1.29.1.tar.gz \
    && tar -xzf nginx-1.29.1.tar.gz

RUN git clone \
    --depth 1 \
    https://github.com/arut/nginx-dav-ext-module.git \
    /build/nginx-dav-ext-module

WORKDIR /build/nginx-1.29.1

RUN ./configure \
    --with-compat \
    --add-dynamic-module=/build/nginx-dav-ext-module \
    && make modules


FROM nginx:1.29.1-alpine

RUN mkdir -p \
    /data/uploads \
    /tmp/nginx_upload

COPY --from=builder \
    /build/nginx-1.29.1/objs/ngx_http_dav_ext_module.so \
    /usr/lib/nginx/modules/ngx_http_dav_ext_module.so

COPY nginx/nginx.conf.template \
    /etc/nginx/templates/default.conf.template

EXPOSE 80