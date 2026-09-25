FROM alpine:3.22 AS builder

ARG NGINX_VERSION=1.29.1
ARG DAV_EXT_VERSION=3.0.0

RUN apk add --no-cache \
    build-base \
    linux-headers \
    pcre2-dev \
    zlib-dev \
    openssl-dev \
    wget \
    tar \
    gzip \
    git

WORKDIR /build

RUN wget -q \
    https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzf nginx-${NGINX_VERSION}.tar.gz

RUN git clone \
    --depth 1 \
    --branch v${DAV_EXT_VERSION} \
    https://github.com/arut/nginx-dav-ext-module.git

WORKDIR /build/nginx-${NGINX_VERSION}

RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/run/nginx.pid \
    --lock-path=/run/lock/nginx.lock \
    --http-client-body-temp-path=/tmp/client_temp \
    --http-proxy-temp-path=/tmp/proxy_temp \
    --http-fastcgi-temp-path=/tmp/fastcgi_temp \
    --http-uwsgi-temp-path=/tmp/uwsgi_temp \
    --http-scgi-temp-path=/tmp/scgi_temp \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --add-module=/build/nginx-dav-ext-module \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install


FROM alpine:3.22

RUN apk add --no-cache \
    pcre2 \
    zlib \
    openssl

RUN mkdir -p \
    /data/uploads \
    /tmp/nginx_upload \
    /var/log/nginx \
    /var/cache/nginx \
    /run

COPY --from=builder \
    /usr/sbin/nginx \
    /usr/sbin/nginx

COPY --from=builder \
    /etc/nginx \
    /etc/nginx

COPY nginx/nginx.conf.template \
    /etc/nginx/templates/default.conf.template

EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]