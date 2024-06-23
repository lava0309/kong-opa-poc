FROM kong

WORKDIR /usr/kong/opa

# copy the plugin sources
COPY . .

# switch to root to install rocks in /usr/local
USER root
RUN cp /etc/kong/kong.conf.default /etc/kong/kong.conf

# install dependencies
RUN apk update && \
  apk add gcc libc-dev git musl-dev curl && \
  luarocks install lua-cjson && \
  luarocks install lua-resty-http && \
  luarocks install lua-resty-jwt && \
  luarocks install luasocket && \
  luarocks install mobdebug

# build and install the plugin
RUN luarocks make

# back to kong user
USER kong
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
