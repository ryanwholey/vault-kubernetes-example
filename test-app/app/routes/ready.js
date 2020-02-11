'use strict'

const knex = require('../lib/knex')

module.exports = {
  method: 'GET',
  path: '/system/health/ready',
  config: {},
  handler: async function() {
    const version = await knex.select(knex.raw('VERSION()'))

    if (!version) {
      throw new Error("No connection")
    }

    return {}
  }
}
