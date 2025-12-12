const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3000';

async function test() {
    try {
        console.log("Registering...");
        const res = await fetch(`${BASE_URL}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: `test_${Date.now()}@test.com`, password: 'password', name: 'Test' })
        });
        console.log("Status:", res.status);
        if (!res.ok) {
            console.log("Text:", await res.text());
        } else {
            console.log("JSON:", await res.json());
        }
    } catch (e) {
        console.error("Error:", e);
    }
}
test();
