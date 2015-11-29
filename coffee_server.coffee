#nodejs-geodata-analitics-api

# ========== API INFO
API = {
  version: '0.2.0',
  name: 'JSON API for analysis of browser request information',
  github: 'https:github.com/ipepe/nodejs-geodata-analitics-api',
}

# ========== DEPENDENCIES
app = require('express')()
mmdbreader = require('maxmind-db-reader')
cors = require('cors')

# ========== CONFIGURATION
server_port = process.env.OPENSHIFT_NODEJS_PORT || process.env.PORT || 3000
server_ip_address = process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1'

# ========== SETUP EXPRESS
# openshift is serving node behind proxy
if process.env.OPENSHIFT_NODEJS_IP
  app.set('trust proxy', process.env.OPENSHIFT_NODEJS_IP )

detectIsAzure = ->
  for key in process.env
    return true if key.toLowerCase().indexOf('azure') > -1
    return true if process.env[key].toLowerCase().indexOf('azure') > -1
  false

if detectIsAzure()
  app.set('trust proxy')

app.use( cors() )
app.use (req, res, next) ->
  res.contentType('application/json')
  next()


# ========== MAXMIND DATABASE SETUP
# load database
geodataCity = mmdbreader.openSync('./GeoLite2-City.mmdb')
geodata_info = {
  info: 'This product includes GeoLite2 data created by MaxMind, available from http:www.maxmind.com',
  db_datetime: "2015-11-29T09:56:08.358Z",
  db_unix_datetime: 1448790968358
}
geodata_cache = {}

get_geodata_info = (ip_address)->
  if geodata_cache[ip_address]
    geodata_cache[ip_address]
  else
    result = geodataCity.getGeoDataSync(ip_address)
    geodata_cache[ip_address] = result
    result


my_api_info = JSON.stringify({
  api_name: API.name,
  api_version: API.version,
  api_git_repo_url: API.github,
  info: {
    geodata: geodata_info
  }
})



#========== APP CODE
createApiResponse = (req) =>
  console.log("request ip", req, req.ip, req.ips)
  JSON.stringify
    info: JSON.parse(my_api_info),
    result:
      client_ip: req.ip,
      client_proxy_chain_ips: req.ips,
      server_unix_time: Date.now(),
      server_iso_time: new Date().toISOString(),
      headers: req.headers,
      geodata: get_geodata_info(req.ip),


app.get '/', (req, res) ->
  api_response = JSON.parse my_api_info
  api_response.usage =
    variable:"/var=variableName",
    json:"/api.json",
    callback:'/callback=functionName'
  res.send(JSON.stringify(api_response))

app.get '/*.json', (req, res) ->
  res.send createApiResponse req

app.get '/var=*', (req, res) ->
  res.send('var ' + req.params['0'] + ' = ' + createApiResponse(req) )

app.get '/callback=*', (req, res) ->
  res.send( req.params['0'] + '(' + createApiResponse(req, 'callback') + ');')

console.log('starting server...', server_ip_address, server_port)
server = app.listen( server_port, server_ip_address )