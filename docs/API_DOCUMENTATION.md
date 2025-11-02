# Fast SocialFi API Documentation

**Version:** v2.1
**Last Updated:** November 2, 2025
**Base URL:** `http://localhost:8080` (development)
**Production URL:** `https://api.fastsocialfi.com` (future)

---

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Pagination](#pagination)
- [Circle APIs](#circle-apis)
- [Trading APIs](#trading-apis)
- [User APIs](#user-apis-future)
- [Content APIs](#content-apis-future)
- [Social APIs](#social-apis-future)
- [Notification APIs](#notification-apis-future)
- [Staking APIs](#staking-apis-future)
- [Governance APIs](#governance-apis-future)
- [Admin APIs](#admin-apis-future)
- [WebSocket APIs](#websocket-apis-future)
- [Examples](#examples)

---

## Overview

The Fast SocialFi API provides RESTful endpoints to interact with the platform's backend services. All requests and responses use JSON format.

### Base Information

| Property | Value |
|----------|-------|
| **Protocol** | HTTPS (production), HTTP (development) |
| **Content-Type** | `application/json` |
| **Character Encoding** | UTF-8 |
| **API Version** | v1 |
| **Prefix** | `/api/v1` |

### Request Headers

```http
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN> (for protected endpoints)
X-Request-ID: <UUID> (optional, for request tracking)
```

### Response Format

All API responses follow this structure:

**Success Response:**
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "meta": {
    "timestamp": "2025-11-02T14:00:00Z",
    "requestId": "uuid"
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {}
  },
  "meta": {
    "timestamp": "2025-11-02T14:00:00Z",
    "requestId": "uuid"
  }
}
```

---

## Authentication

### JWT Authentication

Protected endpoints require a JWT token in the Authorization header.

#### Login

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "signature": "0x..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 86400,
    "user": {
      "id": "uuid",
      "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
      "username": "alice"
    }
  }
}
```

#### Refresh Token

```http
POST /api/v1/auth/refresh
Authorization: Bearer <OLD_TOKEN>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "new_jwt_token",
    "expiresIn": 86400
  }
}
```

#### Using the Token

Include the token in the Authorization header for protected endpoints:

```http
GET /api/v1/circles
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Error Handling

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | OK - Request succeeded |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid request parameters |
| 401 | Unauthorized - Missing or invalid authentication |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable Entity - Validation failed |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Server error |
| 503 | Service Unavailable - Service temporarily unavailable |

### Error Codes

| Code | Description |
|------|-------------|
| `AUTH_INVALID_TOKEN` | Invalid or expired JWT token |
| `AUTH_MISSING_TOKEN` | Authorization header missing |
| `AUTH_INVALID_SIGNATURE` | Invalid wallet signature |
| `VALIDATION_ERROR` | Request validation failed |
| `NOT_FOUND` | Resource not found |
| `ALREADY_EXISTS` | Resource already exists |
| `INSUFFICIENT_BALANCE` | Insufficient token balance |
| `INSUFFICIENT_ALLOWANCE` | Insufficient token allowance |
| `BLOCKCHAIN_ERROR` | Blockchain transaction failed |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `INTERNAL_ERROR` | Internal server error |

### Error Response Example

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "field": "circleId",
      "reason": "must be a positive integer"
    }
  },
  "meta": {
    "timestamp": "2025-11-02T14:00:00Z",
    "requestId": "abc-123-def-456"
  }
}
```

---

## Rate Limiting

Rate limiting is applied per IP address and per user (for authenticated requests).

### Limits

| Endpoint Type | IP Limit | User Limit | Window |
|--------------|----------|------------|--------|
| Public endpoints | 100 req/min | N/A | 60 seconds |
| Authenticated endpoints | 200 req/min | 100 req/min | 60 seconds |
| Write operations | 50 req/min | 30 req/min | 60 seconds |
| Blockchain operations | 20 req/min | 10 req/min | 60 seconds |

### Response Headers

Rate limit information is included in response headers:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1699012800
```

### Rate Limit Exceeded

When rate limit is exceeded, you'll receive a 429 status:

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "details": {
      "retryAfter": 30
    }
  }
}
```

---

## Pagination

List endpoints support pagination using limit and offset parameters.

### Parameters

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `limit` | integer | 20 | 100 | Number of items per page |
| `offset` | integer | 0 | N/A | Number of items to skip |

### Example

```http
GET /api/v1/circles?limit=20&offset=40
```

### Paginated Response

```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "total": 150,
      "limit": 20,
      "offset": 40,
      "hasMore": true
    }
  }
}
```

---

## Circle APIs

Circle APIs manage community circles and their associated tokens.

### List Circles

Get a paginated list of all circles.

```http
GET /api/v1/circles
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Items per page (default: 20, max: 100) |
| `offset` | integer | No | Items to skip (default: 0) |
| `sort` | string | No | Sort field: `created`, `members`, `volume` (default: `created`) |
| `order` | string | No | Sort order: `asc`, `desc` (default: `desc`) |
| `category` | string | No | Filter by category |
| `active` | boolean | No | Filter by active status |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/circles?limit=10&sort=members&order=desc"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "1",
        "chainCircleId": "1",
        "name": "Web3 Builders",
        "symbol": "W3B",
        "tokenAddress": "0x814a4482e6CaFB6F616d23e9ED43cE35d4F50977",
        "owner": "0x197131c5e0400602fFe47009D38d12f815411149",
        "description": "A community for Web3 developers",
        "category": "Technology",
        "memberCount": 150,
        "currentPrice": "0.05",
        "totalSupply": "1000000",
        "marketCap": "50000",
        "volume24h": "5000",
        "curveType": 0,
        "isActive": true,
        "createdAt": "2025-11-01T14:00:00Z",
        "updatedAt": "2025-11-02T14:00:00Z"
      }
    ],
    "pagination": {
      "total": 1,
      "limit": 10,
      "offset": 0,
      "hasMore": false
    }
  }
}
```

---

### Get Circle by ID

Get detailed information about a specific circle.

```http
GET /api/v1/circles/:id
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Circle ID |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/circles/1"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "1",
    "chainCircleId": "1",
    "name": "Web3 Builders",
    "symbol": "W3B",
    "tokenAddress": "0x814a4482e6CaFB6F616d23e9ED43cE35d4F50977",
    "owner": "0x197131c5e0400602fFe47009D38d12f815411149",
    "description": "A community for Web3 developers and enthusiasts",
    "category": "Technology",
    "tags": ["web3", "blockchain", "development"],
    "memberCount": 150,
    "currentPrice": "0.05",
    "totalSupply": "1000000",
    "circulatingSupply": "500000",
    "marketCap": "50000",
    "volume24h": "5000",
    "priceChange24h": "5.2",
    "curveType": 0,
    "curveParams": {
      "k": "1000000000000000",
      "m": "0",
      "n": "0"
    },
    "isActive": true,
    "createdAt": "2025-11-01T14:00:00Z",
    "updatedAt": "2025-11-02T14:00:00Z",
    "stats": {
      "totalTransactions": 245,
      "totalBuyers": 120,
      "totalSellers": 85,
      "averageHoldingTime": 172800
    }
  }
}
```

---

### Create Circle

Create a new circle. Requires authentication.

```http
POST /api/v1/circles
Authorization: Bearer <TOKEN>
Content-Type: application/json
```

**Request Body:**

```json
{
  "name": "Web3 Builders",
  "symbol": "W3B",
  "description": "A community for Web3 developers",
  "category": "Technology",
  "tags": ["web3", "blockchain", "development"],
  "curveType": 0,
  "curveParams": {
    "k": "1000000000000000",
    "m": "0",
    "n": "0"
  },
  "initialSupply": "1000000000000000000000",
  "privateKey": "0x..."
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Circle name (max 100 chars) |
| `symbol` | string | Yes | Token symbol (3-10 uppercase chars) |
| `description` | string | No | Circle description (max 1000 chars) |
| `category` | string | No | Category |
| `tags` | array | No | Tags (max 10) |
| `curveType` | integer | Yes | 0=Linear, 1=Exponential, 2=Sigmoid |
| `curveParams.k` | string | Yes | K parameter (wei) |
| `curveParams.m` | string | No | M parameter (wei) |
| `curveParams.n` | string | No | N parameter (wei) |
| `initialSupply` | string | Yes | Initial token supply (wei) |
| `privateKey` | string | Yes | Creator's private key for signing |

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "2",
    "chainCircleId": "2",
    "name": "Web3 Builders",
    "symbol": "W3B",
    "tokenAddress": "0x...",
    "owner": "0x...",
    "txHash": "0x...",
    "createdAt": "2025-11-02T14:00:00Z"
  }
}
```

---

### Search Circles

Search circles by name, symbol, or description.

```http
GET /api/v1/circles/search
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query (min 2 chars) |
| `limit` | integer | No | Items per page (default: 20) |
| `offset` | integer | No | Items to skip (default: 0) |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/circles/search?q=web3&limit=10"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "1",
        "name": "Web3 Builders",
        "symbol": "W3B",
        "description": "A community for Web3 developers",
        "memberCount": 150,
        "currentPrice": "0.05"
      }
    ],
    "pagination": {
      "total": 1,
      "limit": 10,
      "offset": 0
    }
  }
}
```

---

### Get Trending Circles

Get trending circles based on recent activity.

```http
GET /api/v1/circles/trending
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Number of circles (default: 10, max: 50) |
| `period` | string | No | Time period: `24h`, `7d`, `30d` (default: `24h`) |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/circles/trending?limit=10&period=24h"
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "name": "Web3 Builders",
      "symbol": "W3B",
      "memberCount": 150,
      "currentPrice": "0.05",
      "priceChange24h": "15.5",
      "volume24h": "5000",
      "trending": {
        "rank": 1,
        "score": 95.5
      }
    }
  ]
}
```

---

### Sync Circle Data

Sync circle data from blockchain. Requires authentication.

```http
PUT /api/v1/circles/:id/sync
Authorization: Bearer <TOKEN>
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Circle ID |

**Example Request:**

```bash
curl -X PUT "http://localhost:8080/api/v1/circles/1/sync" \
  -H "Authorization: Bearer <TOKEN>"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "1",
    "synced": true,
    "changes": {
      "totalSupply": "updated",
      "currentPrice": "updated",
      "memberCount": "updated"
    },
    "timestamp": "2025-11-02T14:00:00Z"
  }
}
```

---

## Trading APIs

Trading APIs handle token buying, selling, and price queries.

### Get Token Price

Get current token price for a circle.

```http
GET /api/v1/trading/price/:circleId
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `circleId` | string | Yes | Circle ID |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/trading/price/1"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "circleId": "1",
    "tokenAddress": "0x814a4482e6CaFB6F616d23e9ED43cE35d4F50977",
    "currentPrice": "0.05",
    "totalSupply": "1000000",
    "priceChange24h": "5.2",
    "priceChangePercentage24h": "5.2",
    "high24h": "0.052",
    "low24h": "0.048",
    "volume24h": "5000",
    "lastUpdated": "2025-11-02T14:00:00Z"
  }
}
```

---

### Get Token Balance

Get token balance for an address.

```http
GET /api/v1/trading/balance/:circleId/:address
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `circleId` | string | Yes | Circle ID |
| `address` | string | Yes | Ethereum address |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/trading/balance/1/0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "circleId": "1",
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "balance": "1000000000000000000000",
    "balanceFormatted": "1000",
    "valueInEth": "50",
    "percentageOfSupply": "0.1"
  }
}
```

---

### Buy Tokens

Buy circle tokens. Requires authentication.

```http
POST /api/v1/trading/buy
Authorization: Bearer <TOKEN>
Content-Type: application/json
```

**Request Body:**

```json
{
  "circleId": "1",
  "amount": "10000000000000000000",
  "maxCost": "1000000000000000000",
  "privateKey": "0x..."
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `circleId` | string | Yes | Circle ID |
| `amount` | string | Yes | Amount of tokens to buy (wei) |
| `maxCost` | string | Yes | Maximum ETH to spend (wei, slippage protection) |
| `privateKey` | string | Yes | Buyer's private key for signing |

**Response:**

```json
{
  "success": true,
  "data": {
    "txHash": "0x...",
    "circleId": "1",
    "buyer": "0x...",
    "amount": "10",
    "cost": "0.5",
    "price": "0.05",
    "newPrice": "0.051",
    "timestamp": "2025-11-02T14:00:00Z"
  }
}
```

---

### Sell Tokens

Sell circle tokens. Requires authentication.

```http
POST /api/v1/trading/sell
Authorization: Bearer <TOKEN>
Content-Type: application/json
```

**Request Body:**

```json
{
  "circleId": "1",
  "amount": "5000000000000000000",
  "minRefund": "200000000000000000",
  "privateKey": "0x..."
}
```

**Field Descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `circleId` | string | Yes | Circle ID |
| `amount` | string | Yes | Amount of tokens to sell (wei) |
| `minRefund` | string | Yes | Minimum ETH to receive (wei, slippage protection) |
| `privateKey` | string | Yes | Seller's private key for signing |

**Response:**

```json
{
  "success": true,
  "data": {
    "txHash": "0x...",
    "circleId": "1",
    "seller": "0x...",
    "amount": "5",
    "refund": "0.25",
    "price": "0.05",
    "newPrice": "0.048",
    "timestamp": "2025-11-02T14:00:00Z"
  }
}
```

---

### Calculate Buy Cost

Calculate the cost of buying a specific amount of tokens.

```http
GET /api/v1/trading/buy-cost/:circleId/:amount
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `circleId` | string | Yes | Circle ID |
| `amount` | string | Yes | Amount of tokens (wei) |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/trading/buy-cost/1/10000000000000000000"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "circleId": "1",
    "amount": "10",
    "cost": "0.52",
    "pricePerToken": "0.052",
    "priceImpact": "4.2",
    "fees": {
      "circleOwner": "0.312",
      "platform": "0.104",
      "liquidity": "0.104"
    }
  }
}
```

---

### Calculate Sell Refund

Calculate the refund from selling a specific amount of tokens.

```http
GET /api/v1/trading/sell-refund/:circleId/:amount
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `circleId` | string | Yes | Circle ID |
| `amount` | string | Yes | Amount of tokens (wei) |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/trading/sell-refund/1/5000000000000000000"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "circleId": "1",
    "amount": "5",
    "refund": "0.24",
    "pricePerToken": "0.048",
    "priceImpact": "-4.2",
    "fees": {
      "circleOwner": "0.144",
      "platform": "0.048",
      "liquidity": "0.048"
    }
  }
}
```

---

### Get Transaction History

Get transaction history for a circle or user.

```http
GET /api/v1/trading/transactions
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `circleId` | string | No | Filter by circle ID |
| `address` | string | No | Filter by user address |
| `type` | string | No | Filter by type: `buy`, `sell`, `all` (default: `all`) |
| `limit` | integer | No | Items per page (default: 20) |
| `offset` | integer | No | Items to skip (default: 0) |

**Example Request:**

```bash
curl -X GET "http://localhost:8080/api/v1/trading/transactions?circleId=1&limit=10"
```

**Response:**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "tx-1",
        "txHash": "0x...",
        "circleId": "1",
        "type": "buy",
        "address": "0x...",
        "amount": "10",
        "price": "0.05",
        "total": "0.5",
        "timestamp": "2025-11-02T14:00:00Z"
      }
    ],
    "pagination": {
      "total": 245,
      "limit": 10,
      "offset": 0
    }
  }
}
```

---

## User APIs (Future)

*User management APIs will be implemented in Phase 4.*

### Register User
### Get User Profile
### Update User Profile
### Get User Portfolio
### Get User Activity

---

## Content APIs (Future)

*Content management APIs will be implemented in Phase 4.*

### Create Post
### Get Post
### Update Post
### Delete Post
### Like Post
### Comment on Post

---

## Social APIs (Future)

*Social interaction APIs will be implemented in Phase 4.*

### Follow User
### Unfollow User
### Get Followers
### Get Following
### Send Message

---

## Notification APIs (Future)

*Notification APIs will be implemented in Phase 4.*

### Get Notifications
### Mark as Read
### Get Notification Settings
### Update Notification Settings

---

## Staking APIs (Future)

*Staking APIs will be implemented in Phase 5.*

### Stake Tokens
### Unstake Tokens
### Claim Rewards
### Get Staking Info

---

## Governance APIs (Future)

*Governance APIs will be implemented in Phase 5.*

### Create Proposal
### Vote on Proposal
### Execute Proposal
### Get Proposals

---

## Admin APIs (Future)

*Admin APIs will be implemented in Phase 6.*

### Platform Statistics
### User Management
### Content Moderation
### Circle Management

---

## WebSocket APIs (Future)

*Real-time WebSocket APIs will be implemented in Phase 5.*

### Connection
### Subscribe to Events
### Unsubscribe
### Heartbeat

---

## Examples

### Complete Workflow Example

#### 1. User Authentication

```bash
# Login with wallet
curl -X POST "http://localhost:8080/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "signature": "0x..."
  }'
```

#### 2. Create Circle

```bash
# Create a new circle
curl -X POST "http://localhost:8080/api/v1/circles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "name": "Crypto Artists",
    "symbol": "ART",
    "description": "A community for digital artists",
    "category": "Art",
    "curveType": 0,
    "curveParams": {
      "k": "1000000000000000",
      "m": "0",
      "n": "0"
    },
    "initialSupply": "1000000000000000000000",
    "privateKey": "0x..."
  }'
```

#### 3. Buy Tokens

```bash
# Buy circle tokens
curl -X POST "http://localhost:8080/api/v1/trading/buy" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "circleId": "1",
    "amount": "10000000000000000000",
    "maxCost": "1000000000000000000",
    "privateKey": "0x..."
  }'
```

#### 4. Check Balance

```bash
# Check token balance
curl -X GET "http://localhost:8080/api/v1/trading/balance/1/0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
```

#### 5. Sell Tokens

```bash
# Sell tokens
curl -X POST "http://localhost:8080/api/v1/trading/sell" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "circleId": "1",
    "amount": "5000000000000000000",
    "minRefund": "200000000000000000",
    "privateKey": "0x..."
  }'
```

---

### JavaScript/TypeScript Example

```typescript
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8080/api/v1';

// Create API client
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('jwt_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Login
async function login(walletAddress: string, signature: string) {
  const response = await apiClient.post('/auth/login', {
    walletAddress,
    signature,
  });

  const { token } = response.data.data;
  localStorage.setItem('jwt_token', token);
  return token;
}

// Get circles
async function getCircles(limit = 20, offset = 0) {
  const response = await apiClient.get('/circles', {
    params: { limit, offset },
  });
  return response.data.data;
}

// Create circle
async function createCircle(circleData: {
  name: string;
  symbol: string;
  description: string;
  category: string;
  curveType: number;
  curveParams: {
    k: string;
    m: string;
    n: string;
  };
  initialSupply: string;
  privateKey: string;
}) {
  const response = await apiClient.post('/circles', circleData);
  return response.data.data;
}

// Buy tokens
async function buyTokens(circleId: string, amount: string, maxCost: string, privateKey: string) {
  const response = await apiClient.post('/trading/buy', {
    circleId,
    amount,
    maxCost,
    privateKey,
  });
  return response.data.data;
}

// Get token price
async function getTokenPrice(circleId: string) {
  const response = await apiClient.get(`/trading/price/${circleId}`);
  return response.data.data;
}

// Usage
async function main() {
  try {
    // Get all circles
    const circles = await getCircles(10, 0);
    console.log('Circles:', circles);

    // Get price for first circle
    if (circles.items.length > 0) {
      const price = await getTokenPrice(circles.items[0].id);
      console.log('Token price:', price);
    }
  } catch (error) {
    console.error('API Error:', error);
  }
}

main();
```

---

### Python Example

```python
import requests
from typing import Dict, Any

class FastSocialFiAPI:
    def __init__(self, base_url: str = "http://localhost:8080/api/v1"):
        self.base_url = base_url
        self.token = None

    def set_token(self, token: str):
        self.token = token

    def _headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers

    def login(self, wallet_address: str, signature: str) -> str:
        response = requests.post(
            f"{self.base_url}/auth/login",
            json={"walletAddress": wallet_address, "signature": signature},
            headers=self._headers()
        )
        response.raise_for_status()
        data = response.json()["data"]
        self.token = data["token"]
        return self.token

    def get_circles(self, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
        response = requests.get(
            f"{self.base_url}/circles",
            params={"limit": limit, "offset": offset},
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()["data"]

    def create_circle(self, circle_data: Dict[str, Any]) -> Dict[str, Any]:
        response = requests.post(
            f"{self.base_url}/circles",
            json=circle_data,
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()["data"]

    def buy_tokens(self, circle_id: str, amount: str, max_cost: str, private_key: str) -> Dict[str, Any]:
        response = requests.post(
            f"{self.base_url}/trading/buy",
            json={
                "circleId": circle_id,
                "amount": amount,
                "maxCost": max_cost,
                "privateKey": private_key
            },
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()["data"]

    def get_token_price(self, circle_id: str) -> Dict[str, Any]:
        response = requests.get(
            f"{self.base_url}/trading/price/{circle_id}",
            headers=self._headers()
        )
        response.raise_for_status()
        return response.json()["data"]

# Usage
api = FastSocialFiAPI()

# Get circles
circles = api.get_circles(limit=10)
print(f"Found {circles['pagination']['total']} circles")

# Get price
if circles['items']:
    circle_id = circles['items'][0]['id']
    price = api.get_token_price(circle_id)
    print(f"Token price: {price['currentPrice']} ETH")
```

---

## Support

For API support and questions:

- **GitHub Issues**: https://github.com/your-org/fast-socialfi/issues
- **Documentation**: [README.md](../README.md)
- **Email**: api-support@fastsocialfi.com (future)

---

**Last Updated:** November 2, 2025
**API Version:** v1
**Document Version:** 1.0
