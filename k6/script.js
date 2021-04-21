//start init code -  run exactly once, import and file reade are here and k6 know what to send where in cloud mode thanks to that
//you can't load anything from your local filesystem, or import any other modules anywhere else. This all has to be done from the init code.
import {check, group} from 'k6';
import {textSummary} from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import {Gauge, Trend} from 'k6/metrics';
import * as AUT from './app.js';
import {logPadded, RequestBuilder, logResponseDetails } from './helpers.js';

const PROTOCOL = __ENV.PROTOCOL || 'https';
const AUT_HOSTNAME = __ENV.AUT_HOSTNAME || 'httpbin.test.k6.io';
const BASE_URL = `${PROTOCOL}://${AUT_HOSTNAME}`;

export let SampleTrend = new Trend('Sample Trend');
export let SampleTrend2 = new Trend('Sample Trend 2');
export let GaugeTotalTime = new Gauge('Total time');
const rb = new RequestBuilder(BASE_URL);
const sampleFile = JSON.parse(open("./test_documents/" + __ENV.SAMPLE_FILE));

let Scenario1 = {
  scenarios: {
    tr: {
      executor: 'per-vu-iterations',
      exec: 'Scenario1',
      vus: __ENV.VUS,
      iterations: __ENV.ITERATIONS || 1,
    }
  }
}
export let options = eval(__ENV.SCENARIO)

//A big difference between the init stage and setup/teardown stages is that you have the full k6 API available in the latter, you can for example make HTTP requests in the setup and teardown stages:
export function setup() { //setup code - returns data and only data as JSON, run once for a test, exported function goes to k6
  logTestConfig();
  logPadded("Contents of file: " + sampleFile[0].user);
  let data = {
    somedata: 'somedata',
  }
  if (__ENV.SCENARIO == 'Scenario1') {
    logPadded('Some data' + data.somedata);
  }
  data["testStartTimeMs"] = new Date().getTime();
  logPadded(' ')
  return data
}

export function teardown(data) { //teardown code
  let testEndTimeMs = new Date().getTime();
  let testDurationMs = testEndTimeMs - data["testStartTimeMs"];
  logPadded('Tearing down ..');
  logPadded(`Test duration [s]..${testDurationMs / 1000}`)
  GaugeTotalTime.add(testDurationMs);
}

export function Scenario1(data) {
  let contractId, versionId, documentId = null;
  group('Full Iteration', function () {
    let startIteration = new Date();
    group('Sample', function () {
      let start = new Date();
      let res = postName();
      let end = new Date();
      SampleTrend2.add((end.getTime() - start.getTime()) / 1000);
    });
    let endIteration = new Date();
    SampleTrend.add((endIteration.getTime() - startIteration.getTime()) / 1000);
  });
}

export function handleSummary(data) {
  logPadded('Preparing the end-of-test summary...');
  return {
    './results/summary.json': JSON.stringify(data, null, 2), // and a JSON with all the details...
    'stdout': textSummary(data, {indent: ' ', enableColors: true}), // Show the text summary to stdout...

  }
}

//----------------------------------------------------------------
function logTestConfig() {
  logPadded('Setting up test ...')
  logPadded(`AUT_HOSTNAME: ${__ENV.AUT_HOSTNAME}`)
  logPadded(`SCENARIO: ${__ENV.SCENARIO}`)
}

//Creat and use a builder for requests
function postName() {
  logPadded("/GET " + AUT_HOSTNAME);
  let post_api = new AUT.POST_API();
  let req = rb.setAPI(post_api)
    .replaceInURL('{{post}}', 'post')
    .replaceInJSONBody('{{name}}','Gabriel')
    .addHeader('Content-Type', 'application/json')
    .replaceInHeaders('{{Bearer}}','MyToken')

  let res = req.send();
  let pass = check(res, {
    'Request returns HTTP 200 OK': (r) => res.status === 200,
  });

  logPadded(JSON.stringify(rb.toString(), null, 2));
  logResponseDetails(res);
  return res;
}

