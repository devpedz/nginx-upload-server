FROM nginx:alpine

RUN apk add --no-cache nginx-mod-http-dav-ext \
    && mkdir -p /data/uploads \
    && mkdir -p /tmp/nginx_upload \
    && chmod 755 /data/uploads \
    && chmod 755 /tmp/nginx_upload

COPY nginx/nginx.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80