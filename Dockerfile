# ==============================================================================
# Stage 1: Build the React Application
# ==============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (leverages Docker layer cache)
COPY package*.json ./
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm ci --frozen-lockfile

# Copy application source code and compile static assets
COPY . .
RUN npm run build

# ==============================================================================
# Stage 2: Serve Production Assets with Nginx (Lightweight Alpine)
# ==============================================================================
FROM nginx:1.27-alpine

# Set metadata labels
LABEL maintainer="STANS DevOps Team"
LABEL description="Smart Traffic-Aware Navigation System (STANS)"

# Remove default Nginx website configuration
RUN rm -rf /etc/nginx/conf.d/* /usr/share/nginx/html/*

# Copy custom Nginx configuration for SPA routing and security
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy compiled static files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose HTTP port 80
EXPOSE 80

# Docker healthcheck to verify Nginx is actively responding
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:80/health || exit 1

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
