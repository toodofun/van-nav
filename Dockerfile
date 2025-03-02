FROM node:14-alpine AS feBuilder
WORKDIR /app
# RUN apk add --no-cache g++ gcc make python3
COPY . .
RUN yarn config set -g registry http://mirrors.cloud.tencent.com/npm/ && yarn config set -g sass_binary_site http://mirrors.cloud.tencent.com/npm/node-sass/
RUN cd /app && cd ui/admin && yarn && yarn build && cd ../..
RUN cd ui/website && yarn && yarn build && cd ../..
RUN cd /app && mkdir -p public/admin
RUN cp -r ui/website/build/* public/
RUN cp -r ui/admin/dist/* public/admin/
RUN sed -i 's/\/assets/\/admin\/assets/g' public/admin/index.html


FROM golang:alpine AS binarybuilder
RUN apk --no-cache --no-progress add  git
WORKDIR /app
COPY . .
COPY --from=feBuilder /app/public /app/public
RUN go env -w GOPROXY=https://goproxy.cn,direct && cd /app && ls -la && go mod tidy && go build .



FROM alpine:latest
ENV TZ="Asia/Shanghai"
RUN apk --no-cache --no-progress add \
    ca-certificates \
    tzdata && \
    cp "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" >  /etc/timezone
WORKDIR /app
COPY --from=binarybuilder /app/nav /app/

VOLUME ["/app/data"]
EXPOSE 6412
ENTRYPOINT [ "/app/nav" ]
