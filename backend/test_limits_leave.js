const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3001'; // Assuming port 3001 based on previous runs

async function runTest() {
    try {
        console.log('--- Starting Wallet Limits & Leave Verification ---');

        // 1. Register Free User
        const emailFree = `free_${Date.now()}@test.com`;
        const password = 'password123';
        console.log(`Registering Free User: ${emailFree}`);
        const resFree = await fetch(`${BASE_URL}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: emailFree, password, name: 'Free User' })
        });
        const dataFree = await resFree.json();
        const tokenFree = dataFree.token;

        // 2. Create Wallet 1 (Should succeed)
        console.log('Creating Wallet 1...');
        const resW1 = await fetch(`${BASE_URL}/wallets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenFree}` },
            body: JSON.stringify({ name: 'Wallet 1', type: 'Personal', currency: 'USD' })
        });
        if (resW1.status !== 201) throw new Error('Failed to create Wallet 1');
        const w1 = await resW1.json();
        console.log('Wallet 1 created:', w1.id);

        // 3. Create Wallet 2 (Should succeed)
        console.log('Creating Wallet 2...');
        const resW2 = await fetch(`${BASE_URL}/wallets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenFree}` },
            body: JSON.stringify({ name: 'Wallet 2', type: 'Personal', currency: 'USD' })
        });
        if (resW2.status !== 201) throw new Error('Failed to create Wallet 2');
        console.log('Wallet 2 created');

        // 4. Create Wallet 3 (Should fail - Limit 2)
        console.log('Creating Wallet 3 (Should fail)...');
        const resW3 = await fetch(`${BASE_URL}/wallets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenFree}` },
            body: JSON.stringify({ name: 'Wallet 3', type: 'Personal', currency: 'USD' })
        });
        if (resW3.status === 403) {
            console.log('SUCCESS: Blocked creation of 3rd wallet.');
        } else {
            console.error('FAILURE: Allowed creation of 3rd wallet or unexpected status', resW3.status);
        }

        // 5. Test Leave Wallet
        console.log('Testing Leave Wallet from Wallet 1...');
        // Owner cannot leave, so for this test owner must delete or we need another user.
        // Wait, requirements say "Sair de uma wallet".
        // My implementation blocks OWNER from leaving.
        // Let's create another user, invite them to Wallet 1, and have them leave.

        const emailMember = `member_${Date.now()}@test.com`;
        const resMember = await fetch(`${BASE_URL}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: emailMember, password, name: 'Member' })
        });
        const dataMember = await resMember.json();
        const tokenMember = dataMember.token;

        // Invite Member to Wallet 1
        const resInvite = await fetch(`${BASE_URL}/wallets/${w1.id}/invite`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenFree}` },
            body: JSON.stringify({ email: emailMember })
        });
        const dInvite = await resInvite.json();

        // Accept
        await fetch(`${BASE_URL}/wallets/invite/accept`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenMember}` },
            body: JSON.stringify({ token: dInvite.token })
        });
        console.log('Member joined Wallet 1');

        // Member Leaves
        console.log('Member leaving Wallet 1...');
        const resLeave = await fetch(`${BASE_URL}/wallets/${w1.id}/leave`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${tokenMember}` }
        });
        if (resLeave.status === 200) {
            console.log('SUCCESS: Member left wallet.');
        } else {
            console.log('FAILURE: Member failed to leave', await resLeave.text());
        }

        // Verify member is gone
        const resCheck = await fetch(`${BASE_URL}/wallets/${w1.id}`, {
            headers: { 'Authorization': `Bearer ${tokenMember}` }
        });
        if (resCheck.status === 403 || resCheck.status === 404) {
            console.log('SUCCESS: Member no longer has access.');
        } else {
            console.log('FAILURE: Member still has access.');
        }

        console.log('--- Verification Complete ---');

    } catch (error) {
        console.error('Test failed:', error);
    }
}

runTest();
