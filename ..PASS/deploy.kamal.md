
# KAMAL IS => SSH + DOCKER
    # SSH into your server
    # run docker pull, docker run, docker stop, docker rm
    # label containers so it can find them again
    # optionally run a proxy (Traefik) container


    kamal app exec 'true'   # just to confirm it connects
    kamal app stop
    kamal proxy stop
    kamal remove
    kamal lock release

    storage is untached?
        sudo du -sh /var/lib/docker/volumes/app_storage/_data || true

# check locally
    docker build --no-cache -f Dockerfile.prod.aws -t dop_rails:test .

# inspect in server
    docker inspect $(docker ps -q --filter label=service=dop_rails_app) | less

sudo apt install dos2unix
dos2unix .kamal/secrets
grep -E '^(DATABASE_HOST|DATABASE_USER|DATABASE_NAME)=' .kamal/secrets

# push to git before deploy
    git push
# once per server
    kamal setup

# kamal deploy
    mise use -g ruby@3.4.7

    RAILS_ENV=production bin/rails zeitwerk:check
    RAILS_ENV=production bin/rails assets:precompile
    RAILS_ENV=production bin/rails runner 'puts "BOOT OK"'
    npm run build

    NEW=$(git rev-parse HEAD)
    echo $NEW
    kamal deploy --version=$NEW


[//]: # (    kamal build push --version=$&#40;date +%Y%m%d%H%M%S&#41;)


# Kamal is pinned to an old version in config


grep -R "20673c3" -n config/deploy*
grep -R "dop_rails" -n config/deploy*

kamal config








# logs
    kamal logs 547b90469fd7
9c6d0e1533ad

# verify 
    kamal shell
    cat /rails/public/vite-assets/BUILD_TIME.txt
    
    kamal shell
    ls -la /rails/public/vite-assets/assets | head -20


kamal app exec "bundle exec rails db:migrate"


kamal shell
curl -i http://127.0.0.1:3000/up
curl -i http://127.0.0.1:3000/

kamal proxy logs
kamal logs -n 200


    npm run build
# => kamal deploy --version=$(date +%Y%m%d%H%M%S)
kamal config



    kamal lock help
    kamal lock release

    kamal app details
        vivente-arch-web-20260105191225

    kamal version
    kamal app boot

if old assets - quick fix
    kamal shell
    rm -rf public/assets
    bundle exec rails assets:precompile


    kamal app exec 'bin/rails db:migrate'
    kamal app exec 'printenv | sort'


    kamal shell
    pwd
    ls -la
    bundle -v
    bundle list | grep rails
    which rails
    env | grep BUNDLE

docker ps -a --filter "name=dop_rails_app-web" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
docker logs --tail 300 dop_rails_app-web-2d4ec7641f062e50e39b1fb8110c3f026f8786fd

docker run --rm -it --entrypoint sh kokinsdockaigars/dop_rails






console: app exec --interactive --reuse "bin/rails console"

    kamal console

    u = User.where(email: "kokins.aigars@gmail.com")
    u.update(password: "87347IUHOhsdo820sLAksjd.")
    u.save
    exit

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
docker logs --tail 300 dop_rails_app-web-2d4ec7641f062e50e39b1fb8110c3f026f8786fd
    kamal rollback --version=20251229120555
    
    kamal config
    kamal env
    kamal logs
    
    kamal proxy logs -n 200
    kamal app logs -n 200

If RAILS_SERVE_STATIC_FILES is empty, that’s very likely the problem.
    config/deploy.yml
        env:
            clear:
                RAILS_SERVE_STATIC_FILES: "1"
                
                
                
                curl -v http://0.0.0.0:3000/up
ss -lntp | rg ':80|:443|:3000'


Hard nuke on the SERVER (SSH into EC2 and do:)
    
    docker stop $(docker ps -q)
    docker rm $(docker ps -aq)
    docker image prune -af
    docker volume prune -f

docker logs <web-container> | rg "v17.01"





    
    Why this happens only on Kamal (very common)
    
    In containers, file type detection can differ because of missing OS packages. ActiveStorage uses content-type sniffing (via Marcel / mimetype detection). If the container is missing file magic DB, it can mis-detect files and mark them “spoofed”.
    Fix: install shared-mime-info (and sometimes file) in your image.
    in docker file
        RUN set -eux; \
        apt-get update -qq && apt-get install -y --no-install-recommends \
        shared-mime-info file \
        
    config/environments/production.rb: 
        config.force_ssl = true



    strage
    kamal app exec 'df -h /rails/storage && ls -la /rails/storage | head'

    config/environments/production.rb
        config.active_storage.service = :local


How to know the new version is running
1) Check which image the running container uses
   docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

