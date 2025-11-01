-- ============================================
-- SocialFi Test Data Seeds
-- ============================================

USE socialfi_db;

-- Insert test users (5 users from request.txt)
INSERT INTO `users` (
    wallet_address, ens_name, username, display_name, bio,
    avatar_ipfs_hash, reputation_score, follower_count,
    following_count, circle_count, total_trading_volume,
    total_content_count, total_reward_received, nft_count,
    token_portfolio_value, last_active_at
) VALUES
(
    '0x742d35cc6634c0532925a3b844bc9e7595f0beb1',
    'alice.eth',
    'alice_crypto',
    'Alice Chen',
    'Web3 builder & DeFi enthusiast. Love photography and sharing blockchain insights.',
    'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG',
    2850.50,
    1520,
    380,
    5,
    '125.75',
    89,
    '45.25',
    12,
    '380.50',
    NOW() - INTERVAL 1 HOUR
),
(
    '0x8ba1f109551bd432803012645ac136ddd64dba72',
    'bob.eth',
    'bob_trader',
    'Bob Martinez',
    'NFT collector | Crypto trader | Building the future of SocialFi',
    'QmPZ9gcCEpqKTo6aq61g4nXGUhM1bjyXJDuCBGVhQoJW4E',
    1950.25,
    892,
    512,
    3,
    '89.30',
    45,
    '28.80',
    28,
    '520.75',
    NOW() - INTERVAL 2 HOUR
),
(
    '0xdd2fd4581271e230360230f9337d5c0430bf44c0',
    NULL,
    'carol_dev',
    'Carol Wang',
    'Smart contract developer. Creating decentralized social experiences.',
    'QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco',
    3200.75,
    2340,
    890,
    8,
    '256.40',
    156,
    '98.60',
    8,
    '1250.30',
    NOW() - INTERVAL 30 MINUTE
),
(
    '0xbcd4042de499d14e55001ccbb24a551f3b954096',
    'david.eth',
    'david_artist',
    'David Kim',
    'Digital artist exploring Web3 creative economy. Minting memories on-chain.',
    'QmYHNYAaYK5hm3ZhZFx5W9H6xrCchSd1ar1pz3R2Q38uNt',
    1250.00,
    3450,
    125,
    2,
    '45.20',
    234,
    '156.75',
    45,
    '680.90',
    NOW() - INTERVAL 4 HOUR
),
(
    '0x71c7656ec7ab88b098defb751b7401b5f6d8976f',
    NULL,
    'emma_dao',
    'Emma Johnson',
    'DAO governance expert. Helping communities coordinate on-chain.',
    'QmNfF5QKsKXrFkBXPc39G1VxGj8hW6GtSUMkNBqhDHVhLr',
    890.30,
    445,
    678,
    1,
    '12.50',
    23,
    '8.40',
    3,
    '95.20',
    NOW() - INTERVAL 8 HOUR
);

-- Insert user relationships
INSERT INTO `user_relationships` (from_user_id, relationship_type, to_user_id, strength_score, interaction_count) VALUES
-- Alice follows Bob and Carol
(1, 'FOLLOWS', 2, 3.5, 45),
(1, 'FOLLOWS', 3, 5.0, 89),

-- Bob follows Alice and David
(2, 'FOLLOWS', 1, 2.0, 12),
(2, 'FOLLOWS', 4, 1.5, 8),

-- Carol follows Alice and Emma
(3, 'FOLLOWS', 1, 4.0, 67),
(3, 'FOLLOWS', 5, 2.5, 23),

-- David follows everyone
(4, 'FOLLOWS', 1, 1.0, 5),
(4, 'FOLLOWS', 2, 1.0, 3),
(4, 'FOLLOWS', 3, 1.0, 7),

-- Emma follows and collaborates with Carol
(5, 'FOLLOWS', 3, 3.0, 34),
(5, 'COLLABORATES', 3, 4.5, 12);

-- Note: Circles will be created via smart contracts
-- The contract address and circle_id will be added after deployment
