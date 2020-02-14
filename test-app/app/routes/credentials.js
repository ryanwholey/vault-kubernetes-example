'use strict'

const knex = require('../lib/knex')
const config = require('../config')
const _ = require('lodash')

module.exports = {
  method: 'GET',
  path: '/credentials',
  config: {},
  handler: async function(request) {
    let version

    try {
      version = await knex.select(knex.raw('VERSION()'))
    } catch (err) {
    
    }
    const status = version ? 'OK' : 'FAILURE'
    console.log(`${new Date().toISOString()}: ${request.url}: ${status}`)
    const { username, password } = new URL(config.pgConnectionString)
    console.log(`\t user: ${username}`)
    console.log(`\t pass: ${password}`)
    console.log(`\t pod: ${process.env.POD_NAME}`)
  
    return {
      ..._.pick(knex.client.config.connection, ['user', 'password']),
      status,
      podName: config.podName
    }
  }
}
