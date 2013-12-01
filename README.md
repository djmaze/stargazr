## Configuration

In order to get by the anonymous Github API usage limit (recommended):

* Get a personal access token for the app from [the application settings at Github](https://github.com/settings/applications). 
* Put it in your _.env_ file, at `GITHUB_ACCESS_TOKEN`.

## Testing email

    gem install mailcatcher
    mailcatcher

View mails at [http://localhost:1080](http://localhost:1080).
