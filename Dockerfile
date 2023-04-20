FROM ruby:2.6.8
RUN apt-get update -qq && \
    apt-get install -y \
        nano \
        lsof \
        yarn \
        poppler-utils && \
    apt-get install -y build-essential libpq-dev nodejs npm libreoffice imagemagick unzip ghostscript && \
    rm -rf /var/lib/apt/lists/*

# If you want to run a newer version of UniversalViewer, you may need to install a newer version of nodejs
# RUN curl -sL https://deb.nodesource.com/setup_14.x -o /tmp/nodesource_setup.sh
#    apt install nodejs

# If changes are made to fits version or location,
# amend `LD_LIBRARY_PATH` in docker-compose.yml accordingly.
RUN mkdir -p /opt/fits && \
    cd /opt/fits && \
    wget https://github.com/harvard-lts/fits/releases/download/1.5.1/fits-1.5.1.zip -O fits.zip && \
    unzip fits.zip && \
    rm fits.zip && \
    chmod a+x /opt/fits/fits.sh
#ENV PATH="${PATH}:/opt/fits"

# Install universalviewer
RUN mkdir /node
RUN  npm install universalviewer@3.0.36 --prefix /node

RUN mkdir /data
WORKDIR /data
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
ADD .irbrc /root/.irbrc
RUN bundle install
RUN rails db:migrate
ADD . /data
# Configure Active Fedora to use the right core
# RUN sed 's/hydra-development/vault_dev/g' /usr/local/bundle/gems/active-fedora-11.5.2/config/solr.yml
# RUN bundle exec rake assets:precompile
EXPOSE 3000
