/**
 * Load Testing Script using k6
 * This script provides comprehensive load testing capabilities
 *
 * Usage: k6 run load-test.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users over 2 minutes
    { duration: '5m', target: 100 }, // Stay at 100 users for 5 minutes
    { duration: '2m', target: 200 }, // Ramp up to 200 users over 2 minutes
    { duration: '5m', target: 200 }, // Stay at 200 users for 5 minutes
    { duration: '2m', target: 0 },   // Ramp down to 0 users over 2 minutes
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate should be below 10%
  },
};

// Environment variables
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Test scenarios
export default function () {
  // Health check
  const healthResponse = http.get(`${BASE_URL}/health`);
  check(healthResponse, {
    'health check status is 200': (r) => r.status === 200,
    'health check response time < 200ms': (r) => r.timings.duration < 200,
  });
  errorRate.add(healthResponse.status !== 200);

  // API status check
  const statusResponse = http.get(`${BASE_URL}/api/status`);
  check(statusResponse, {
    'status check status is 200': (r) => r.status === 200,
    'status check response time < 300ms': (r) => r.timings.duration < 300,
  });
  errorRate.add(statusResponse.status !== 200);

  // Simulate user login (if endpoint exists)
  const loginPayload = JSON.stringify({
    email: `user${__VU}@example.com`,
    password: 'password123',
  });

  const loginResponse = http.post(`${BASE_URL}/api/auth/login`, loginPayload, {
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (loginResponse.status === 200) {
    const authToken = loginResponse.json().token;

    // Test authenticated endpoints
    const headers = {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    };

    // Get user profile
    const profileResponse = http.get(`${BASE_URL}/api/user/profile`, { headers });
    check(profileResponse, {
      'profile status is 200': (r) => r.status === 200,
      'profile response time < 500ms': (r) => r.timings.duration < 500,
    });
    errorRate.add(profileResponse.status !== 200);

    // Update user profile
    const updatePayload = JSON.stringify({
      bio: `Updated bio for user ${__VU}`,
    });

    const updateResponse = http.put(`${BASE_URL}/api/user/profile`, updatePayload, { headers });
    check(updateResponse, {
      'update profile status is 200': (r) => r.status === 200,
      'update profile response time < 1000ms': (r) => r.timings.duration < 1000,
    });
    errorRate.add(updateResponse.status !== 200);
  }

  // Simulate data retrieval with different query patterns
  const queries = [
    `${BASE_URL}/api/data?page=1&limit=10`,
    `${BASE_URL}/api/data?page=2&limit=20`,
    `${BASE_URL}/api/data?search=test&limit=5`,
  ];

  queries.forEach((url) => {
    const response = http.get(url);
    check(response, {
      'data query status is 200': (r) => r.status === 200,
      'data query response time < 1000ms': (r) => r.timings.duration < 1000,
    });
    errorRate.add(response.status !== 200);
  });

  // Simulate file upload (if endpoint exists)
  const fileData = {
    file: http.file('test file content', 'test.txt', 'text/plain'),
  };

  const uploadResponse = http.post(`${BASE_URL}/api/upload`, fileData);
  check(uploadResponse, {
    'upload status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    'upload response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  errorRate.add(uploadResponse.status !== 200 && uploadResponse.status !== 201);

  // Random sleep to simulate user think time
  sleep(Math.random() * 3 + 1); // 1-4 seconds
}

// Setup function - runs before the test starts
export function setup() {
  console.log('🚀 Starting load test setup...');

  // Warm up the application
  const warmupResponse = http.get(`${BASE_URL}/health`);
  if (warmupResponse.status !== 200) {
    console.error('❌ Application is not healthy. Aborting test.');
    return;
  }

  console.log('✅ Application is healthy. Starting load test...');
  return { baseUrl: BASE_URL };
}

// Teardown function - runs after the test completes
export function teardown(data) {
  console.log('🏁 Load test completed');
  console.log(`📊 Test results for: ${data.baseUrl}`);
}

// Handle summary - custom summary output
export function handleSummary(data) {
  const summary = {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'performance-report.json': JSON.stringify(data, null, 2),
    'performance-summary.html': htmlReport(data),
  };

  return summary;
}

function textSummary(data, options) {
  return `
📊 Load Test Summary
==================

Test Duration: ${data.metrics.iteration_duration.values.avg}ms avg iteration
Total Requests: ${data.metrics.http_reqs.values.count}
Failed Requests: ${data.metrics.http_req_failed.values.rate * 100}%

Response Time Statistics:
  Average: ${Math.round(data.metrics.http_req_duration.values.avg)}ms
  95th percentile: ${Math.round(data.metrics.http_req_duration.values['p(95)'])}ms
  99th percentile: ${Math.round(data.metrics.http_req_duration.values['p(99)'])}ms

HTTP Status Distribution:
${Object.entries(data.metrics.http_req_duration_by_status_class || {})
  .map(([status, values]) => `  ${status}: ${values.count} requests`)
  .join('\n')}

Custom Metrics:
  Error Rate: ${(data.metrics.errors?.values.rate * 100 || 0).toFixed(2)}%
  Custom Response Time: ${Math.round(data.metrics.response_time?.values.avg || 0)}ms
`;
}

function htmlReport(data) {
  return `
<!DOCTYPE html>
<html>
<head>
    <title>Load Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>🚀 Load Test Report</h1>
    <div class="metric">
        <h3>Test Overview</h3>
        <p><strong>Total Requests:</strong> ${data.metrics.http_reqs.values.count}</p>
        <p><strong>Failed Requests:</strong> ${data.metrics.http_req_failed.values.rate * 100}%</p>
        <p><strong>Average Response Time:</strong> ${Math.round(data.metrics.http_req_duration.values.avg)}ms</p>
    </div>

    <div class="metric">
        <h3>Response Time Percentiles</h3>
        <p><strong>95th percentile:</strong> ${Math.round(data.metrics.http_req_duration.values['p(95)'])}ms</p>
        <p><strong>99th percentile:</strong> ${Math.round(data.metrics.http_req_duration.values['p(99)'])}ms</p>
    </div>

    <div class="metric">
        <h3>Status Codes</h3>
        ${Object.entries(data.metrics.http_req_duration_by_status_class || {})
          .map(([status, values]) => `<p><strong>${status}:</strong> ${values.count} requests</p>`)
          .join('')}
    </div>
</body>
</html>
`;
}