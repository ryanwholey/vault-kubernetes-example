const fs = require('fs')
const util = require('util')

const dotenv = require('dotenv')

const readFile = util.promisify(fs.readFile)

async function parseDbCredentials() {
  const {PG_CONNECTION_STRING: pgConnectionString} = dotenv.parse(await readFile(process.env.ENV_FILE))
  return new URL(pgConnectionString)
}

module.exports = parseDbCredentials
