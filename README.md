## Prerequisites

* Ruby 2.0 with bundler installed
* [ArangoDB](http://www.arangodb.org/) 1.4 running locally (at port 8529)

## Configuration

* Copy _.env.development.sample_ to _.env.development_. Adjust the mail settings.
* Register a new developer application in  [the application settings at Github](https://github.com/settings/applications). Put the client id and secret in your _.env_ file.

Production works accordingly. Just use _.env.production_ instead.

## Running

Run the website (just a boring Sinatra app):

    ruby web.rb

Run the notifier (preferably once a day):

    ruby notifier.rb

Set `RACK_ENV=production` to run in the production environment.

## Testing email

    gem install mailcatcher
    mailcatcher

View mails at [http://localhost:1080](http://localhost:1080).
