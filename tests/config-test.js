/* eslint-disable max-nested-callbacks */
'use strict'

const path = require('path')
const config = require('../src/config')
const configContents = require('./fixtures/tcs.json')

describe('config', function () {
  let conf
  beforeEach(() => {
    conf = config(path.join(__dirname, 'fixtures/tcs.json'))
  })

  it('returns the config', () => {
    expect(conf).toEqual(configContents)
  })
})
