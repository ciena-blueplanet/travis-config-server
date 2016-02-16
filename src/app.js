'use strict'

const debug = require('debug')('server')
const express = require('express')
const logger = require('morgan')
const path = require('path')
const Promise = require('promise')
const cpExec = require('child_process').exec
const config = require('./config')

const exec = Promise.denodeify(cpExec)
const app = express()

app.use(logger('dev'))

// ==================================================================
//                          The main method
// ==================================================================

/* GET home page. */
app.get('/:org/:repo/.travis.yml', function (req, res) {
  const conf = config()

  const timestamp = Date.now()
  const slug = `${req.params.org}/${req.params.repo}`
  const options = {
    env: {
      'HOME': process.env.HOME,
      'TIMESTAMP': timestamp,
      'SLUG': slug,
      'GITHUB_TOKEN': conf.travis.rwToken,
      'NPM_API_TOKEN': conf.npm.apiToken,
      'SLACK_TOKEN': conf.slack.token
    },
    shell: '/bin/bash'
  }
  exec('bin/generate-travis-yml.sh', options)
    .then(() => {
      const options = {
        root: path.join(process.cwd(), `${timestamp}`),
        headers: {
          'x-timestamp': Date.now(),
          'x-sent': true
        }
      }
      res.sendFile('travis.yml', options, (err) => {
        if (err) {
          debug(`error in sendFile ${err}`)
          res.status(err.status).end()
        }
        exec(`rm -rf ${timestamp}`)
      })
    })
    .catch((err) => {
      debug(`error in exec chain: ${err}`)
      res.send(err)
      exec(`rm -rf ${timestamp}`)
    })
})

// ==================================================================
//                          Error Handling
// ==================================================================

// catch 404 and forward to error handler
app.use(function (req, res) {
  console.log(req.path)
  res.status(404).send('Not Found')
  res.end()
})

// error handler
app.use(function (err, req, res) {
  res.status(err.status || 500)
  res.render('error', {
    message: err.message,
    error: {}
  })
})

module.exports = app
