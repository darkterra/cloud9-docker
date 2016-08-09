# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
FROM darkterra/supervisor-docker
MAINTAINER Jérémy Young <darkterra01@gmail.com>

# ------------------------------------------------------------------------------
# Install basics
RUN apt-get update
RUN apt-get install -y build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs

# ------------------------------------------------------------------------------
# Install Postgre
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get update
RUN apt-get install -y postgresql-9.4

# ------------------------------------------------------------------------------
# Install Redis
RUN wget http://download.redis.io/redis-stable.tar.gz && tar xvzf redis-stable.tar.gz && cd redis-stable && make

# ------------------------------------------------------------------------------
# Install Node.js (Uniquement pour lancer le serveur Cloud9)
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs

# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------------------
# Suppression de Postgres 9.3
RUN sudo -u ubuntu -i bash -l -c " \
    sudo apt-get purge -y postgresql-9.3"

# ------------------------------------------------------------------------------
# Ajout de la configuration de Postgres 9.4
ADD conf/pg_hba.conf /etc/postgresql/9.4/main/
ADD conf/postgresql.conf /etc/postgresql/9.4/main/

# ------------------------------------------------------------------------------
# Configurations Spécifique à Oscar (TODO: Déporter cette partie dans un script)
RUN echo Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/sudoers

# Version spécifique pour l'application Oscar
RUN sudo -u ubuntu -i bash -l -c " \
    nvm install 0.10.40 && \
    nvm alias default 0.10.40"
    
# TODO: Vérifier la commande forever colums add dir (ci dessous) si elle est correcte !
RUN sudo -u ubuntu -i bash -l -c " \
    npm install -g npm@2.7.5 && \
    npm install -g forever@0.15.1 && \
    forever columns add dir && \
    sudo apt-get install libxinerama1 libfontconfig1 libcups2 && \
    cd ~ && \
    wget https://downloadarchive.documentfoundation.org/libreoffice/old/4.1.6.2/deb/x86_64/LibreOffice_4.1.6.2_Linux_x86-64_deb.tar.gz && \
    tar -xvzf LibreOffice_4.1.6.2_Linux_x86-64_deb.tar.gz && \
    cd LibreOffice_4.1.6.2_Linux_x86-64_deb/DEBS && \
    sudo dpkg -i *.deb"

# Ajout du fichier de config npm
ADD conf/npmrc /home/ubuntu/.npmrc
RUN chown ubuntu:ubuntu /home/ubuntu/.npmrc
RUN chmod 600 /home/ubuntu/.npmrc

# Ligne à supprimer ?
#    sudo apt-get remove --purge libreoffice* && \
#    sudo apt-get autoremove --purge && \
#    sudo apt-get install ttf-mscorefonts-installer && \

# Remplacé par la copie du fichier .npmrc (ci-dessus)
#    sudo npm set registry http://xpars-tls01.compass-group.fr:4873/ && \
#    sudo npm set strict-ssl false && \
#    sudo npm set always-auth true

# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 80 8080 5433

# ------------------------------------------------------------------------------
# Start supervisor, define default command
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]