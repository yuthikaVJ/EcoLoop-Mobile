import http from 'k6/http';
import { check, sleep } from 'k6';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

export const options = {
  stages: [
    { duration: '15s', target: 5 },
    { duration: '45s', target: 25 },
    { duration: '15s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
    checks: ['rate>0.95'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://70.153.136.178:5252';
const searchTerms = ['box', 'plastic', 'paper', 'metal'];

export default function () {
  const search = searchTerms[__ITER % searchTerms.length];
  const url =
    `${BASE_URL}/api/products?search=${encodeURIComponent(search)}` +
    '&sort=newest&page=1&pageSize=20';

  const response = http.get(url, {
    tags: { endpoint: 'product-search' },
  });

  check(response, {
    'product search succeeds': (r) => r.status === 200,
    'product search response is JSON': (r) =>
      r.headers['Content-Type']?.includes('application/json'),
    'product search response is below 1 second': (r) =>
      r.timings.duration < 1000,
  });

  sleep(1);
}

export function handleSummary(data) {
  return {
    'results/k6-product-search-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
