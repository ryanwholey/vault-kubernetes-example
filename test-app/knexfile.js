'use strict'

const path = require('path')

const config = require('./app/config')

const knexConfig = {
    client: 'pg',
    connection: config.pgConnectionString,
    migrations: {
        directory: path.join(__dirname, '/migrations'),
        tableName: 'knex_migrations'
    },
    debug: (process.env.hasOwnProperty('DEBUG_KNEX'))
}

// hack:
exports.development = exports.production = exports.test = knexConfig
