import http from 'k6/http';
import { check, sleep } from 'k6';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

export const options = {
  stages: [
    { duration: '15s', target: 10 },
    { duration: '45s', target: 10 },
    { duration: '15s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
    checks: ['rate>0.95'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://70.153.136.178:5252:5252';

export default function () {
  const response = http.get(`${BASE_URL}/api/product-categories`, {
    tags: { endpoint: 'product-categories' },
  });

  check(response, {
    'category request succeeds': (r) => r.status === 200,
    'category response is JSON': (r) =>
      r.headers['Content-Type']?.includes('application/json'),
    'category response is below 1 second': (r) =>
      r.timings.duration < 1000,
  });

  sleep(1);
}

export function handleSummary(data) {
  return {
    'results/k6-category-load-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
