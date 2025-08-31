# API Documentation

This document provides comprehensive API documentation for the project template.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Core Endpoints](#core-endpoints)
- [User Management](#user-management)
- [Data Operations](#data-operations)
- [File Operations](#file-operations)
- [Monitoring](#monitoring)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [API Versions](#api-versions)

## Overview

### Base URL
```
Production: https://api.yourdomain.com
Staging: https://api-staging.yourdomain.com
Development: http://localhost:3000
```

### Content Types
- **Request**: `application/json`
- **Response**: `application/json`
- **File Upload**: `multipart/form-data`

### Response Format
```json
{
  "success": true,
  "data": {},
  "message": "Operation successful",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "requestId": "req-12345"
}
```

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  },
  "timestamp": "2024-01-01T00:00:00.000Z",
  "requestId": "req-12345"
}
```

## Authentication

### JWT Token Authentication

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "user",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIs...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
      "expiresIn": 3600
    }
  }
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Authorization: Bearer <refresh_token>
```

#### Logout
```http
POST /api/auth/logout
Authorization: Bearer <access_token>
```

### API Key Authentication

For service-to-service communication:
```http
GET /api/service/data
X-API-Key: your-api-key-here
```

## Core Endpoints

### Health Check
```http
GET /health
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-01T00:00:00.000Z",
    "version": "1.0.0",
    "uptime": 3600
  }
}
```

### Application Status
```http
GET /api/status
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "database": "connected",
    "redis": "connected",
    "services": ["api", "worker", "scheduler"],
    "metrics": {
      "activeUsers": 150,
      "requestsPerMinute": 1200,
      "errorRate": 0.02
    }
  }
}
```

### Metrics Endpoint
```http
GET /metrics
Authorization: Bearer <admin_token>
```

Returns Prometheus-compatible metrics for monitoring.

## User Management

### Get User Profile
```http
GET /api/user/profile
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "user",
    "firstName": "John",
    "lastName": "Doe",
    "bio": "Software developer",
    "avatar": "https://cdn.example.com/avatar.jpg",
    "location": "New York, NY",
    "timezone": "America/New_York",
    "preferences": {
      "theme": "dark",
      "notifications": true
    },
    "createdAt": "2024-01-01T00:00:00.000Z",
    "lastLoginAt": "2024-01-01T12:00:00.000Z"
  }
}
```

### Update User Profile
```http
PUT /api/user/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "firstName": "Jane",
  "lastName": "Smith",
  "bio": "Updated bio",
  "preferences": {
    "theme": "light"
  }
}
```

### Change Password
```http
POST /api/user/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword123",
  "confirmPassword": "newpassword123"
}
```

### Delete Account
```http
DELETE /api/user/account
Authorization: Bearer <token>
```

## Data Operations

### List Items
```http
GET /api/data?page=1&limit=10&sort=createdAt&order=desc&search=query
Authorization: Bearer <token>
```

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)
- `sort`: Sort field (default: createdAt)
- `order`: Sort order (asc/desc, default: desc)
- `search`: Search query
- `filter`: JSON filter object

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "name": "Item 1",
        "description": "Description",
        "createdAt": "2024-01-01T00:00:00.000Z",
        "updatedAt": "2024-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 150,
      "totalPages": 15,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### Get Single Item
```http
GET /api/data/{id}
Authorization: Bearer <token>
```

### Create Item
```http
POST /api/data
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "New Item",
  "description": "Item description",
  "category": "general",
  "tags": ["tag1", "tag2"]
}
```

### Update Item
```http
PUT /api/data/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Item",
  "description": "Updated description"
}
```

### Delete Item
```http
DELETE /api/data/{id}
Authorization: Bearer <token>
```

### Bulk Operations
```http
POST /api/data/bulk
Authorization: Bearer <token>
Content-Type: application/json

{
  "operation": "delete",
  "ids": ["uuid1", "uuid2", "uuid3"]
}
```

## File Operations

### Upload File
```http
POST /api/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

# Form data:
# file: <file>
# metadata: {"description": "File description"}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "filename": "document.pdf",
    "originalName": "my-document.pdf",
    "mimeType": "application/pdf",
    "size": 1024000,
    "url": "https://cdn.example.com/files/uuid/document.pdf",
    "uploadedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Get File Info
```http
GET /api/files/{id}
Authorization: Bearer <token>
```

### Download File
```http
GET /api/files/{id}/download
Authorization: Bearer <token>
```

### Delete File
```http
DELETE /api/files/{id}
Authorization: Bearer <token>
```

### List Files
```http
GET /api/files?page=1&limit=20&type=document
Authorization: Bearer <token>
```

## Monitoring

### Application Metrics
```http
GET /metrics
Authorization: Bearer <admin_token>
```

Returns Prometheus metrics:
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/api/data",status="200"} 1500

# HELP http_request_duration_seconds HTTP request duration in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",endpoint="/api/data",le="0.1"} 1200
```

### Health Checks
```http
GET /health/ready
GET /health/live
GET /health/deep
```

### System Information
```http
GET /api/system/info
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "version": "1.0.0",
    "environment": "production",
    "uptime": 3600000,
    "memory": {
      "used": 256,
      "total": 1024,
      "percentage": 25
    },
    "cpu": {
      "usage": 15.5,
      "cores": 4
    },
    "database": {
      "connections": 12,
      "poolSize": 20
    }
  }
}
```

## Error Handling

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created |
| 204 | No Content | Request successful, no content returned |
| 400 | Bad Request | Invalid request data |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 502 | Bad Gateway | Gateway error |
| 503 | Service Unavailable | Service temporarily unavailable |

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Input validation failed |
| `AUTHENTICATION_ERROR` | 401 | Authentication failed |
| `AUTHORIZATION_ERROR` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMIT_EXCEEDED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

### Validation Errors

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format",
        "value": "invalid-email"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters",
        "value": ""
      }
    ]
  }
}
```

## Rate Limiting

### Rate Limit Headers

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
X-RateLimit-Retry-After: 60
```

