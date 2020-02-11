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
    }

    console.log(`${new Date().toISOString()}: ${request.url}: ${status}`)
    const { username, password } = new URL(config.pgConnectionString)
    console.log(`\t user: ${username}`)
    console.log(`\t pass: ${password}`)
    console.log(`\t pod: ${process.env.POD_NAME}`)

    return {
      pgVersion: version && version[0].version,
      status, 
      username,
      password,
      podName: config.podName
    }
  }
}
