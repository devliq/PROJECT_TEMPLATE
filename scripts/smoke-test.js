#!/usr/bin/env node

/**
 * Smoke test script for Vercel deployment
 * Tests basic functionality of the deployed application
 */

const https = require('https');
const http = require('http');

const [, , deployUrl] = process.argv;

if (!deployUrl) {
  console.error('❌ Error: Deploy URL is required');
  console.error('Usage: node scripts/smoke-test.js <deploy-url>');
  process.exit(1);
}

console.log(`🚀 Running smoke tests against: ${deployUrl}`);

// Normalize URL
let url = deployUrl;
if (!url.startsWith('http://') && !url.startsWith('https://')) {
  url = `https://${url}`;
}

// Remove trailing slash
url = url.replace(/\/$/, '');

const tests = [
  {
    name: 'Health Check',
    path: '/health',
    expectedStatus: 200,
    timeout: 10000,
  },
  {
    name: 'API Status',
    path: '/api/status',
    expectedStatus: 200,
    timeout: 10000,
  },
  {
    name: 'Root Endpoint',
    path: '/',
    expectedStatus: 200,
    timeout: 10000,
  },
];

let passed = 0;
let failed = 0;

function makeRequest(test) {
  return new Promise(resolve => {
    const testUrl = `${url}${test.path}`;
    console.log(`Testing: ${test.name} - ${testUrl}`);

    const client = testUrl.startsWith('https://') ? https : http;

    const req = client.get(testUrl, { timeout: test.timeout }, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === test.expectedStatus) {
          console.log(`✅ ${test.name}: PASSED (${res.statusCode})`);
          resolve({ test, success: true, statusCode: res.statusCode, data });
        } else {
          console.log(
            `❌ ${test.name}: FAILED (Expected ${test.expectedStatus}, got ${res.statusCode})`
          );
          resolve({ test, success: false, statusCode: res.statusCode, data });
        }
      });
    });

    req.on('error', err => {
      console.log(`❌ ${test.name}: ERROR - ${err.message}`);
      resolve({ test, success: false, error: err.message });
    });

    req.on('timeout', () => {
      req.destroy();
      console.log(`❌ ${test.name}: TIMEOUT`);
      resolve({ test, success: false, error: 'Timeout' });
    });
  });
}

async function runTests() {
  for (const test of tests) {
    try {
      const result = await makeRequest(test);
      if (result.success) {
        passed++;
      } else {
        failed++;
      }
    } catch (error) {
      console.error(`❌ Unexpected error in ${test.name}:`, error);
      failed++;
    }
  }

  console.log('\n📊 Smoke Test Results:');
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(
    `📈 Success Rate: ${((passed / (passed + failed)) * 100).toFixed(1)}%`
  );

  if (failed > 0) {
    console.log('\n❌ Smoke tests failed!');
    process.exit(1);
  } else {
    console.log('\n✅ All smoke tests passed!');
    process.exit(0);
  }
}

runTests().catch(error => {
  console.error('❌ Fatal error running smoke tests:', error);
  process.exit(1);
});
