// ========== DEPENDENCIES
var app = require('express')();
var cors = require('cors');
var request = require('request');

// ========== CONFIGURATION
var API_KEY = process.env.API_KEY || 'dev';
var PORT = process.env.PORT || 4000;

// ========== SETUP EXPRESS
// openshift is serving node behind proxy
if (process.env.OPENSHIFT_NODEJS_IP) {
    app.set('trust proxy', process.env.OPENSHIFT_NODEJS_IP);
} else if (process.env.NODE_ENV === 'production') {
    app.set('trust proxy', true);
}

app.use(cors());

// ========== App Logic
app.get('/*', function(req, res) {
    if((req.query['key'] === API_KEY) && req.query['url']){
        res.contentType('application/json');
        var options = {
            url: new Buffer(req.query['url'], 'base64').toString()
        };
        if (req.query['headers']) {
            options.headers = JSON.parse(req.query['headers']);
        }
        return request(options, function(error, response) {
            return res.send(JSON.stringify({
                error: error,
                response: response
            }));
        });
    }else{
        res.status(404).send('Not found')
    }
});

// ========== App Start
console.log('starting server...', PORT, API_KEY);
var server = app.listen(PORT);
console.log('server started');
