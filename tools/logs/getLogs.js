

const fs = require('fs');
const http = require("https");

var filename = 'xxx'
var domain = 'www.iie-systems.de'
var port = 3000
let rawdata = fs.readFileSync(filename);
var options = {
    'method': 'GET',
    'hostname': domain,
    'port': port,
    'path': '/loki/api/v1/query_range?query=xxx',
    'maxRedirects': 20
  };

function makeRequest(http_options, postData = '') {
    return new Promise((resolve, reject) => {
        const req = http.request(http_options, (res) => {
            var chunks = []
            res.on('data', (data) => {
                chunks.push(data);
            });
            req.on('error', err => {
                reject(err);
            });
            req.on('end', () => {
                resolve(Buffer.concat(chunks));
            });
        });
        if (postData != '') req.write(postData);
        req.end();
    });
}

async function run() {


}

run()
