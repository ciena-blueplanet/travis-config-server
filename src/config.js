'use strict'

/**
 * Read and return the config
 * @param {String} path - an override to manually set the path
 * @returns {Object} the config options read from json
 */
module.exports = function (path) {
  const configPath = path || process.env.TCS_CONFIG_PATH || '../.tcs.json'
  return require(configPath)
}
