# Multi-stage build for optimized production image
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++ git curl

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application files
COPY . .

# Build TypeScript if needed
RUN if [ -f "tsconfig.json" ]; then npm install -D typescript && npm run build; fi

# Production stage
FROM node:18-alpine

# Install runtime dependencies
RUN apk add --no-cache curl tini

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/backend ./backend
COPY --from=builder --chown=nodejs:nodejs /app/contracts ./contracts
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Copy build output if exists
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist 2>/dev/null || true

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Use tini to handle signals properly
ENTRYPOINT ["/sbin/tini", "--"]

# Start application
CMD ["node", "backend/server.js"]
