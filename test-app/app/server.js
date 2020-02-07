'use strict'

const config = require('./config')

const path = require('path')

const Hapi = require('hapi')
const HapiRouter = require('hapi-router')

async function initServer() {
    const server = new Hapi.Server({
        debug: { request: ['info'] } ,
        port: config.port,
    })
    
    await server.register([
        {
            plugin: HapiRouter,
            options: {
                cwd: path.join(__dirname, 'routes'),
                routes: '**/*.js'
            },
        }
    ])
    
    try {
        await server.start()
        console.log(`Server started at ${config.port}`)
    } catch (err) {
        console.error('Problem during startup error; server should now exit')
        throw err
    }

    return server
}

initServer()
