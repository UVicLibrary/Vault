FROM ruby:2.7.8
RUN apt-get update -qq && \
    apt-get install -y \
        build-essential \
        ghostscript \
        imagemagick \
        libpq-dev \
        libvips \
        ffmpeg \
        nodejs \
        npm \
        libreoffice \
        libsasl2-dev \
        nano \
        lsof \
        yarn \
        unzip \
        poppler-utils && \
        apt-get clean && \
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

# The new home for our application is /home/app/webapp (used to be /data)
RUN mkdir -p /home/app/webapp
WORKDIR /home/app/webapp

ADD Gemfile /home/app/webapp/Gemfile
ADD Gemfile.lock /home/app/webapp/Gemfile.lock
ADD .irbrc /root/.irbrc
RUN bundle install
RUN rails db:migrate RAILS_ENV=development
ADD . /home/app/webapp
EXPOSE 3000
CMD /bin/bash