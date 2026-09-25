# ============================================================
# BUILD DAV MODULE
# ============================================================

FROM nginx:1.29.1-alpine AS builder

RUN apk add --no-cache \
    build-base \
    linux-headers \
    pcre2-dev \
    zlib-dev \
    openssl-dev \
    libxml2-dev \
    libxslt-dev \
    wget \
    tar \
    git

WORKDIR /build


# ============================================================
# DOWNLOAD EXACT NGINX SOURCE VERSION
# ============================================================

RUN wget -q \
    https://nginx.org/download/nginx-1.29.1.tar.gz \
    && tar -xzf nginx-1.29.1.tar.gz


# ============================================================
# DOWNLOAD DAV EXT MODULE
# ============================================================

RUN git clone \
    --depth 1 \
    https://github.com/arut/nginx-dav-ext-module.git \
    /build/nginx-dav-ext-module


# ============================================================
# BUILD MODULE
# ============================================================

WORKDIR /build/nginx-1.29.1

RUN ./configure \
    --with-compat \
    --add-dynamic-module=/build/nginx-dav-ext-module \
    && make modules


# ============================================================
# PRODUCTION RUNTIME
# ============================================================

FROM nginx:1.29.1-alpine

RUN mkdir -p \
    /data/uploads \
    /tmp/nginx_upload \
    /var/log/nginx \
    /run


# ============================================================
# COPY DAV MODULE
# ============================================================

COPY --from=builder \
    /build/nginx-1.29.1/objs/ngx_http_dav_ext_module.so \
    /usr/lib/nginx/modules/ngx_http_dav_ext_module.so


# ============================================================
# NGINX CONFIG
# ============================================================

COPY nginx/nginx.conf.template \
    /etc/nginx/templates/default.conf.template


# ============================================================
# PORT
# ============================================================

EXPOSE 80


# ============================================================
# START NGINX
# ============================================================

CMD ["nginx", "-g", "daemon off;"]