2) Check the app from Kamal (best)
   kamal app details
   kamal app logs -n 200

3) docker disk space
    docker system df
    docker volume ls
    docker system df -v


4) Safe cleanup sequence
    docker builder prune -af
    docker image prune -af
    docker system prune -af

5) verify your uploads volume is real and kept:
     docker volume inspect app_storage



    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    docker exec -it <your-web-container-name> sh -lc 'ss -lntp | rg ":3000" || netstat -lntp | rg ":3000"'
    docker exec -it kamal-proxy sh -lc 'ss -lntp | rg ":3000" || netstat -lntp | rg ":3000"'
    docker ps --format "{{.Names}}" | rg -i "proxy|kamal"
    docker exec -it vivente-arch-web-20251230144952 sh -lc 'curl -v http://vivente-arch:3000/up || true'
    
    docker volume ls | rg 'app_storage|app_public|vivente'
    
    docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}"
    docker inspect vivente-arch-web-20251230144952 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
    
    docker ps --format "{{.Names}}" | rg -i "proxy|kamal"
    docker exec -it kamal-proxy sh -lc 'curl -v http://vivente-arch-web:3000/up || curl -v http://<container-ip>:3000/up'
    
    
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"



    inspect docker network
        docker network ls 
        docker network inspect kamal 2>/dev/null | head -n 30
        docker network inspect kamal | rg -n 'Name|IPv4Address|Containers' -n
        docker network ls --format '{{.Name}}' | rg -i 'kamal|vivente|proxy|web'
        docker network inspect <that_network_name> | head -n 40
            docker network inspect kamal | head -n 40

    sniff network
        ip -br link


    sudo tcpdump -i docker0 -nn -s0 -A 'tcp port 3000' -c 20

        ip -br link | rg '^br-'
        br-19835d904b02
        sudo tcpdump -i br-19835d904b02 -nn -s0 -A 'tcp port 3000' -c 30

        sudo tcpdump -i br-19835d904b02 -nn -s0 -vv 'tcp dst port 3000' -c 200
        sudo tcpdump -i br-19835d904b02 -nn -s0 -XX 'tcp dst port 3000 and (tcp[((tcp[12] & 0xf0) >> 2)] = 0x16)'




https:///lv
1) Go inside the running container (Kamal)
   kamal app exec -r web 'whoami && pwd && ls -la'

Then inspect the public folder:
    kamal app exec -r web 'ls -la /rails/public | head -200'
    kamal app exec -r web 'ls -la /rails/public/assets | head -50'
    kamal app exec -r web 'ls -la /rails/public/vite-assets | head -50'

Search for the exact files:
    kamal app exec -r web 'ls -la /rails/public/vite-assets/assets | rg "application_styles" || true'
    kamal app exec -r web 'ls -la /rails/public/assets | rg "home_card_icons|icon_1" || true'

2) Confirm whether Rails is configured to serve static files
    kamal app exec -r web 'printenv | rg "RAILS_SERVE_STATIC_FILES|RAILS_ENV|NODE_ENV|RAILS_MASTER_KEY|SECRET_KEY_BASE"'

If RAILS_SERVE_STATIC_FILES is empty, that’s very likely the problem.
    config/deploy.yml
    env:
      clear:
        RAILS_SERVE_STATIC_FILES: "1"


docker build -t kokinsdockaigars/dop_rails_01:v1.1.2 .
docker push kokinsdockaigars/dop_rails_01:v1.1.2

curl -I http://dev.architecturevivente.com
curl -I https://dev.architecturevivente.com
curl -I https://sacredgeometrysites.com


kamal app exec 'ls -lah app/assets/images | sed -n "1,200p"'
kamal app exec 'ls -lah public | sed -n "1,200p"'
kamal app exec 'rg -n "home_bg\.jpg|home-bg\.jpg|home_bg" app | head'
kamal app exec 'echo $SECRET_KEY_BASE | wc -c'


