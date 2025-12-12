const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3001';

async function runTest() {
    try {
        console.log('--- Starting Wallet Verification ---');

        // 1. Register User A (Owner)
        const emailA = `owner_${Date.now()}@test.com`;
        const password = 'password123';
        console.log(`Registering Owner: ${emailA}`);
        const resA = await fetch(`${BASE_URL}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: emailA, password, name: 'Owner' })
        });

        if (!resA.ok) {
            const text = await resA.text();
            throw new Error(`Register Owner failed: ${resA.status} ${text}`);
        }

        const dataA = await resA.json();
        const tokenA = dataA.token;
        if (!tokenA) throw new Error('Failed to register Owner');

        // 2. Register User B (Invitee)
        const emailB = `invitee_${Date.now()}@test.com`;
        console.log(`Registering Invitee: ${emailB}`);
        const resB = await fetch(`${BASE_URL}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: emailB, password, name: 'Invitee' })
        });
        const dataB = await resB.json();
        const tokenB = dataB.token;
        if (!tokenB) throw new Error('Failed to register Invitee');

        // 3. Create Wallet
        console.log('Owner creating generic wallet...');
        const resWallet = await fetch(`${BASE_URL}/wallets`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${tokenA}`
            },
            body: JSON.stringify({ name: 'Family Budget', type: 'Personal', currency: 'USD' })
        });
        const wallet = await resWallet.json();
        console.log('Wallet created:', wallet.id);

        // 4. Invite User B
        console.log('Inviting User B...');
        const resInvite = await fetch(`${BASE_URL}/wallets/${wallet.id}/invite`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${tokenA}`
            },
            body: JSON.stringify({ email: emailB })
        });
        const inviteData = await resInvite.json();
        // Since we are in dev mode (no SMTP), the token should be returned
        const inviteToken = inviteData.token;
        if (!inviteToken) throw new Error('Failed to get invite token (ensure dev mode returns it)');
        console.log('Invitation sent, token:', inviteToken);

        // 5. User B Accepts Invitation
        console.log('User B accepting invitation...');
        const resAccept = await fetch(`${BASE_URL}/wallets/invite/accept`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${tokenB}`
            },
            body: JSON.stringify({ token: inviteToken })
        });
        const acceptData = await resAccept.json();
        console.log('Accept response:', acceptData);

        // 6. Verify Membership (User B should see the wallet now)
        console.log('Verifying membership for User B...');
        const resGetWallet = await fetch(`${BASE_URL}/wallets/${wallet.id}`, {
            headers: { 'Authorization': `Bearer ${tokenB}` }
        });
        if (resGetWallet.status === 200) {
            console.log('User B invoked getWallet successfully -> Membership confirmed.');
        } else {
            console.error('User B failed to get wallet:', await resGetWallet.text());
        }

        console.log('--- Verification Complete ---');

    } catch (error) {
        console.error('Test failed:', error);
    }
}

runTest();
