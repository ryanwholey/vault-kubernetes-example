'use strict'

// Explicitly assume 'production' environment unless specified
const NODE_ENV = (!process.env.NODE_ENV) ? 'production' : process.env.NODE_ENV
process.env.NODE_ENV = NODE_ENV

require('dotenv').config({ path: process.env.ENV_FILE })

const config = {
    knex: {
        pool: {
            min: parseInt(process.env.KNEX_POOL_MIN, 10) || 6,
            max: parseInt(process.env.KNEX_POOL_MAX, 10) || 9
        },
    },
    pgConnectionString: process.env.PG_CONNECTION_STRING,
    port: process.env.PORT || 3000,
    podName: process.env.POD_NAME,
}

console.log(config)

module.exports = config
