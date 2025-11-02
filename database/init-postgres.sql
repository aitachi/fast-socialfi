-- PostgreSQL 初始化脚本
-- Fast SocialFi Database

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 设置时区
SET timezone = 'UTC';

-- 创建 Schema
CREATE SCHEMA IF NOT EXISTS socialfi;

-- 设置搜索路径
SET search_path TO socialfi, public;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address VARCHAR(42) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255),
    bio TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_users_address ON users(address);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- 添加注释
COMMENT ON TABLE users IS '用户表';
COMMENT ON COLUMN users.id IS '用户唯一标识';
COMMENT ON COLUMN users.address IS '以太坊钱包地址';
COMMENT ON COLUMN users.username IS '用户名';

-- 输出信息
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL 数据库初始化完成!';
    RAISE NOTICE '数据库: socialfi_db';
    RAISE NOTICE '用户: socialfi';
    RAISE NOTICE 'Schema: socialfi';
END $$;
