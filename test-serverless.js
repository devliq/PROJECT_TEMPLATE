const handler = require('./src/index.js');

function createMockResponse() {
  return {
    statusCode: 200,
    headers: {},
    body: null,
    json(data) {
      this.body = JSON.stringify(data);
      this.headers['Content-Type'] = 'application/json';
      return this;
    },
    send(data) {
      this.body = data;
      return this;
    },
    setHeader(key, value) {
      // eslint-disable-next-line security/detect-object-injection
      this.headers[key] = value;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    end() {
      return this;
    },
  };
}

function createMockRequest(method, url) {
  return {
    method,
    url,
    headers: { 'x-forwarded-for': '127.0.0.1' },
    connection: { remoteAddress: '127.0.0.1' },
  };
}

function testRoute(name, req, expectedStatus) {
  console.log(`\nTesting ${name}`);
  const res = createMockResponse();
  handler(req, res);
  console.log(`Status: ${res.statusCode} (expected: ${expectedStatus})`);
  if (res.statusCode === expectedStatus) {
    console.log('✅ PASS');
  } else {
    console.log('❌ FAIL');
  }
  if (res.body) {
    console.log(`Response: ${res.body.substring(0, 100)}...`);
  }
}

console.log('Starting serverless function tests...');

testRoute('GET /', createMockRequest('GET', '/'), 200);
testRoute('GET /api/info', createMockRequest('GET', '/api/info'), 200);
testRoute(
  'GET /api/greet/John',
  createMockRequest('GET', '/api/greet/John'),
  200
);
testRoute('GET /api/health', createMockRequest('GET', '/api/health'), 200);
testRoute('GET /api/config', createMockRequest('GET', '/api/config'), 200);
testRoute('GET /package.json', createMockRequest('GET', '/package.json'), 200);
testRoute('GET /README.md', createMockRequest('GET', '/README.md'), 200);
testRoute('OPTIONS /', createMockRequest('OPTIONS', '/'), 200);
testRoute('POST /', createMockRequest('POST', '/'), 405);
testRoute('GET /invalid', createMockRequest('GET', '/invalid'), 404);

// Additional tests for edge cases
testRoute('GET /api/greet/', createMockRequest('GET', '/api/greet/'), 400); // Empty name
testRoute(
  'GET /api/greet/John@',
  createMockRequest('GET', '/api/greet/John@'),
  400
); // Invalid characters
testRoute(
  'GET /api/greet/John?appName=TestApp',
  createMockRequest('GET', '/api/greet/John?appName=TestApp'),
  200
); // With query param

console.log('\nTests completed!');
