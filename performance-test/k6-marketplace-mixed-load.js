import http from 'k6/http';
import { check, sleep } from 'k6';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

export const options = {
  scenarios: {
    browse_products: {
      executor: 'constant-arrival-rate',
      rate: 8,
      timeUnit: '1s',
      duration: '60s',
      preAllocatedVUs: 10,
      maxVUs: 50,
      exec: 'browseProducts',
    },
    browse_categories: {
      executor: 'constant-arrival-rate',
      rate: 3,
      timeUnit: '1s',
      duration: '60s',
      preAllocatedVUs: 5,
      maxVUs: 20,
      exec: 'browseCategories',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
    'http_req_duration{endpoint:product-list}': ['p(95)<1000'],
    'http_req_duration{endpoint:category-list}': ['p(95)<1000'],
    checks: ['rate>0.95'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://70.153.136.178:5252:5252';

function verify(response, endpoint) {
  check(response, {
    [`${endpoint} request succeeds`]: (r) => r.status === 200,
    [`${endpoint} response is JSON`]: (r) =>
      r.headers['Content-Type']?.includes('application/json'),
    [`${endpoint} response is below 1 second`]: (r) =>
      r.timings.duration < 1000,
  });
}

export function browseProducts() {
  const response = http.get(
    `${BASE_URL}/api/products?sort=newest&page=1&pageSize=20`,
    { tags: { endpoint: 'product-list' } }
  );
  verify(response, 'product list');
}

export function browseCategories() {
  const response = http.get(`${BASE_URL}/api/product-categories`, {
    tags: { endpoint: 'category-list' },
  });
  verify(response, 'category list');
}

export function handleSummary(data) {
  return {
    'results/k6-marketplace-mixed-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
