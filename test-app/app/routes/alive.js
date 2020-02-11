'use strict'

module.exports = {
  method: 'GET',
  path: '/system/health/alive',
  handler: async function(request) {
    return {}
  }
}
