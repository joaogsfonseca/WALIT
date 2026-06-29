# Walit

Aplicação de carteiras partilhadas (shared wallets) com gestão de membros, convites, premium e recuperação de conta.

- **Backend:** Node.js + Express + Prisma (PostgreSQL)
- **Frontend:** Flutter (Provider)

## Estrutura

```
backend/    API REST (auth, wallets, users)
frontend/   App Flutter (Android, iOS, Web, Desktop)
```

## Backend

### Requisitos
- Node.js 18+
- PostgreSQL

### Configuração
Criar `backend/.env` (não versionado):

```env
DATABASE_URL="postgresql://user:pass@localhost:5432/walit?schema=public"
JWT_SECRET="<gerar com: openssl rand -hex 48>"
PORT=3000
# Origens permitidas (separadas por vírgula). Vazio = todas (apenas dev).
CORS_ORIGIN="http://localhost:3000"
# SMTP (opcional; sem isto os emails são impressos na consola em modo dev)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="..."
SMTP_PASS="<App Password do Gmail>"
```

### Arrancar
```bash
cd backend
npm install
npx prisma migrate deploy   # ou: npx prisma migrate dev
npm run dev                 # nodemon
# ou: npm start
```

### Endpoints principais
- `POST /auth/signup` · `POST /auth/verify-email` · `POST /auth/resend-verification`
- `POST /auth/login` · `POST /auth/refresh-token` · `POST /auth/logout`
- `POST /auth/forgot-password` · `POST /auth/reset-password`
- `GET/POST /wallets` · `GET/PUT/DELETE /wallets/:id`
- `POST /wallets/:id/invite` · `POST /wallets/invite/accept` · `POST /wallets/:id/leave`
- `GET /users/profile` · `PUT /users/settings`

Os endpoints de autenticação têm rate limiting; rotas autenticadas usam um access token JWT (15 min) com rotação de refresh token.

## Frontend

```bash
cd frontend
flutter pub get
flutter run
```

O `api_service.dart` aponta para `localhost:3000` (web/iOS) e `10.0.2.2:3000` (emulador Android).
