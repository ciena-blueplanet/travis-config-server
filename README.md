[ci-img]: https://img.shields.io/travis/ciena-blueplanet/travis-config-server.svg "Travis CI Build Status"
[ci-url]: https://travis-ci.org/ciena-blueplanet/travis-config-server

[cov-img]: https://img.shields.io/coveralls/ciena-blueplanet/travis-config-server.svg "Coveralls Code Coverage"
[cov-url]: https://coveralls.io/github/ciena-blueplanet/travis-config-server
[npm-img]: https://img.shields.io/npm/v/travis-config-server.svg "NPM Version"
[npm-url]: https://www.npmjs.com/package/travis-config-server

# travis-config-server <br /> [![Travis][ci-img]][ci-url] [![Coveralls][cov-img]][cov-url] [![NPM][npm-img]][npm-url]
A simple web service to ease the building of `.travis.yml` configs

## Setup
In order to utilize `travis-config-server`, you need to install some prerequisites on the server you'll have it running.
`travis-config-server` needs to be able to run the command-line `travis` utility to encrypt sensitive data into the
generated `.travis.yml`.

### Installing travis CLI
The Travis CLI can be installed by following the directions here: https://github.com/travis-ci/travis.rb#installation

### Configuring travis-config-server
We can't encrypt what we don't know, so you have to create a config file (`.tcs.json`) which holds the secrets you want
`travis-config-server` to encrypt into `.travis.yml` for you when it's generated. The file looks something like this:

```javascript
{
  "travis": {
    // the personal access token for the github user that will be
    // used for doing automated version bumps (must have write permissons on the repo)
    "rwToken": "<long-ugly-hash-1>"
  },
  "npm": {
    // the API token for the npm user to do deploy into npmjs.com
    "apiToken": "<long-ugly-hash-2>"
  },
  "slack": {
    // The slack integration token (with the team name in front)
    "token": "<team>:<slack-token>"
  }
}
```

Fill in the info above and store that file somewhere you can point at later, maybe `~/.tcs.json`

## Usage
Using the service is done in two ways.
 1. Starting up the server somewhere
 1. Hitting the server to get your `.travis.yml` file.

### Launching the server
Install the server


```
npm install -g travis-config-server
```

Navigate somewhere you don't mind temporary directories being created when people request `.travis.yml` files on
the server you want to host your `travis-config-server` instance.


```
mkdir -p ~/travis-config-server
cd ~/travis-config-server
```

Start up the server (telling it where the `.tcs.json` is stored)


```
TCS_CONFIG_PATH=~/.tcs.json DEBUG=server travis-config-server
```


Once you're confident it's working and you have the right info in your `.tcs.json` file, you can launch the server
so it won't stop when you log out:


```
TCS_CONFIG_PATH=~/.tcs.json nohup travis-config-server &
```

### Requesting a `.travis.yml` file
Downloading a `.travis.yml` file from this service is very simple. Let's say your server is running at
`https://my-domain.com`. To request a `.travis.yml` for the `foo-bar` repository in the `baz-bob` org, issue
the following command:


```bash
curl -O https://my-domain.com:3333/baz-bob/foo-bar/.travis.yml
```

You now have a `.travis.yml` file with all the encrypted goodies you need. Here's the current baseline it's using:


```
language: node_js
sudo: false
node_js:
- '5.3'
branches:
  except:
  - /^v[0-9\.]+/
before_install:
- npm install -g coveralls pr-bumper
- pr-bumper check
install:
- npm install
- bower install
after_success:
- sed -i -- 's/SF:${module}\/\(.*\)/SF:addon\/\1.js/' coverage/lcov.info && rm -f coverage/lcov.info--
- cat coverage/lcov.info | coveralls
addons:
  apt:
    sources:
    - ubuntu-toolchain-r-test
    packages:
    - g++-4.8
env:
  matrix:
  - CXX=g++-4.8
  global:
before_deploy:
- pr-bumper bump
deploy:
  provider: npm
  email: npm.ciena@gmail.com
  skip_cleanup: true
  api_key:
  on:
    branch: master
    tags: false
after_deploy:
- .travis/publish-gh-pages.sh
notifications:
  slack:
```


The following commands are then run against the `.travis.yml` before it's returned in the web service reponse:


```
travis login --github-token $GITHUB_TOKEN
travis encrypt GITHUB_TOKEN=$GITHUB_TOKEN --add -r $SLUG
travis encrypt $NPM_API_TOKEN --add deploy.api_key -r $SLUG
travis encrypt "$SLACK_TOKEN" --add notifications.slack -r $SLUG
```

