const nodemailer = require("nodemailer");

// Configuração de transporte (Simulação se não houver SMTP real)
// Para produção, usar variáveis de ambiente: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || "smtp.ethereal.email",
    port: process.env.SMTP_PORT || 587,
    secure: false, // true para 465, false para outras portas
    auth: {
        user: process.env.SMTP_USER || "fake_user",
        pass: process.env.SMTP_PASS || "fake_pass",
    },
});

const sendResetEmail = async (email, token) => {
    const resetLink = `http://localhost:3000/reset-password?token=${token}`;

    // Se não tivermos config real, apenas logamos na consola para dev
    if (!process.env.SMTP_HOST) {
        console.log("==========================================");
        console.log(`[DEV MODE] Enviar Email para: ${email}`);
        console.log(`[DEV MODE] Link de Recuperação: ${resetLink}`);
        console.log("==========================================");
        return;
    }

    try {
        await transporter.sendMail({
            from: '"Walit App" <no-reply@walit.app>',
            to: email,
            subject: "Recuperação de Password - Walit",
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px;">
                    <h2>Recuperação de Password</h2>
                    <p>Recebemos um pedido para recuperar a sua password.</p>
                    <p>Clique no link abaixo para criar uma nova password:</p>
                    <a href="${resetLink}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Recuperar Password</a>
                    <p><small>Se não pediu isto, ignore este email.</small></p>
                </div>
            `,
        });
        console.log(`Email de recuperação enviado para ${email}`);
    } catch (error) {
        console.error("Erro ao enviar email:", error);
    }
};



const sendInvitationEmail = async (email, token, inviterName, walletName) => {
    const inviteLink = `http://localhost:3000/invite/accept?token=${token}`; // Adjust for frontend URL later if needed

    // Dev Mode Logging
    if (!process.env.SMTP_HOST) {
        console.log("==========================================");
        console.log(`[DEV MODE] Invite Email to: ${email}`);
        console.log(`[DEV MODE] Wallet: ${walletName}, Inviter: ${inviterName}`);
        console.log(`[DEV MODE] Invite Link: ${inviteLink}`);
        console.log("==========================================");
        return;
    }

    try {
        await transporter.sendMail({
            from: '"Walit App" <no-reply@walit.app>',
            to: email,
            subject: `Convite para juntar-se à wallet ${walletName}`,
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px;">
                    <h2>Você foi convidado!</h2>
                    <p>${inviterName} convidou você para juntar-se à wallet <strong>${walletName}</strong>.</p>
                    <p>Clique no link abaixo para aceitar o convite:</p>
                    <a href="${inviteLink}" style="background-color: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Aceitar Convite</a>
                    <p><small>Se não conhece esta pessoa, ignore este email.</small></p>
                </div>
            `,
        });
        console.log(`Email de convite enviado para ${email}`);
    } catch (error) {
        console.error("Erro ao enviar email de convite:", error);
    }
};

const sendVerificationEmail = async (email, code) => {
    // Dev Mode Logging
    if (!process.env.SMTP_HOST) {
        console.log("==========================================");
        console.log(`[DEV MODE] Verification Email to: ${email}`);
        console.log(`[DEV MODE] CODE: ${code}`);
        console.log("==========================================");
        return;
    }

    try {
        await transporter.sendMail({
            from: '"Walit App" <no-reply@walit.app>',
            to: email,
            subject: "Confirme o seu email - Walit",
            html: `
                <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; padding: 40px; text-align: center; background-color: #f4f4f4;">
                    <div style="background-color: white; padding: 40px; border-radius: 10px; max-width: 500px; margin: 0 auto; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                        <h2 style="color: #333; margin-bottom: 20px;">Bem-vindo à Walit!</h2>
                        <p style="color: #666; font-size: 16px; margin-bottom: 30px;">Para garantir a segurança da sua conta, por favor introduza o código de verificação abaixo na aplicação.</p>
                        
                        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #2c3e50;">${code}</span>
                        </div>

                        <p style="color: #999; font-size: 14px;">Este código expira em 15 minutos.</p>
                    </div>
                </div>
            `,
        });
        console.log(`Email de verificação enviado para ${email}`);
    } catch (error) {
        console.error("Erro ao enviar email de verificação:", error);
    }
};

module.exports = { sendResetEmail, sendInvitationEmail, sendVerificationEmail };
