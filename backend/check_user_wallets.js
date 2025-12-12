const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const user = await prisma.user.findUnique({
        where: { email: 'joaoteste@gmail.com' },
        include: {
            wallet_memberships: {
                include: {
                    wallet: true
                }
            }
        }
    });

    if (!user) {
        console.log('User not found');
        return;
    }

    console.log('=== User Info ===');
    console.log('Name:', user.name);
    console.log('Email:', user.email);
    console.log('Premium:', user.premium_active);

    console.log('\n=== Wallets ===');
    if (user.wallet_memberships.length === 0) {
        console.log('No wallets found');
    } else {
        user.wallet_memberships.forEach((membership, index) => {
            console.log(`\nWallet ${index + 1}:`);
            console.log('  ID:', membership.wallet.id);
            console.log('  Name:', membership.wallet.name);
            console.log('  Type:', membership.wallet.type);
            console.log('  Currency:', membership.wallet.currency);
            console.log('  Role:', membership.role);
            console.log('  Created:', membership.wallet.created_at);
        });
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
