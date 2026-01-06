# ---------- BUILD STAGE ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Install deps first (cache-friendly)
COPY package*.json ./
RUN npm install

# Copy source
COPY . .

# Prisma client
# ARG DATABASE_URL
# ENV DATABASE_URL=$DATABASE_URL
ENV DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy"
RUN npx prisma generate

# Build TS → JS
RUN npm run build


# ---------- RUN STAGE ----------
FROM node:20-alpine

WORKDIR /app

# Copy only what is needed
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./      
# Do not do: COPY --from=builder /app/dist ./dist   // bcz prisma need prisma.config.js file at root with prisma folder
# But in local dev we can have inside dist folder as Bcz Prisma CLI resolves config relative to the execution context, not strictly project root
# and local setup accidentally satisfied the resolution rules. so it worked in local but failed in docker.
COPY --from=builder /app/prisma ./prisma
COPY package*.json ./
 
ENV NODE_ENV=production

EXPOSE 3000

# CMD ["node", "src/server.js"] for: without docker compose file
CMD ["sh", "-c", "npx prisma migrate deploy && node src/server.js"]
