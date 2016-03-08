#!/bin/bash

#
# Environment variables passed into context by caller
#
# TIMESTAMP - the timestamp of the request (used to make a temp directory)
# SLUG - the repo slug (org/repo)
# GITHUB_TOKEN - the read/write token for travis-ci-ciena user for version bumps
# NPM_API_TOKEN - the npm API token for publishing
# SLACK_TOKEN - the slack token used to push msgs to slack
#

module=$(echo $SLUG | awk -F/ '{print $2;}')

mkdir $TIMESTAMP
cd $TIMESTAMP

# start with our baseline .travis.yml
# TODO: make this configurable later
cat <<EOT >> .travis.yml
language: node_js
node_js:
- '5.0'
- 'stable'
sudo: false
branches:
  except:
  - "/^v[0-9\\.]+/"
cache:
  directories:
  - bower_components
  - node_modules
addons:
  apt:
    sources:
    - ubuntu-toolchain-r-test
    packages:
    - g++-4.8
env:
  matrix:
  - EMBER_TRY_SCENARIO=default
  - EMBER_TRY_SCENARIO=ember-release
  - EMBER_TRY_SCENARIO=ember-beta
  - EMBER_TRY_SCENARIO=ember-canary
  global:
    - CXX=g++-4.8
matrix:
  fast_finish: true
  allow_failures:
  - env: EMBER_TRY_SCENARIO=ember-canary
before_install:
- npm config set spin false
- npm install -g coveralls pr-bumper
- pr-bumper check
install:
- npm install
- bower install
before_script:
- "export DISPLAY=:99.0"
- "sh -e /etc/init.d/xvfb start"
- sleep 3 # give xvfb some time to start
script:
- npm run lint
- ember try:one $EMBER_TRY_SCENARIO --- ember test
after_success:
- sed -i -- 's/SF:${module}\/\(.*\)/SF:addon\/\1.js/' coverage/lcov.info && rm -f coverage/lcov.info--
- cat coverage/lcov.info | coveralls
before_deploy:
- pr-bumper bump
deploy:
  provider: npm
  email: npm.ciena@gmail.com
  skip_cleanup: true
  api_key:
  on:
    branch: master
    condition: "$EMBER_TRY_SCENARIO = 'default'"
    node: 'stable'
    tags: false
after_deploy:
- .travis/publish-gh-pages.sh
notifications:
  slack:
EOT

# login and encrypt all the things
travis login --github-token $GITHUB_TOKEN
travis encrypt GITHUB_TOKEN=$GITHUB_TOKEN --add -r $SLUG
travis encrypt $NPM_API_TOKEN --add deploy.api_key -r $SLUG
travis encrypt "$SLACK_TOKEN" --add notifications.slack -r $SLUG

# rename the file b/c sendFile in express doesn't see to like dotfiles
mv .travis.yml travis.yml
