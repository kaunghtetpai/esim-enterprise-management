const axios = require('axios');

const BASE_URL = 'http://localhost:8000/api/v1/system';

async function testEndpoint(method, endpoint, data = null) {
  try {
    const config = {
      method,
      url: `${BASE_URL}${endpoint}`,
      timeout: 10000
    };
    
    if (data) config.data = data;
    
    const response = await axios(config);
    console.log(`✓ ${method} ${endpoint} - Status: ${response.status}`);
    console.log(`  Response: ${JSON.stringify(response.data, null, 2)}`);
    return true;
  } catch (error) {
    console.log(`✗ ${method} ${endpoint} - Error: ${error.message}`);
    if (error.response) {
      console.log(`  Status: ${error.response.status}`);
      console.log(`  Response: ${JSON.stringify(error.response.data, null, 2)}`);
    }
    return false;
  }
}

async function testAllEndpoints() {
  console.log('Testing System Monitoring API Endpoints\n');
  
  const tests = [
    ['GET', '/health', null],
    ['GET', '/status', null],
    ['GET', '/diagnostics', null],
    ['POST', '/auto-fix', {}],
    ['GET', '/errors', null],
    ['DELETE', '/errors', null]
  ];
  
  let passed = 0;
  let total = tests.length;
  
  for (const [method, endpoint, data] of tests) {
    console.log(`\n--- Testing ${method} ${endpoint} ---`);
    const success = await testEndpoint(method, endpoint, data);
    if (success) passed++;
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log(`\n=== Test Results ===`);
  console.log(`Passed: ${passed}/${total}`);
  console.log(`Success Rate: ${((passed/total)*100).toFixed(1)}%`);
}

testAllEndpoints().catch(console.error);