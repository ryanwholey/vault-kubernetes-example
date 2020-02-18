'use strict'

const knex = require('../lib/knex')
const config = require('../config')
const _ = require('lodash')
const parseDbCredentials = require('../lib/parseDbCredentials')

module.exports = {
  method: 'GET',
  path: '/credentials',
  config: {},
  handler: async function(request) {
    let version

    try {
      version = await knex.select(knex.raw('VERSION()'))
    } catch (err) {
      console.log(err)
    }

    const status = version ? 'OK' : 'FAILURE'
    const { username, password } = await parseDbCredentials()

    const response =  {
      ..._.pick(knex.client.config.connection, ['user', 'password']),
      fileUsername: username,
      filePassword: password,
      knexUsername: knex.client.connectionSettings.user,
      knexPass: knex.client.connectionSettings.password,
      status,
      podName: config.podName
    }
    // console.log(response)
    return response
  }
}
