//nodejs-geodata-analitics-api
//v.0.1.0

//dependencies
var express = require('express');
var app = express();
var mmdbreader = require('maxmind-db-reader');

//this api is hosted at openshift.com
var server_port = process.env.OPENSHIFT_NODEJS_PORT || 8080;
var server_ip_address = process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1';

//openshift is serving node behind proxy
app.set('trust proxy', process.env.OPENSHIFT_NODEJS_IP );

//load database
var geodataCity = mmdbreader.openSync('./GeoLite2-City.mmdb');

//api statistic counter, for now until server restart...
var apiHitCounter = {json:0, variable: 0, callback:0};

function createApiResponse(req, api_type){
	var api = {
		api_name:'api.iPePe.pl WebAPI for Web analysis and statistics',
		api_version:'0.0.1',
		api_github:'https://github.com/ipepe/nodejs-geodata-analitics-api',
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
	var response = {usage:{variable:"/var=variableName",json:"/api.json",callback:'/callback=functionName'}}
	res.contentType('application/json');
	res.send(JSON.stringify(response));
});

app.get('/api.json', function (req, res) {
	res.contentType('application/json');
	res.send(createApiResponse(req, 'json'));
});

app.get('/var=*', function (req, res) {
	res.contentType('application/json');
	res.send('var ' + req.params['0'] + ' = ' + createApiResponse(req, 'variable') );
});
app.get('/callback=*', function (req, res) {
	res.contentType('application/json');
	res.send( req.params['0'] + '(' + createApiResponse(req, 'callback') + ');' );
});

var server = app.listen( server_port, server_ip_address );