### Rate Limit Response

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "details": {
      "limit": 100,
      "remaining": 0,
      "reset": 1640995200,
      "retryAfter": 60
    }
  }
}
```

### Rate Limits by Endpoint

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/auth/*` | 10 | 1 minute |
| `/api/data` | 100 | 1 minute |
| `/api/upload` | 20 | 1 hour |
| `/api/user/*` | 50 | 1 minute |
| All others | 1000 | 1 minute |

## API Versions

### Versioning Strategy

API versions are indicated in the URL path:
```
/api/v1/endpoint
/api/v2/endpoint
```

### Version Headers

```http
Accept: application/vnd.api+json; version=1
X-API-Version: 1
```

### Version Compatibility

- **v1**: Current stable version
- **v2**: Next version (under development)

### Deprecation Policy

1. New API versions are announced 3 months in advance
2. Deprecated versions remain available for 6 months
3. Breaking changes are communicated via email and documentation
4. Migration guides are provided for major version changes

### Version Detection

```javascript
// Client-side version detection
const apiVersion = 'v1';
const baseURL = `https://api.example.com/api/${apiVersion}`;
```

```javascript
// Server-side version handling
app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);
```

## SDKs and Libraries

### JavaScript SDK

```javascript
import { APIClient } from '@yourproject/sdk';

const client = new APIClient({
  baseURL: 'https://api.yourdomain.com',
  apiKey: 'your-api-key'
});

// Authenticate
await client.auth.login('user@example.com', 'password');

// Make requests
const user = await client.user.getProfile();
const items = await client.data.list({ page: 1, limit: 10 });
```

### Python SDK

```python
from yourproject_sdk import APIClient

client = APIClient(
    base_url='https://api.yourdomain.com',
    api_key='your-api-key'
)

# Authenticate
client.auth.login('user@example.com', 'password')

# Make requests
user = client.user.get_profile()
items = client.data.list(page=1, limit=10)
```

## Webhooks

### Webhook Configuration

```http
POST /api/webhooks
Authorization: Bearer <token>
Content-Type: application/json

{
  "url": "https://yourapp.com/webhook",
  "events": ["user.created", "data.updated"],
  "secret": "webhook-secret"
}
```

### Webhook Payload

```json
{
  "id": "evt_12345",
  "type": "user.created",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Webhook Events

| Event | Description |
|-------|-------------|
| `user.created` | New user account created |
| `user.updated` | User profile updated |
| `user.deleted` | User account deleted |
| `data.created` | New data record created |
| `data.updated` | Data record updated |
| `data.deleted` | Data record deleted |
| `file.uploaded` | File uploaded |
| `file.deleted` | File deleted |

This API documentation provides a comprehensive reference for integrating with the application. For additional support or questions, please contact the development team.