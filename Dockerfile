FROM kong:latest

# Install necessary build tools and libraries
USER root
RUN apk add --no-cache git gcc libc-dev

# Copy the plugin code into the container
COPY kong-plugin-opa /usr/local/share/lua/5.1/kong/plugins/opa

# Change directory to the plugin folder
WORKDIR /usr/local/share/lua/5.1/kong/plugins/opa

# Build the plugin using luarocks make
RUN luarocks make

# Install the plugin
RUN luarocks install kong-plugin-opa
RUN luarocks install kong-plugin-jwt  # Install JWT plugin

# Change back to the kong user
USER kong