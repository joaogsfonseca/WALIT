const axios = require('axios');

const API_URL = 'http://localhost:3000';

async function testProfileFlow() {
    try {
        const timestamp = Date.now();
        const email = `test_profile_${timestamp}@example.com`;
        const password = 'password123';
        const name = 'Profile Tester';

        console.log(`1. Initializing Test with user: ${email}`);

        // 1. Signup
        console.log('2. Signing up...');
        const signupRes = await axios.post(`${API_URL}/auth/signup`, {
            name,
            email,
            password
        });
        const token = signupRes.data.token;
        console.log('   Signup successful. Token received.');

        // 2. Fetch Profile
        console.log('3. Fetching Profile...');
        const profileRes = await axios.get(`${API_URL}/users/profile`, {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log('   Profile Response:', profileRes.data);

        // 3. Verification
        if (profileRes.data.email === email && profileRes.data.name === name) {
            console.log('SUCCESS: Profile data matches signup data.');
        } else {
            console.error('FAILURE: Profile data mismatch.');
            process.exit(1);
        }

    } catch (error) {
        console.error('TEST FAILED:', error.response ? error.response.data : error.message);
        process.exit(1);
    }
}

testProfileFlow();
