docker-compose stop kong && docker-compose rm -f kong && cd kong-plugin-opa && docker build --no-cache -t kong-with-opa-v2 . && cd .. && docker-compose up -d kong && docker-compose logs -f kong  