# EasyWeb: Dockerized Web Server with NGINX, PHP, and LetsEncrypt Certificate

This project allows you to run a simple nginx web server with out-of-the-box PHP and TLS support.
The entire setup is running in Docker and managed with Docker Compose.
You just have to supplement your public domain to start the web server with automatically generated Let's Encrypt certificates.

## Setup

- Install `docker`: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
- Install `docker-compose`: [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)
- Configure the `A` and `AAAA` records of your domain to point to your server
- On your server, clone this repository: `git clone https://github.com/iphoneintosh/docker-nginx-php-letsencrypt`
- Go into this directory: `cd docker-nginx-php-letsencrypt`
- In `nginx.conf`, replace `one.domain` with your real domain
- In `gen-certs.conf`, insert your domain into the `domains` array
- In `gen-certs.conf`, optionally insert your email address
- Generate the certificates: `bash gen-certs.conf`
- Open your domain in a web browser. TLS should work now.
