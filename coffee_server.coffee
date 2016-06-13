#nodejs-geodata-analitics-api

# ========== DEPENDENCIES
app = require('express')()
cors = require('cors')
request = require('request')

# ========== CONFIGURATION
server_port = process.env.OPENSHIFT_NODEJS_PORT || process.env.PORT || 3000
server_ip_address = process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1'

# ========== SETUP EXPRESS
# openshift is serving node behind proxy
if process.env.OPENSHIFT_NODEJS_IP
  app.set('trust proxy', process.env.OPENSHIFT_NODEJS_IP )
else if process.env.NODE_ENV == 'production'
  app.set('trust proxy', true)

app.use(cors())

# ========== App Logic
app.get '/', (req, res) ->
  res.contentType('application/json')
  options = { url: new Buffer(req.query['url'], 'base64').toString() }
  options.headers = JSON.parse(req.query['headers']) if req.query['headers']
  request options, (error, response) ->
    res.send(JSON.stringify({error: error, response: response}))

# ========== App Start
console.log('starting server...', server_ip_address, server_port)
server = app.listen( server_port, server_ip_address )