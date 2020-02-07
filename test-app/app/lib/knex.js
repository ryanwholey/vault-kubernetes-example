'use strict'

// load this first so we can set env BLUEBIRD_DEBUG=1
const config = require('../config')

const Joi = require('joi')
const Knex = require('knex')

try {
    Joi.assert(
        config.pgConnectionString,
        Joi.string().uri({ scheme: 'postgres' }).required()
    )
} catch (e) {
    console.error(`ERROR: Invalid postgres connection string: '${config.pgConnectionString}'. Will now exit.\n`) // eslint-disable-line no-console
    process.exit(1) // eslint-disable-line no-process-exit
}

const knex = new Knex({
    client: 'pg',
    connection: config.pgConnectionString,
    pool: {
        min: config.knexPoolMin,
        max: config.knexPoolMax
    },
    debug: config.debugDatabase
})

module.exports = knex
