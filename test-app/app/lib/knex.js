'use strict'

// load this first so we can set env BLUEBIRD_DEBUG=1
const config = require('../config')

const Joi = require('joi')
const Knex = require('knex')
const parseDbCredentials = require('./parseDbCredentials')

try {
    Joi.assert(
        config.pgConnectionString,
        Joi.string().uri({ scheme: 'postgres' }).required()
    )
} catch (e) {
    console.error(`ERROR: Invalid postgres connection string: '${config.pgConnectionString}'. Will now exit.\n`) // eslint-disable-line no-console
    process.exit(1) // eslint-disable-line no-process-exit
}

const initial = new URL(config.pgConnectionString).username

const knex = new Knex({
    client: 'pg',
    pool: {
        min: 1,
        max: 10,
    },
    debug: config.debugDatabase,
    connection: async () => {
        const { username, password, hostname, port, pathname } = await parseDbCredentials()
        const connection = {
            port,
            password,
            database: pathname.replace('/', ''),
            host: hostname,
            user: username,
            expirationChecker: () => {
                console.log(`CHECKING EXIRATION: expired=${initial !== username};initial=${initial};new=${username}`)
                return true
            }
        }
        
        return connection
      }
})

module.exports = knex
