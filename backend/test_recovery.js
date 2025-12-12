const http = require('http');
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

const timestamp = Date.now();
const email = `recovery_test_${timestamp}@example.com`;
const oldPassword = 'oldPassword123';
const newPassword = 'newPassword456';

const signupData = JSON.stringify({
    name: 'Recovery Tester',
    email: email,
    password: oldPassword
});

const forgotData = JSON.stringify({
    email: email
});

function makeRequest(path, method, data) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: '/auth' + path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: body }));
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function runTest() {
    try {
        console.log("1. Creating User...");
        const signupRes = await makeRequest('/signup', 'POST', signupData);
        console.log(`   Status: ${signupRes.status}`);
        if (signupRes.status !== 201) throw new Error("Signup failed");

        console.log("2. Requesting Password Reset...");
        const forgotRes = await makeRequest('/forgot-password', 'POST', forgotData);
        console.log(`   Status: ${forgotRes.status}`);
        if (forgotRes.status !== 200) throw new Error("Forgot password request failed");

        console.log("3. Fetching Token from DB...");
        // Pequena pausa para garantir escrita
        await new Promise(r => setTimeout(r, 1000));

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user || !user.reset_token) throw new Error("Token not found in DB");
        console.log(`   Token Found: ${user.reset_token.substring(0, 5)}...`);

        console.log("4. Reseting Password...");
        const resetData = JSON.stringify({
            token: user.reset_token,
            newPassword: newPassword
        });
        const resetRes = await makeRequest('/reset-password', 'POST', resetData);
        console.log(`   Status: ${resetRes.status}`);
        if (resetRes.status !== 200) throw new Error("Reset password failed");

        console.log("5. Logging in with NEW Password...");
        const loginData = JSON.stringify({
            email: email,
            password: newPassword
        });
        const loginRes = await makeRequest('/login', 'POST', loginData);
        console.log(`   Status: ${loginRes.status}`);

        if (loginRes.status === 200) {
            console.log("SUCCESS! Account recovery flow verified.");
        } else {
            console.log("FAILED to login with new password.");
        }

    } catch (error) {
        console.error("TEST FAILED:", error.message);
    } finally {
        await prisma.$disconnect();
    }
}

// Aguardar servidor arrancar se for corrido logo a seguir
setTimeout(runTest, 2000);
