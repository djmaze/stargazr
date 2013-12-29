## Configuration

* Copy _.env.development.sample_ to _.env.development_. Adjust the mail settings.
* Register a new developer application in  [the application settings at Github](https://github.com/settings/applications). Put the client id and secret in your _.env_ file.

Production works accordingly, with _.env.production_.

## Testing email

    gem install mailcatcher
    mailcatcher

View mails at [http://localhost:1080](http://localhost:1080).
