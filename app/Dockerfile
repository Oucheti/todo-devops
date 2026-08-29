```dockerfile
# =========================
# Stage 1 : Installation
# =========================
FROM node:20-alpine AS dependencies

WORKDIR /app

# Installer uniquement les dépendances nécessaires
COPY package*.json ./

RUN npm ci --omit=dev


# =========================
# Stage 2 : Image finale
# =========================
FROM node:20-alpine

WORKDIR /app

# Environnement production
ENV NODE_ENV=production

# Copier les dépendances
COPY --from=dependencies /app/node_modules ./node_modules

# Copier le code de l'application
COPY . .

# L'application écoute sur le port 3000
EXPOSE 3000

# Lancer l'application
CMD ["npm", "start"]
```
