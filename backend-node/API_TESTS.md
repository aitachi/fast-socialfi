# Fast SocialFi API 测试集合

## 环境变量

```
API_URL=http://localhost:3000/api
JWT_TOKEN=your_jwt_token_here
```

## 1. 健康检查

### 检查 API 状态

```bash
curl http://localhost:3000/api/health
```

预期响应:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-01T00:00:00.000Z",
    "uptime": 123.456
  }
}
```

## 2. 用户注册和登录

### 2.1 注册新用户

```bash
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_address": "0x1234567890123456789012345678901234567890",
    "signature": "0xabc...",
    "message": "Sign in to Fast SocialFi at 2024-01-01T00:00:00.000Z",
    "username": "alice_crypto",
    "display_name": "Alice",
    "bio": "Web3 enthusiast"
  }'
```

### 2.2 登录

```bash
curl -X POST http://localhost:3000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_address": "0x1234567890123456789012345678901234567890",
    "signature": "0xabc...",
    "message": "Sign in to Fast SocialFi at 2024-01-01T00:00:00.000Z"
  }'
```

保存返回的 token:
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "..."
  }
}
```

## 3. 用户操作

### 3.1 获取当前用户信息

```bash
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3.2 获取用户资料

```bash
curl http://localhost:3000/api/users/1
```

### 3.3 更新用户资料

```bash
curl -X PUT http://localhost:3000/api/users/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Alice Updated",
    "bio": "DeFi lover | NFT collector"
  }'
```

### 3.4 获取粉丝列表

```bash
curl "http://localhost:3000/api/users/1/followers?page=1&limit=20"
```

### 3.5 获取关注列表

```bash
curl "http://localhost:3000/api/users/1/following?page=1&limit=20"
```

## 4. 帖子操作

### 4.1 发布帖子

```bash
curl -X POST http://localhost:3000/api/posts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello Web3! #DeFi #NFT",
    "hashtags": ["DeFi", "NFT"],
    "visibility": "public"
  }'
```

### 4.2 获取帖子详情

```bash
curl http://localhost:3000/api/posts/1
```

### 4.3 获取用户的帖子

```bash
curl "http://localhost:3000/api/posts/user/1?page=1&limit=20"
```

### 4.4 获取时间线

```bash
curl http://localhost:3000/api/posts/feed \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4.5 获取热门帖子

```bash
curl "http://localhost:3000/api/posts/trending?page=1&limit=20"
```

### 4.6 获取话题帖子

```bash
curl "http://localhost:3000/api/posts/hashtag/DeFi?page=1&limit=20"
```

### 4.7 更新帖子

```bash
curl -X PUT http://localhost:3000/api/posts/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Updated content #Web3",
    "hashtags": ["Web3"]
  }'
```

### 4.8 删除帖子

```bash
curl -X DELETE http://localhost:3000/api/posts/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 5. 社交互动

### 5.1 点赞帖子

```bash
curl -X POST http://localhost:3000/api/posts/1/like \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.2 取消点赞

```bash
curl -X DELETE http://localhost:3000/api/posts/1/like \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.3 收藏帖子

```bash
curl -X POST http://localhost:3000/api/posts/1/bookmark \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.4 取消收藏

```bash
curl -X DELETE http://localhost:3000/api/posts/1/bookmark \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.5 获取收藏列表

```bash
curl http://localhost:3000/api/social/bookmarks \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.6 关注用户

```bash
curl -X POST http://localhost:3000/api/social/follow/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.7 取消关注

```bash
curl -X DELETE http://localhost:3000/api/social/follow/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5.8 检查关注状态

```bash
curl http://localhost:3000/api/social/following/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 6. 评论

### 6.1 获取帖子评论

```bash
curl "http://localhost:3000/api/posts/1/comments?page=1&limit=20"
```

### 6.2 发表评论

```bash
curl -X POST http://localhost:3000/api/posts/1/comments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Great post! 👍"
  }'
```

### 6.3 回复评论

```bash
curl -X POST http://localhost:3000/api/posts/1/comments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Thanks!",
    "parent_id": 1
  }'
```

## 7. 搜索

### 7.1 搜索用户

```bash
curl "http://localhost:3000/api/search/users?keyword=alice&page=1&limit=20"
```

### 7.2 搜索帖子

```bash
curl "http://localhost:3000/api/search/posts?keyword=defi&page=1&limit=20"
```

### 7.3 搜索话题

```bash
curl "http://localhost:3000/api/search/hashtags?keyword=nft&page=1&limit=20"
```

### 7.4 用户自动补全

```bash
curl "http://localhost:3000/api/search/suggest/users?prefix=ali&size=10"
```

## 8. 错误处理测试

### 8.1 未认证访问

```bash
curl http://localhost:3000/api/users/me
# 应返回 401 Unauthorized
```

### 8.2 无效的 Token

```bash
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer invalid_token"
# 应返回 401 Invalid Token
```

### 8.3 访问不存在的资源

```bash
curl http://localhost:3000/api/posts/999999
# 应返回 404 Post Not Found
```

### 8.4 参数验证失败

```bash
curl -X POST http://localhost:3000/api/posts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
# 应返回 400 Validation Error
```

## 9. 压力测试(使用 Apache Bench)

### 9.1 测试健康检查端点

```bash
ab -n 1000 -c 10 http://localhost:3000/api/health
```

### 9.2 测试获取帖子列表

```bash
ab -n 500 -c 5 "http://localhost:3000/api/posts/trending"
```

## 10. Postman 集合

可以将以上测试导入 Postman:

1. 创建新的 Collection
2. 设置环境变量:
   - `api_url`: http://localhost:3000/api
   - `jwt_token`: 从登录响应获取
3. 添加所有端点测试
4. 使用 Pre-request Scripts 自动设置 token

## 测试检查清单

- [ ] 健康检查 API 正常
- [ ] 用户注册成功
- [ ] 用户登录成功并返回 token
- [ ] 使用 token 可以访问受保护端点
- [ ] 可以创建、读取、更新、删除帖子
- [ ] 点赞、评论、收藏功能正常
- [ ] 关注、取消关注功能正常
- [ ] 搜索功能返回正确结果
- [ ] 错误处理正确返回状态码和错误信息
- [ ] 限流机制正常工作
