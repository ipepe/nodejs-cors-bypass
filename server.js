//nodejs-geodata-analitics-api
var this_api_version = '0.1.1';

// ========== DEPENDENCIES
var express = require('express');
var app = express();
var mmdbreader = require('maxmind-db-reader');
var cors = require('cors');
var app = express();

//========== CONFIGURATION
//this api is hosted at openshift.com
var server_port = process.env.OPENSHIFT_NODEJS_PORT || 8080;
var server_ip_address = process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1';

// ========== SETUP EXPRESS
//openshift is serving node behind proxy
app.set('trust proxy', process.env.OPENSHIFT_NODEJS_IP );

// cors setup
app.use( cors() );

//json contentType
app.use(function(req, res, next) {
	res.contentType('application/json');
	next();
});

//========== MAXMIND DATABASE SETUP
//load database
var geodataCity = mmdbreader.openSync('./GeoLite2-City.mmdb');

// ========== MY APP VARIABLES
//api statistic counter, for now until server restart...
var apiHitCounter = {json:0, variable: 0, callback:0};

//========== APP CODE
function createApiResponse(req, api_type){
	var api = {
		api_name: 'api.iPePe.pl WebAPI for Web analysis and statistics',
		api_version: this_api_version,
		api_github: 'https://github.com/ipepe/nodejs-geodata-analitics-api',
		api_hit_count: apiHitCounter,
		result: {}
	};
	api.api_hit_count[api_type]++;

	api.result.ip = req.ip;
	api.result.ips = req.ips;
	api.result.useragent = req.headers['user-agent'];
	api.result.language = req.headers['accept-language'];
	api.result.referer =  req.headers.referrer || req.headers.referer;
	
	api.result.geodata = { 
		info:'This product includes GeoLite2 data created by MaxMind, available from http://www.maxmind.com',
		db_datetime:'2015-02-19T01:53:23.236Z',
		db_unix_datetime:1424310803236
	};
	api.result.geodata.result = geodataCity.getGeoDataSync(api.result.ip);
	return JSON.stringify(api);
}

app.get('/', function (req, res) {
	var response = {
		api_name: 'api.iPePe.pl WebAPI for Web analysis and statistics',
		api_version: this_api_version,
		api_github: 'https://github.com/ipepe/nodejs-geodata-analitics-api',
		usage:{
			variable:"/var=variableName",
			json:"/api.json",
			callback:'/callback=functionName'
		}
	}
	res.send(JSON.stringify(response));
});

app.get('/api.json', function (req, res) {
	res.send(createApiResponse(req, 'json'));
});

app.get('/var=*', function (req, res) {
	res.send('var ' + req.params['0'] + ' = ' + createApiResponse(req, 'variable') );
});
app.get('/callback=*', function (req, res) {
	res.send( req.params['0'] + '(' + createApiResponse(req, 'callback') + ');' );
});

var server = app.listen( server_port, server_ip_address );