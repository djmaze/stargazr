 # Build: docker build -t stargazr .
# Run: docker run -p 4567:4567 -d stargazr
FROM ubuntu

RUN sed -i "s/main/main universe/" /etc/apt/sources.list
RUN apt-get update

# Locale
RUN apt-get -y install language-pack-de-base && update-locale LC_ALL=de_DE.UTF-8

# Install ruby-build
RUN apt-get install -y sudo git-core wget build-essential libssl-dev libreadline-dev
RUN git clone https://github.com/sstephenson/ruby-build.git
RUN cd ruby-build && ./install.sh

# Install Ruby & bundler
ENV RUBY_VERSION 2.0.0-p247
ENV RUBY_PATH /usr/local/ruby-$RUBY_VERSION
RUN ruby-build $RUBY_VERSION $RUBY_PATH
RUN $RUBY_PATH/bin/gem install bundler --pre --no-ri --no-rdoc
RUN echo "export PATH=$RUBY_PATH/bin:$PATH" >/.bash_profile

# Install arangodb
RUN echo 'deb http://www.arangodb.org/repositories/arangodb/xUbuntu_12.04/ /' >> /etc/apt/sources.list.d/arangodb.list
RUN wget -qO- http://www.arangodb.org/repositories/arangodb/xUbuntu_12.04/Release.key | apt-key add -
ENV ARANGODB_VERSION 1.4.13
RUN apt-get update
RUN apt-get -y install arangodb=$ARANGODB_VERSION

# Start arangodb, wait for it to start, create database, stop it, wait for it to stop
RUN echo "#/bin/bash\n" 'while : ; do bash -c "echo >/dev/tcp/localhost/8529" >/dev/null && break || sleep 1; done;' >/usr/local/bin/wait_for_arangodb && \
    chmod u+x /usr/local/bin/wait_for_arangodb

# Add cronjob
RUN apt-get -y install cron
RUN echo "HOME=/docker/stargazr\nPATH=$RUBY_PATH/bin:$PATH\n\n@daily /bin/bash -l -c 'RACK_ENV=production bundle exec ruby notifier.rb >>log/notifier.log 2>&1'" | crontab -

# Add Gemfile and bundle
WORKDIR /docker/stargazr
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN PATH=$RUBY_PATH/bin:$PATH bundle install -j 4

# Add project
ADD . /docker/stargazr

CMD /bin/bash -l -c "/etc/init.d/arangodb start && \
    wait_for_arangodb && \
    arangosh --javascript.execute-string 'db._createDatabase(\"stargazer\")'; \
    cron && \
    RACK_ENV=production bundle exec ruby web.rb"
EXPOSE 4567
EXPOSE 8529
VOLUME /docker/stargazr/log
