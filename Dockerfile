# Build: docker build -t stargazr .
# Run: docker run -d -p 4567:4567 -link arangodb:arangodb stargazr
FROM ruby:2.0

RUN apt-get update -qq

# Locale
RUN apt-get -y install locales && \
    echo C.UTF-8 UTF-8 >/etc/locale.gen && \
    locale-gen

# Add cronjob
RUN apt-get -y install cron
RUN echo "HOME=/usr/src/myapp\nPATH=$RUBY_PATH/bin:$PATH\n\n@daily /bin/bash -l -c 'RACK_ENV=production bundle exec ruby notifier.rb >>log/notifier.log 2>&1'" | crontab -

# Bundle
WORKDIR /usr/src/app
ADD Gemfile /usr/src/app/Gemfile
ADD Gemfile.lock /usr/src/app/Gemfile.lock
RUN bundle install --system -j 4

# Add project
ADD . /usr/src/app

CMD /bin/bash -c "cron && bundle exec ruby web.rb -o 0.0.0.0"
EXPOSE 4567
VOLUME /usr/src/myapp/log
