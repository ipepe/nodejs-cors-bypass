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
else if process.env.NODE_ENV == 'production'
  app.set('trust proxy', true)

app.use( cors() )


# ========== MAXMIND DATABASE SETUP
# load database
geodataCity = mmdbreader.openSync('./GeoLite2-City.mmdb')
geodata_info = {
  info: 'This product includes GeoLite2 data created by MaxMind, available from http:www.maxmind.com',
  db_datetime: "2015-11-29T09:56:08.358Z",
  db_unix_datetime: 1448790968358
}
geodata_cache = {}

get_formatted_ip_address_info = (ip_address)->
  result = geodataCity.getGeoDataSync(ip_address)
  if result
    formatted_result = result.location
    formatted_result.country_code = result?.country?.iso_code
    formatted_result.country_name = result?.country?.names?.en
  else
    null

get_geodata_info = (ip_address)->
  if ip_address
    if geodata_cache[ip_address]
      geodata_cache[ip_address]
    else
      result = get_formatted_ip_address_info(ip_address)
      geodata_cache[ip_address] = result
      result
  else
    null

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
  ip_address = req.ip
  ip_address = ip_address.split(":")[0] if ip_address
  ips = (req.ips.map (ip) -> ip.split(':')[0])
  JSON.stringify
    info: JSON.parse(my_api_info),
    result:
      direct_client_ip: req?.connection?.remoteAddress
      client_ip: ip_address || null,
      client_proxy_chain_ips: ips,
      server_unix_time: Date.now(),
      server_iso_time: new Date().toISOString(),
      headers: req.headers,
      geodata: get_geodata_info(ip_address),


app.get '/', (req, res) ->
  res.contentType('application/json')
  api_response = JSON.parse my_api_info
  api_response.usage =
    variable:"/var=variableName",
    json:"/api.json",
    callback:'/callback=functionName'
  res.send(JSON.stringify(api_response))

app.get '/*.json', (req, res) ->
  res.contentType('application/json')
  res.send createApiResponse req

app.get '/var=*', (req, res) ->
  res.contentType('application/javascript')
  res.send('var ' + req.params['0'] + ' = ' + createApiResponse(req) )

app.get '/callback=*', (req, res) ->
  res.contentType('application/javascript')
  res.send( req.params['0'] + '(' + createApiResponse(req, 'callback') + ');')

console.log('starting server...', server_ip_address, server_port)
server = app.listen( server_port, server_ip_address )