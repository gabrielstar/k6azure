const defaultHeaders = {
  header1: 'header1',
  Bearer: '{{Bearer}}',
};

class BaseAPI {
  get method() {
    return this._method;
  }

  set method(value) {
    this._method = value;
  }

  get body() {
    return this._body;
  }

  set body(value) {
    this._body = value;
  }

  get headers() {
    return this._headers;
  }

  set headers(value) {
    this._headers = value;
  }

  get url() {
    return this._url;
  }

  set url(value) {
    this._url = value;
  }

  constructor(url = defaultHeaders) {
    this._url = url;
    this._headers = defaultHeaders
    this._body = '';
    this._method = 'GET';

  }
}

export class POST_API extends BaseAPI {
  constructor(url = '/{{post}}') {
    super(url);
    this.body = {
      name: '{{name}}'
    };
    this.method = 'POST';
  }
}
