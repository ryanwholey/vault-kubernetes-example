'use strict'

const knex = require('../lib/knex')
const config = require('../config')

module.exports = {
    method: 'GET',
    path: '/credentials',
    config: {},
    handler: async function(request) {
      let version
      let status
      try {
        version = await knex.select(knex.raw('VERSION()'))
        status = version ? 'OK' : 'NOT OK'
      } catch (err) {
        status = 'NOT OK'
        console.error(err)
      }

      console.log(`${new Date().toISOString()}: ${request.url}: ${status}`)

      return {
        pgVersion: version[0].version,
        status, 
        credentials: config.pgConnectionString,
        podName: config.podName
      }
    }
}
