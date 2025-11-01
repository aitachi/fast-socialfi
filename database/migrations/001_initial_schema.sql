-- ============================================
-- SocialFi Database Schema - Initial Migration
-- MySQL 8.0+
-- ============================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS `direct_messages`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `comments`;
DROP TABLE IF EXISTS `trades`;
DROP TABLE IF EXISTS `posts`;
DROP TABLE IF EXISTS `user_circle_relationships`;
DROP TABLE IF EXISTS `circles`;
DROP TABLE IF EXISTS `user_relationships`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `daily_active_users`;
DROP TABLE IF EXISTS `circle_stats_snapshots`;
DROP TABLE IF EXISTS `user_feed_cache`;
DROP TABLE IF EXISTS `trending_cache`;

-- ============================================
-- Users Table
-- ============================================
CREATE TABLE `users` (
    `user_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `wallet_address` VARCHAR(42) UNIQUE NOT NULL,
    `ens_name` VARCHAR(255) DEFAULT NULL,

    -- Personal Information
    `username` VARCHAR(50) UNIQUE DEFAULT NULL,
    `display_name` VARCHAR(100) DEFAULT NULL,
    `bio` TEXT DEFAULT NULL,
    `avatar_ipfs_hash` VARCHAR(66) DEFAULT NULL,
    `cover_ipfs_hash` VARCHAR(66) DEFAULT NULL,
    `email` VARCHAR(255) DEFAULT NULL,
    `twitter_handle` VARCHAR(50) DEFAULT NULL,
    `github_handle` VARCHAR(50) DEFAULT NULL,

    -- Social Statistics
    `follower_count` INT UNSIGNED DEFAULT 0,
    `following_count` INT UNSIGNED DEFAULT 0,
    `circle_count` INT UNSIGNED DEFAULT 0,

    -- Reputation System
    `reputation_score` DECIMAL(10,2) DEFAULT 0,
    `total_trading_volume` DECIMAL(30,18) DEFAULT 0,
    `total_content_count` INT UNSIGNED DEFAULT 0,
    `total_reward_received` DECIMAL(30,18) DEFAULT 0,

    -- Blockchain Data
    `nft_count` INT UNSIGNED DEFAULT 0,
    `token_portfolio_value` DECIMAL(30,18) DEFAULT 0,

    -- Settings
    `notification_enabled` BOOLEAN DEFAULT TRUE,
    `email_verified` BOOLEAN DEFAULT FALSE,
    `kyc_verified` BOOLEAN DEFAULT FALSE,
    `is_banned` BOOLEAN DEFAULT FALSE,

    -- Timestamps
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `last_active_at` TIMESTAMP NULL DEFAULT NULL,

    -- Constraints
    CONSTRAINT `chk_wallet_address` CHECK (wallet_address REGEXP '^0x[a-fA-F0-9]{40}$'),
    CONSTRAINT `chk_username_length` CHECK (CHAR_LENGTH(username) >= 3),
    CONSTRAINT `chk_reputation_positive` CHECK (reputation_score >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for users table
CREATE INDEX `idx_users_wallet` ON `users`(`wallet_address`);
CREATE INDEX `idx_users_username` ON `users`(`username`);
CREATE INDEX `idx_users_reputation` ON `users`(`reputation_score` DESC);
CREATE INDEX `idx_users_created_at` ON `users`(`created_at` DESC);
CREATE INDEX `idx_users_last_active` ON `users`(`last_active_at` DESC);
CREATE FULLTEXT INDEX `idx_users_search` ON `users`(`username`, `display_name`, `bio`);

-- ============================================
-- User Relationships Table (Social Graph)
-- ============================================
CREATE TABLE `user_relationships` (
    `relationship_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- Graph Triple: Subject - Predicate - Object
    `from_user_id` BIGINT UNSIGNED NOT NULL,
    `relationship_type` ENUM('FOLLOWS', 'BLOCKS', 'COLLABORATES') NOT NULL,
    `to_user_id` BIGINT UNSIGNED NOT NULL,

    -- Relationship Strength (for recommendation algorithm)
    `strength_score` DECIMAL(5,2) DEFAULT 1.0,
    `interaction_count` INT UNSIGNED DEFAULT 0,

    -- Timestamps
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT `fk_ur_from_user` FOREIGN KEY (`from_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ur_to_user` FOREIGN KEY (`to_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `uk_user_relationship` UNIQUE(`from_user_id`, `relationship_type`, `to_user_id`),
    CONSTRAINT `chk_no_self_relationship` CHECK (`from_user_id` != `to_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for user_relationships
CREATE INDEX `idx_ur_from_type` ON `user_relationships`(`from_user_id`, `relationship_type`);
CREATE INDEX `idx_ur_to_type` ON `user_relationships`(`to_user_id`, `relationship_type`);
CREATE INDEX `idx_ur_strength` ON `user_relationships`(`strength_score` DESC);

-- ============================================
-- Circles Table
-- ============================================
CREATE TABLE `circles` (
    `circle_id` BIGINT UNSIGNED PRIMARY KEY,
    `owner_id` BIGINT UNSIGNED NOT NULL,
    `contract_address` VARCHAR(42) UNIQUE NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `symbol` VARCHAR(20) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `category` VARCHAR(50) DEFAULT NULL,
    `tags` JSON DEFAULT NULL,

    -- Blockchain Data (synced from chain)
    `total_supply` DECIMAL(30,18) DEFAULT 0,
    `current_price` DECIMAL(30,18) DEFAULT 0,
    `market_cap` DECIMAL(30,18) DEFAULT 0,
    `member_count` INT UNSIGNED DEFAULT 0,
    `post_count` INT UNSIGNED DEFAULT 0,
    `total_volume` DECIMAL(30,18) DEFAULT 0,

    -- Settings
    `is_public` BOOLEAN DEFAULT TRUE,
    `min_token_to_join` DECIMAL(30,18) DEFAULT 0,
    `allow_posting` BOOLEAN DEFAULT TRUE,
    `moderation_enabled` BOOLEAN DEFAULT TRUE,

    -- Timestamps
    `created_at_block` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT `fk_circle_owner` FOREIGN KEY (`owner_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `chk_circle_contract` CHECK (contract_address REGEXP '^0x[a-fA-F0-9]{40}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for circles
CREATE INDEX `idx_circles_owner` ON `circles`(`owner_id`);
CREATE INDEX `idx_circles_category` ON `circles`(`category`);
CREATE INDEX `idx_circles_market_cap` ON `circles`(`market_cap` DESC);
CREATE INDEX `idx_circles_member_count` ON `circles`(`member_count` DESC);
CREATE FULLTEXT INDEX `idx_circles_search` ON `circles`(`name`, `description`);

-- ============================================
-- User-Circle Relationships Table
-- ============================================
CREATE TABLE `user_circle_relationships` (
    `uc_relationship_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `circle_id` BIGINT UNSIGNED NOT NULL,
    `relationship_type` ENUM('OWNS', 'MODERATOR', 'MEMBER') NOT NULL,

    -- Token Holdings
    `token_balance` DECIMAL(30,18) DEFAULT 0,
    `join_price` DECIMAL(30,18) DEFAULT NULL,
    `contribution_score` DECIMAL(10,2) DEFAULT 0,

    -- Permissions
    `can_post` BOOLEAN DEFAULT TRUE,
    `can_moderate` BOOLEAN DEFAULT FALSE,
    `can_invite` BOOLEAN DEFAULT FALSE,

    -- Timestamps
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_interaction_at` TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT `fk_ucr_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ucr_circle` FOREIGN KEY (`circle_id`) REFERENCES `circles`(`circle_id`) ON DELETE CASCADE,
    CONSTRAINT `uk_user_circle` UNIQUE(`user_id`, `circle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for user_circle_relationships
CREATE INDEX `idx_ucr_user` ON `user_circle_relationships`(`user_id`);
CREATE INDEX `idx_ucr_circle` ON `user_circle_relationships`(`circle_id`);
CREATE INDEX `idx_ucr_type` ON `user_circle_relationships`(`relationship_type`);
CREATE INDEX `idx_ucr_contribution` ON `user_circle_relationships`(`contribution_score` DESC);

-- ============================================
-- Posts Table
-- ============================================
CREATE TABLE `posts` (
    `post_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `author_id` BIGINT UNSIGNED NOT NULL,
    `circle_id` BIGINT UNSIGNED DEFAULT NULL,

    -- Content Data
    `content_ipfs_hash` VARCHAR(66) NOT NULL,
    `content_type` ENUM('TEXT', 'IMAGE', 'VIDEO', 'LINK', 'NFT') NOT NULL,
    `title` VARCHAR(255) DEFAULT NULL,
    `preview_text` TEXT DEFAULT NULL,

    -- Blockchain Data (synced from chain)
    `tx_hash` VARCHAR(66) DEFAULT NULL,
    `block_number` BIGINT UNSIGNED DEFAULT NULL,
    `upvotes` INT UNSIGNED DEFAULT 0,
    `downvotes` INT UNSIGNED DEFAULT 0,
    `comment_count` INT UNSIGNED DEFAULT 0,
    `reward_amount` DECIMAL(30,18) DEFAULT 0,

    -- NFT Data
    `is_nft` BOOLEAN DEFAULT FALSE,
    `nft_token_id` BIGINT UNSIGNED DEFAULT NULL,
    `nft_contract_address` VARCHAR(42) DEFAULT NULL,

    -- Status
    `is_deleted` BOOLEAN DEFAULT FALSE,
    `is_pinned` BOOLEAN DEFAULT FALSE,
    `moderation_status` ENUM('PENDING', 'APPROVED', 'REJECTED', 'FLAGGED') DEFAULT 'APPROVED',

    -- Timestamps
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT `fk_post_author` FOREIGN KEY (`author_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_post_circle` FOREIGN KEY (`circle_id`) REFERENCES `circles`(`circle_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for posts
CREATE INDEX `idx_posts_author` ON `posts`(`author_id`);
CREATE INDEX `idx_posts_circle` ON `posts`(`circle_id`);
CREATE INDEX `idx_posts_created` ON `posts`(`created_at` DESC);
CREATE INDEX `idx_posts_upvotes` ON `posts`(`upvotes` DESC);
CREATE INDEX `idx_posts_reward` ON `posts`(`reward_amount` DESC);
CREATE FULLTEXT INDEX `idx_posts_search` ON `posts`(`title`, `preview_text`);

-- ============================================
-- Comments Table
-- ============================================
CREATE TABLE `comments` (
    `comment_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `post_id` BIGINT UNSIGNED NOT NULL,
    `author_id` BIGINT UNSIGNED NOT NULL,
    `parent_comment_id` BIGINT UNSIGNED DEFAULT NULL,

    `content` TEXT NOT NULL,
    `upvotes` INT UNSIGNED DEFAULT 0,
    `is_deleted` BOOLEAN DEFAULT FALSE,

    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT `fk_comment_post` FOREIGN KEY (`post_id`) REFERENCES `posts`(`post_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_comment_author` FOREIGN KEY (`author_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_comment_parent` FOREIGN KEY (`parent_comment_id`) REFERENCES `comments`(`comment_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for comments
CREATE INDEX `idx_comments_post` ON `comments`(`post_id`, `created_at`);
CREATE INDEX `idx_comments_author` ON `comments`(`author_id`);
CREATE INDEX `idx_comments_parent` ON `comments`(`parent_comment_id`);

-- ============================================
-- Trades Table
-- ============================================
CREATE TABLE `trades` (
    `trade_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tx_hash` VARCHAR(66) UNIQUE NOT NULL,
    `trader_id` BIGINT UNSIGNED NOT NULL,
    `circle_id` BIGINT UNSIGNED NOT NULL,

    `trade_type` ENUM('BUY', 'SELL') NOT NULL,
    `token_amount` DECIMAL(30,18) NOT NULL,
    `eth_amount` DECIMAL(30,18) NOT NULL,
    `price` DECIMAL(30,18) NOT NULL,
    `fee` DECIMAL(30,18) DEFAULT 0,

    `block_number` BIGINT UNSIGNED NOT NULL,
    `timestamp` TIMESTAMP NOT NULL,

    CONSTRAINT `fk_trade_trader` FOREIGN KEY (`trader_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_trade_circle` FOREIGN KEY (`circle_id`) REFERENCES `circles`(`circle_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for trades
CREATE INDEX `idx_trades_trader` ON `trades`(`trader_id`, `timestamp` DESC);
CREATE INDEX `idx_trades_circle` ON `trades`(`circle_id`, `timestamp` DESC);
CREATE INDEX `idx_trades_timestamp` ON `trades`(`timestamp` DESC);

-- ============================================
-- Notifications Table
-- ============================================
CREATE TABLE `notifications` (
    `notification_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,

    `notification_type` ENUM(
        'NEW_FOLLOWER', 'NEW_COMMENT', 'POST_REWARD', 'CIRCLE_INVITE',
        'TRADE_EXECUTED', 'GOVERNANCE_PROPOSAL', 'MENTION'
    ) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT DEFAULT NULL,

    -- Related Entities
    `related_user_id` BIGINT UNSIGNED DEFAULT NULL,
    `related_post_id` BIGINT UNSIGNED DEFAULT NULL,
    `related_circle_id` BIGINT UNSIGNED DEFAULT NULL,

    `is_read` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for notifications
CREATE INDEX `idx_notif_user_read` ON `notifications`(`user_id`, `is_read`, `created_at` DESC);

-- ============================================
-- Direct Messages Table
-- ============================================
CREATE TABLE `direct_messages` (
    `message_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `from_user_id` BIGINT UNSIGNED NOT NULL,
    `to_user_id` BIGINT UNSIGNED NOT NULL,

    `encrypted_content` TEXT NOT NULL,
    `encryption_key_hash` VARCHAR(66) DEFAULT NULL,

    `is_read` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `fk_dm_from` FOREIGN KEY (`from_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_dm_to` FOREIGN KEY (`to_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `chk_no_self_message` CHECK (`from_user_id` != `to_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for direct_messages
CREATE INDEX `idx_dm_from` ON `direct_messages`(`from_user_id`, `created_at` DESC);
CREATE INDEX `idx_dm_to` ON `direct_messages`(`to_user_id`, `is_read`, `created_at` DESC);

-- ============================================
-- Analytics Tables
-- ============================================

-- Daily Active Users
CREATE TABLE `daily_active_users` (
    `date` DATE PRIMARY KEY,
    `active_user_count` INT UNSIGNED NOT NULL,
    `new_user_count` INT UNSIGNED NOT NULL,
    `total_transactions` INT UNSIGNED NOT NULL,
    `total_volume` DECIMAL(30,18) NOT NULL,
    `calculated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Circle Statistics Snapshots
CREATE TABLE `circle_stats_snapshots` (
    `snapshot_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `circle_id` BIGINT UNSIGNED NOT NULL,
    `snapshot_date` DATE NOT NULL,
    `member_count` INT UNSIGNED NOT NULL,
    `token_price` DECIMAL(30,18) NOT NULL,
    `market_cap` DECIMAL(30,18) NOT NULL,
    `daily_volume` DECIMAL(30,18) NOT NULL,
    `daily_post_count` INT UNSIGNED NOT NULL,

    CONSTRAINT `fk_snapshot_circle` FOREIGN KEY (`circle_id`) REFERENCES `circles`(`circle_id`) ON DELETE CASCADE,
    CONSTRAINT `uk_circle_date` UNIQUE(`circle_id`, `snapshot_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_snapshots` ON `circle_stats_snapshots`(`circle_id`, `snapshot_date` DESC);

-- ============================================
-- Cache Tables
-- ============================================

-- User Feed Cache
CREATE TABLE `user_feed_cache` (
    `feed_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `post_id` BIGINT UNSIGNED NOT NULL,
    `relevance_score` DECIMAL(10,2) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT `fk_feed_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_feed_post` FOREIGN KEY (`post_id`) REFERENCES `posts`(`post_id`) ON DELETE CASCADE,
    CONSTRAINT `uk_user_post_feed` UNIQUE(`user_id`, `post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_feed_user_score` ON `user_feed_cache`(`user_id`, `relevance_score` DESC, `created_at` DESC);

-- Trending Cache
CREATE TABLE `trending_cache` (
    `trending_id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity_type` ENUM('POST', 'CIRCLE', 'USER') NOT NULL,
    `entity_id` BIGINT UNSIGNED NOT NULL,
    `trending_score` DECIMAL(10,2) NOT NULL,
    `time_window` ENUM('1h', '24h', '7d') NOT NULL,
    `calculated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX `idx_trending` (`entity_type`, `time_window`, `trending_score` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Initial Admin User (for testing)
-- ============================================
INSERT INTO `users` (
    `wallet_address`, `username`, `display_name`, `bio`, `reputation_score`
) VALUES (
    '0x0000000000000000000000000000000000000001',
    'admin',
    'Platform Admin',
    'Platform administrator account',
    10000.00
);
