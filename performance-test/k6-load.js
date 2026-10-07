import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5252';

export default function () {
  const response = http.get(`${BASE_URL}/api/products`);

  check(response, {
    'status is successful': (r) => r.status >= 200 && r.status < 300,
    'response is below 1 second': (r) => r.timings.duration < 1000,
  });

  sleep(1);
}