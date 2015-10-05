/**
 * Copyright 2014 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

var express = require('express'),
    app = express(),
    server = require('http').createServer(app),
    fs = require('fs'),
    bluemix = require('./config/bluemix'),
    watson = require('watson-developer-cloud'),
    extend = require('util')._extend,
    UAparser = require('ua-parser-js'),
    userAgentParser = new UAparser();

//---Deployment Tracker---------------------------------------------------------
require("cf-deployment-tracker-client").track();

// setup express
require('./config/express')(app);
 
// if you're running locally (not on bluemix) set your auth credentials
// if you're on bluemix, pull auth credentials from VCAP environment
var qa_credentials = {
    username:'qa username',
    password:'qa password'
};
var stt_credentials = {
    username:'stt username',
    password:'stt password'
};

if (process.env.hasOwnProperty("VCAP_SERVICES")) {
    // Running on Bluemix. Parse out the port and host that we've been assigned.
    var env = JSON.parse(process.env.VCAP_SERVICES);
    var host = process.env.VCAP_APP_HOST; 
    var port = process.env.VCAP_APP_PORT;
   
    qa_credentials = env['question_and_answer'][0].credentials;  
    stt_credentials = env['speech_to_text'][0].credentials;  
}

qa_credentials.version = 'v1';
qa_credentials.dataset = 'healthcare';
stt_credentials.version = 'v1';


// setup watson services
var question_and_answer_healthcare = watson.question_and_answer(qa_credentials);
var speechToText = watson.speech_to_text(stt_credentials);

// render index page
app.get('/', function(req, res){
    res.render('index');
});

// render index page
app.get('/tos', function(req, res){
    res.render('tos');
});



// Handle the form POST containing an audio file and return transcript (from mobile)
app.post('/transcribe', function(req, res){
    
    var file = req.files.audio;
    var readStream = fs.createReadStream(file.path);
    console.log("opened stream for " + file.path);
    
    var params = {
        audio:readStream,
        content_type:'audio/l16; rate=8000; channels=1',
        continuous:"true"
    };
         
    speechToText.recognize(params, function(err, response) {
        
        readStream.close();
        
        if (err) {
            return res.status(err.code || 500).json(err);
        } else {
            var result = {};
            if (response.results.length > 0) {
                var finalResults = response.results.filter( isFinalResult );
                
                if ( finalResults.length > 0 ) {
                   result = finalResults[0].alternatives[0];
                }
            }
            return res.send( result );
        }
    });
});

function isFinalResult(value) {
    return value.final == true;
}

//handle QA query and return json result (for mobile)
app.get('/ask', function(req, res){
    
    var query = req.query.query;
    
    if ( query != undefined ) {
        question_and_answer_healthcare.ask({ text: query}, function (err, response) {
            if (err){
                return res.status(err.code || 500).json(response);
            } else {
                if (response.length > 0) {
                    var answers = [];
                    
                    for (var x=0; x<response[0].question.evidencelist.length; x++) {
                        var item = {};
                        item.text = response[0].question.evidencelist[x].text;
                        item.value = response[0].question.evidencelist[x].value;
                        answers.push(item);
                    }
                    
                    var result = {
                        answers:answers
                    };
                	return res.send( result );
                }
                return res.send({});
            }
        });
    }
    else {
        return res.status(500).send('Bad Query');
    }
});


// Start server
var port = (process.env.VCAP_APP_PORT || 3000);
server.listen(port);
console.log('listening at:', port);
