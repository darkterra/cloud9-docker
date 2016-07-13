# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
FROM resin/rpi-raspbian:jessie-20160713
MAINTAINER Jérémy Young <darkterra01@gmail.com>

# ------------------------------------------------------------------------------
# Install base
RUN sudo apt-get update
RUN sudo apt-get install -y build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs 
    
# ------------------------------------------------------------------------------
# Install Cloud9
RUN sudo git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 

# Add supervisord conf
#ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /workspace
VOLUME /workspace

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------------------
# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
#EXPOSE 3000

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
#CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
CMD ["node", "/cloud9/server.js", "--collab", "--listen 0.0.0.0", "--port 80", "-w", "/workspace"]