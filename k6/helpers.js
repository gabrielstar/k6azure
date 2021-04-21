import http from 'k6/http';

const PAD = 90;

export class RequestBuilder {
  constructor(baseURL = '', url = '') {
    this.baseURL = baseURL;
    this.url = url;
    this.body = {};
    this.method = 'GET';
    this.params = {
      timeout: '60s',
      headers: {}
    };
  }

  setUrl(url) {
    this.url = url;
    return this;
  }
  setAPI(API){
    this.url = API.url;
    this.params.headers = API.headers;
    this.body = API.body;
    this.method = API.method;
    return this;
  }
  setMethod(method) {
    this.method = method;
    return this;
  }

  withPOST() {
    this.setMethod('POST');
    return this;
  }

  withPUT() {
    this.setMethod('PUT');
    return this;
  }

  withGET() {
    this.setMethod('GET');
    return this;
  }
  resetHeaders(){
    this.params.headers = {}
    return this;
  }
  setHeaders(headers) {
    this.params.headers = headers;
    return this;
  }

  addHeader(headerName, headerValue) {
    this.params.headers[headerName] = headerValue;
    return this;
  }

  deleteHeader(headerName) {
    delete this.params.headers[headerName];
    return this;
  }

  setBody(body) {
    this.body = body;
    return this;
  }

  replaceInURL(key, value) {
    this.url = this.url.replace(key, value);
    return this;
  }

  replaceInJSONBody(key, value) {
    this.body = JSON.parse(JSON.stringify(this.body).replace(key, value));
    return this;
  }
  replaceInHeaders(key, value) {
    this.params.headers = JSON.parse(JSON.stringify(this.params.headers).replace(key, value));
    return this;
  }
  toString() {
    return {
      url: this.baseURL + this.url,
      method: this.method,
      body: this.body,
      params: this.params,
    }
  }

  send() {
    return http.request(this.method, this.baseURL + this.url, this.body, this.params);
  }
}

export function logPadded(string, padding = PAD) {
  console.log(string.padEnd(padding));
};

export function logResponseDetails(res, id = "") {
  logPadded( res.body);
  logPadded(` ${id} resp status : ` + res.status);
  logPadded(` ${id} req url: ` + ` ${res.request.method} ` + res.request.url);
  logPadded(` ${id} req body: ` + JSON.stringify(res.request.body,null,2));
}
