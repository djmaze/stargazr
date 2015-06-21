# Build: docker build -t stargazr .
# Run: docker run -d -p 4567:4567 -link arangodb:arangodb stargazr
FROM ruby:2.0

RUN apt-get update -qq

# Locale
RUN apt-get -y install locales && \
    echo C.UTF-8 UTF-8 >/etc/locale.gen && \
    locale-gen

# Add go-cron
RUN curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.7/go-cron-linux.gz \
  | zcat >/usr/local/bin/go-cron \
 && chmod u+x /usr/local/bin/go-cron

# Bundle
WORKDIR /usr/src/app
ADD Gemfile /usr/src/app/Gemfile
ADD Gemfile.lock /usr/src/app/Gemfile.lock
RUN bundle install --system -j 4

# Add project
ADD . /usr/src/app

EXPOSE 4567
VOLUME /usr/src/app/log
