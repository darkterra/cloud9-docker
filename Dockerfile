# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
FROM kdelfour/supervisor-docker
MAINTAINER Jérémy Young <darkterra01@gmail.com>

# ------------------------------------------------------------------------------
# Install base
RUN sudo apt-get update
RUN sudo apt-get install -y build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs
    
# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN sudo scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /workspace
VOLUME /workspace

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN sudo apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------------------
# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN sudo apt-get install -y nodejs

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
#EXPOSE 3000

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
