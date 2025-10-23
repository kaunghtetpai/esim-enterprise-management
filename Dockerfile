FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
COPY frontend/package*.json ./frontend/
COPY backend/package*.json ./backend/

RUN npm ci
RUN cd frontend && npm ci
RUN cd backend && npm ci

COPY . .
RUN npm run build

FROM node:18-alpine AS production

WORKDIR /app
COPY --from=builder /app/backend/dist ./backend/dist
COPY --from=builder /app/frontend/build ./frontend/build
COPY --from=builder /app/backend/package*.json ./backend/
COPY --from=builder /app/backend/node_modules ./backend/node_modules

EXPOSE 8000

CMD ["node", "backend/dist/server.js"]