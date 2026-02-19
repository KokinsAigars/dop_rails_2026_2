
# Nuke Docker
    docker ps -aq | xargs -r docker rm -f
    docker image prune -af
    docker builder prune -af
    docker system prune -af
    docker network prune -f

    storage is untached?
        sudo du -sh /var/lib/docker/volumes/app_storage/_data || true

# Development
### docker-compose.dev.yml => .env => Dockerfile.dev => entrypoint.dev.sh

    docker compose -f docker-compose.dev.yml up --build

    PostgreSQL
        new server: host=localhost; port=5433; user && password from .env

    create database manually: dop_dev (utf8)


# every day run

    docker compose -f docker-compose.dev.yml --env-file .env up


# terminal inside running docker container
    docker ps
    docker exec -it <mycontainer> sh
    docker exec -it 606230741c21 sh


sudo gem install bundler
gem update --system 4.0.4
bundle install
