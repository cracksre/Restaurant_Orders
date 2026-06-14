#!/bin/bash
# Load test script for Restaurant Ordering Assistant
# Simulates 500 concurrent Alexa sessions

set -e

API_ENDPOINT="${1}"
NUM_USERS="${2:-500}"
DURATION="${3:-300}"  # 5 minutes

if [ -z "$API_ENDPOINT" ]; then
    echo "Usage: ./load-test.sh <API_ENDPOINT> [NUM_USERS] [DURATION_SECONDS]"
    echo "Example: ./load-test.sh https://abc123.execute-api.us-east-1.amazonaws.com dev 500 300"
    exit 1
fi

echo "Starting load test..."
echo "Endpoint: $API_ENDPOINT"
echo "Users: $NUM_USERS"
echo "Duration: $DURATION seconds"

# Install k6 if not present
if ! command -v k6 &> /dev/null; then
    echo "k6 not found. Installing k6..."
    brew install k6  # macOS
fi

# Run load test
k6 run --vus $NUM_USERS --duration ${DURATION}s - <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 100 },
    { duration: '1m30s', target: __ENV.USERS || 500 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(99)<1500'],
    http_req_failed: ['<1%'],
  },
};

export default function () {
  const baseUrl = __ENV.BASE_URL || 'https://example.com';
  
  // Test menu endpoint
  let res = http.get(`${baseUrl}/menu`);
  check(res, {
    'menu status is 200': (r) => r.status === 200,
    'menu p99 latency < 1.5s': (r) => r.timings.duration < 1500,
  });
  
  sleep(1);
  
  // Test cart endpoint
  res = http.post(`${baseUrl}/cart`, JSON.stringify({
    sessionId: 'test-session-' + Math.random(),
    item: { name: 'Burger', price: 12.99, quantity: 1 }
  }));
  check(res, {
    'cart status is 200': (r) => r.status === 200,
  });
  
  sleep(1);
  
  // Test order endpoint
  res = http.post(`${baseUrl}/order`, JSON.stringify({
    sessionId: 'test-session-' + Math.random(),
    items: [{ name: 'Burger', price: 12.99, quantity: 1 }],
    total: 14.00
  }));
  check(res, {
    'order status is 200': (r) => r.status === 200,
  });
  
  sleep(1);
}
EOF

echo "Load test completed!"
