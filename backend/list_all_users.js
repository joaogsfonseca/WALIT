const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const users = await prisma.user.findMany({
        include: {
            wallet_memberships: {
                include: {
                    wallet: true
                }
            }
        }
    });

    console.log('=== All Users ===\n');

    if (users.length === 0) {
        console.log('No users in database');
        return;
    }

    users.forEach((user, index) => {
        console.log(`User ${index + 1}:`);
        console.log('  Email:', user.email);
        console.log('  Name:', user.name);
        console.log('  Premium:', user.premium_active);
        console.log('  Wallets:', user.wallet_memberships.length);

        if (user.wallet_memberships.length > 0) {
            user.wallet_memberships.forEach((m) => {
                console.log(`    - ${m.wallet.name} (${m.wallet.type}, ${m.wallet.currency}) - ${m.role}`);
            });
        }
        console.log('');
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