docker ps
docker exec -it <container_id> bash
cat config/puma.rb | rg current

# Step 1: Install Kamal
    
    gem install kamal

        group :development do
            gem "kamal"
        end

    bundle exec kamal init
    bundle exec kamal version


# Step 2: Create the config/deploy.yml File

    config/deploy.yml

# Step 3: Handle Environment Secrets
    
    .env.prod.aws == .kamal/secrets

# Step 4: Kamal (deploy with a new --version each time )

1. =>   kamal setup
         kamal setup --version=$(git rev-parse --short HEAD)
   
   Deploy with a unique version:
   
      kamal lock status
      kamal lock release
      kamal setup --version=$(date +%Y%m%d%H%M%S)

2. =>   kamal deploy
        kamal deploy --version=$(git rev-parse --short HEAD)

   Deploy with a unique version:
      
      kamal deploy --version=$(date +%Y%m%d%H%M%S)


        kamal details
clear
        kamal logs

kamal app logs -n 200
kamal app logs -n 200 --since 5m
kamal proxy logs -n 200

clean disk
    docker builder prune -af
    docker image prune -af
    docker system prune -af




kamal app details
kamal proxy details

## docker needs permissions in server
    if you want to run Docker as a non-root user, then you need to add your user to the docker group.
    Create the docker group if it does not exist:
        $ sudo groupadd docker
    Add your user to the docker group:
        $ sudo usermod -aG docker $USER
    Log in to the new docker group (to avoid having to log out and log in again; but if not enough, try to reboot):
        $ newgrp docker
    Check if Docker can be run without root:
        $ docker run hello-world
    Reboot if you still get an error:
        $ reboot


kamal app exec -i -- sh
# inside container:
mkdir -p /rails/log
touch /rails/log/production.log
chmod 664 /rails/log/production.log
# and ensure directory writable:
chmod 775 /rails/log

kamal app exec -- ls -la /rails/log
kamal app exec -- sh -lc 'id && touch /rails/log/production.log && echo OK'

kamal app exec -- sh -lc 'bundle info image_processing || true'


What kamal setup actually does
    Think of kamal setup as turning a raw EC2 box into a Kamal-ready host.
    It:
        SSHes into your server
        Installs Docker (if missing)
        Installs Docker Compose plugin (if needed)
        Creates Kamal’s internal directories
        Sets up:
        container registry login
        secrets handling
        Verifies the host can:
        pull images
        run containers
        Prepares networking and volumes
            It does NOT deploy your app yet
            It does NOT rebuild images
            It does NOT migrate the database
    Run it:
        once per new server
        again only if the server was wiped/recreated

What kamal deploy actually does
    This is your release button.
    It:
        Builds your Docker image (locally or in CI)
        Pushes it to your registry
        Pulls the image on the server
        Stops the old container
        Starts the new container
        Injects env & secrets
        Runs health checks
        Switches traffic (zero/near-zero downtime)
        Cleans up old images
            This is what you run 99% of the time




[//]: # (image magic not included in docker file)
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.ID}}\t{{.Status}}"
docker inspect --format '{{.Name}}  {{.Config.Image}}  {{.Image}}' <container_id_or_name>
docker exec -it <app_container> sh -lc 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/up'
docker exec -it kamal-proxy sh -lc 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/up'
docker exec -it kamal-proxy sh -lc 'bin/rails routes | grep -E "^rails_health_check|/up" || true'
docker container ls -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
docker inspect vivente-arch-web-7cc529f2d74f6fab9865626317269a31e5e73d62 --format '{{json .Config.Healthcheck}}'
docker inspect vivente-arch-web-7cc529f2d74f6fab9865626317269a31e5e73d62 --format '{{json .State.Health}}'
docker logs --tail 200 vivente-arch-web-7cc529f2d74f6fab9865626317269a31e5e73d62


check if the running container has ImageMagick
    kamal app exec -r web 'which identify && identify -version'
    kamal app exec -r web 'which file && file --version | head -n 1'
    kamal app exec -r web 'which identify || echo "NO identify"; identify -version || true'








