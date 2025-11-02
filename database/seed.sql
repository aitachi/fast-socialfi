-- Fast SocialFi Database Seed Data
-- Test data for development and testing

-- ============================================
-- 1. 测试用户数据
-- ============================================

INSERT INTO users (wallet_address, username, display_name, bio, avatar_url, verified, reputation_score) VALUES
('0x1234567890123456789012345678901234567890', 'alice_crypto', 'Alice', 'Web3 enthusiast | NFT collector | DeFi lover', 'https://i.pravatar.cc/150?img=1', true, 950),
('0x2345678901234567890123456789012345678901', 'bob_defi', 'Bob', 'DeFi developer | Smart contract expert', 'https://i.pravatar.cc/150?img=2', true, 850),
('0x3456789012345678901234567890123456789012', 'charlie_nft', 'Charlie', 'NFT artist | Digital creator', 'https://i.pravatar.cc/150?img=3', false, 600),
('0x4567890123456789012345678901234567890123', 'diana_dao', 'Diana', 'DAO governance | Community builder', 'https://i.pravatar.cc/150?img=4', true, 780),
('0x5678901234567890123456789012345678901234', 'eve_trader', 'Eve', 'Crypto trader | Market analyst', 'https://i.pravatar.cc/150?img=5', false, 520),
('0x6789012345678901234567890123456789012345', 'frank_dev', 'Frank', 'Full-stack Web3 developer', 'https://i.pravatar.cc/150?img=6', false, 450),
('0x7890123456789012345678901234567890123456', 'grace_investor', 'Grace', 'Venture capitalist | Angel investor', 'https://i.pravatar.cc/150?img=7', true, 890),
('0x8901234567890123456789012345678901234567', 'henry_metaverse', 'Henry', 'Metaverse explorer | VR enthusiast', 'https://i.pravatar.cc/150?img=8', false, 380),
('0x9012345678901234567890123456789012345678', 'iris_security', 'Iris', 'Security researcher | Bug bounty hunter', 'https://i.pravatar.cc/150?img=9', true, 920),
('0x0123456789012345678901234567890123456789', 'jack_miner', 'Jack', 'Crypto miner | Hardware enthusiast', 'https://i.pravatar.cc/150?img=10', false, 410);

-- ============================================
-- 2. 关注关系数据
-- ============================================

INSERT INTO follows (follower_id, following_id) VALUES
-- Alice follows everyone
(1, 2), (1, 3), (1, 4), (1, 5), (1, 6),
-- Bob follows some
(2, 1), (2, 3), (2, 7), (2, 9),
-- Charlie follows artists and creators
(3, 1), (3, 4), (3, 8),
-- Diana follows governance related
(4, 1), (4, 2), (4, 7),
-- Cross follows
(5, 1), (5, 2), (6, 1), (6, 2), (6, 3),
(7, 1), (7, 2), (7, 4), (7, 9),
(8, 1), (8, 3), (9, 1), (9, 2), (9, 6),
(10, 1), (10, 2), (10, 5);

-- ============================================
-- 3. 话题标签数据
-- ============================================

INSERT INTO hashtags (tag, tag_normalized, post_count, trend_score, description) VALUES
('Web3', 'web3', 0, 95.5, 'Web3 technology and decentralization'),
('DeFi', 'defi', 0, 92.3, 'Decentralized Finance'),
('NFT', 'nft', 0, 88.7, 'Non-Fungible Tokens'),
('DAO', 'dao', 0, 85.2, 'Decentralized Autonomous Organizations'),
('Ethereum', 'ethereum', 0, 91.8, 'Ethereum blockchain'),
('Bitcoin', 'bitcoin', 0, 89.4, 'Bitcoin cryptocurrency'),
('Metaverse', 'metaverse', 0, 78.6, 'Virtual worlds and metaverse'),
('SmartContracts', 'smartcontracts', 0, 82.1, 'Smart contract development'),
('Crypto', 'crypto', 0, 94.2, 'Cryptocurrency in general'),
('Blockchain', 'blockchain', 0, 90.5, 'Blockchain technology');

-- ============================================
-- 4. 帖子数据
-- ============================================

INSERT INTO posts (author_id, content, media_urls, media_type, hashtags, visibility, moderation_status) VALUES
(1, 'Just minted my first NFT collection! Check it out on OpenSea. #NFT #Web3 #Crypto', '["https://picsum.photos/600/400?random=1"]', 'image', ARRAY['NFT', 'Web3', 'Crypto'], 'public', 'approved'),
(2, 'New DeFi protocol launch! APY is insane right now. DYOR! #DeFi #Ethereum #Yield', '["https://picsum.photos/600/400?random=2"]', 'image', ARRAY['DeFi', 'Ethereum', 'Yield'], 'public', 'approved'),
(3, 'Working on a new generative art project. Here''s a sneak peek! #NFT #Art #GenerativeArt', '["https://picsum.photos/600/400?random=3", "https://picsum.photos/600/400?random=4"]', 'image', ARRAY['NFT', 'Art', 'GenerativeArt'], 'public', 'approved'),
(4, 'DAO governance proposal: Should we expand to Layer 2? Vote now! #DAO #Governance #Ethereum', '[]', 'text', ARRAY['DAO', 'Governance', 'Ethereum'], 'public', 'approved'),
(5, 'Market analysis: BTC breaking resistance at $45k. Bull run incoming? #Bitcoin #Crypto #Trading', '["https://picsum.photos/600/400?random=5"]', 'image', ARRAY['Bitcoin', 'Crypto', 'Trading'], 'public', 'approved'),
(1, 'GM everyone! What are you building today? #Web3 #GM', '[]', 'text', ARRAY['Web3', 'GM'], 'public', 'approved'),
(6, 'Deployed my first smart contract on mainnet! Feeling excited and nervous 😅 #SmartContracts #Ethereum #Dev', '[]', 'text', ARRAY['SmartContracts', 'Ethereum', 'Dev'], 'public', 'approved'),
(7, 'Just invested in 5 new Web3 startups. The future is decentralized! #Web3 #Venture #Startup', '[]', 'text', ARRAY['Web3', 'Venture', 'Startup'], 'public', 'approved'),
(8, 'Exploring the metaverse on Decentraland. The virtual real estate market is wild! #Metaverse #VR #Decentraland', '["https://picsum.photos/600/400?random=6"]', 'image', ARRAY['Metaverse', 'VR', 'Decentraland'], 'public', 'approved'),
(9, 'Found a critical vulnerability in a major DeFi protocol. Responsible disclosure in progress. #Security #DeFi #BugBounty', '[]', 'text', ARRAY['Security', 'DeFi', 'BugBounty'], 'public', 'approved'),
(2, 'Thread: How to get started with DeFi in 2024 🧵\n\n1. Get a Web3 wallet\n2. Buy some ETH\n3. Try Uniswap\n4. Explore yield farming\n\n#DeFi #Tutorial', '[]', 'text', ARRAY['DeFi', 'Tutorial'], 'public', 'approved'),
(3, 'New drop alert! 100 unique 1/1 NFTs dropping this weekend. Set your alarms! ⏰ #NFT #NFTDrop #CryptoArt', '["https://picsum.photos/600/400?random=7"]', 'image', ARRAY['NFT', 'NFTDrop', 'CryptoArt'], 'public', 'approved'),
(4, 'Community call in 1 hour! We''ll discuss the roadmap for Q2. Join us! #DAO #Community', '[]', 'text', ARRAY['DAO', 'Community'], 'public', 'approved'),
(10, 'My mining rig hit 1000 MH/s today! Time to celebrate 🎉 #Mining #Crypto #ETH', '["https://picsum.photos/600/400?random=8"]', 'image', ARRAY['Mining', 'Crypto', 'ETH'], 'public', 'approved'),
(1, 'Thoughts on the current state of Web3 social media? We need better alternatives! #Web3 #SocialFi #Decentralization', '[]', 'text', ARRAY['Web3', 'SocialFi', 'Decentralization'], 'public', 'approved');

-- 更新帖子-话题关联
INSERT INTO post_hashtags (post_id, hashtag_id)
SELECT p.id, h.id
FROM posts p
CROSS JOIN hashtags h
WHERE h.tag = ANY(p.hashtags);

-- ============================================
-- 5. 评论数据
-- ============================================

INSERT INTO comments (post_id, author_id, content) VALUES
(1, 2, 'Amazing work! The artwork is stunning 🔥'),
(1, 3, 'Congrats on your first NFT! What''s the mint price?'),
(1, 4, 'Love the concept! Are you planning a series?'),
(2, 1, 'This looks interesting but be careful, always DYOR!'),
(2, 5, 'APY seems too good to be true. What''s the catch?'),
(3, 1, 'This is absolutely beautiful! Can''t wait to see the full collection'),
(3, 8, 'The color palette is amazing. What tools did you use?'),
(4, 1, 'Voted YES! Layer 2 is the future'),
(4, 2, 'We need to consider the costs first. Let''s do more research.'),
(5, 1, 'Great analysis! I''m bullish too 📈'),
(6, 2, 'GM! Building a new NFT marketplace today'),
(6, 3, 'GM! Working on some new art pieces'),
(7, 1, 'Congratulations! That''s a huge milestone!'),
(7, 2, 'Well done! Did you get it audited?'),
(8, 1, 'Smart investments! Which projects are you most excited about?');

-- 添加一些回复(子评论)
INSERT INTO comments (post_id, author_id, parent_id, content) VALUES
(1, 1, 2, 'Thank you so much! Means a lot coming from you!'),
(1, 1, 3, 'Mint price is 0.05 ETH. Limited to 1000 pieces.'),
(2, 2, 5, 'No catch, but it''s a new protocol so higher risk. Only invest what you can afford to lose.'),
(3, 3, 7, 'Thanks! I used Processing and Photoshop for post-processing.');

-- ============================================
-- 6. 点赞数据
-- ============================================

INSERT INTO likes (user_id, target_type, target_id) VALUES
-- Post likes
(1, 'post', 2), (1, 'post', 3), (1, 'post', 5), (1, 'post', 9),
(2, 'post', 1), (2, 'post', 3), (2, 'post', 7), (2, 'post', 11),
(3, 'post', 1), (3, 'post', 2), (3, 'post', 8), (3, 'post', 12),
(4, 'post', 1), (4, 'post', 2), (4, 'post', 4), (4, 'post', 13),
(5, 'post', 2), (5, 'post', 5), (5, 'post', 10), (5, 'post', 14),
(6, 'post', 1), (6, 'post', 7), (6, 'post', 11),
(7, 'post', 1), (7, 'post', 2), (7, 'post', 8),
(8, 'post', 3), (8, 'post', 9), (8, 'post', 12),
(9, 'post', 2), (9, 'post', 7), (9, 'post', 10),
(10, 'post', 5), (10, 'post', 14), (10, 'post', 15),
-- Comment likes
(1, 'comment', 1), (1, 'comment', 3), (1, 'comment', 6),
(2, 'comment', 2), (2, 'comment', 4), (2, 'comment', 7),
(3, 'comment', 1), (3, 'comment', 5), (3, 'comment', 8),
(4, 'comment', 2), (4, 'comment', 6), (4, 'comment', 9);

-- ============================================
-- 7. 收藏数据
-- ============================================

INSERT INTO bookmarks (user_id, post_id, folder_name) VALUES
(1, 2, 'DeFi Resources'),
(1, 3, 'Art Inspiration'),
(1, 11, 'Tutorials'),
(2, 1, 'NFT Ideas'),
(2, 7, 'Dev Resources'),
(3, 1, 'NFT Inspiration'),
(3, 12, 'My Collection'),
(4, 4, 'DAO Proposals'),
(4, 13, 'Community'),
(5, 2, 'Investment Ideas'),
(5, 5, 'Market Analysis');

-- ============================================
-- 8. 转发数据
-- ============================================

INSERT INTO reposts (user_id, post_id, comment) VALUES
(1, 2, 'This is exactly what we need in DeFi!'),
(2, 1, 'Supporting fellow creators! Check this out!'),
(3, 12, 'Don''t miss this drop!'),
(4, 4, 'Important governance decision. Please vote!'),
(5, 5, 'Solid analysis. Worth a read.'),
(7, 8, 'The future of work and play!');

-- ============================================
-- 9. NFT 元数据
-- ============================================

INSERT INTO nfts (token_id, contract_address, chain_id, owner_address, creator_address, name, description, image_url, attributes) VALUES
('1', '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', 1, '0x1234567890123456789012345678901234567890', '0x1234567890123456789012345678901234567890', 'Bored Ape #1', 'Bored Ape Yacht Club NFT', 'https://picsum.photos/400/400?random=11', '[{"trait_type": "Background", "value": "Blue"}, {"trait_type": "Fur", "value": "Gold"}]'),
('2', '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', 1, '0x1234567890123456789012345678901234567890', '0x1234567890123456789012345678901234567890', 'Bored Ape #2', 'Bored Ape Yacht Club NFT', 'https://picsum.photos/400/400?random=12', '[{"trait_type": "Background", "value": "Purple"}, {"trait_type": "Fur", "value": "Black"}]'),
('100', '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB', 1, '0x2345678901234567890123456789012345678901', '0x2345678901234567890123456789012345678901', 'CryptoPunk #100', 'CryptoPunk NFT', 'https://picsum.photos/400/400?random=13', '[{"trait_type": "Type", "value": "Alien"}, {"trait_type": "Accessory", "value": "3D Glasses"}]'),
('1', '0x60E4d786628Fea6478F785A6d7e704777c86a7c6', 1, '0x3456789012345678901234567890123456789012', '0x3456789012345678901234567890123456789012', 'Mutant Ape #1', 'Mutant Ape Yacht Club NFT', 'https://picsum.photos/400/400?random=14', '[{"trait_type": "Background", "value": "Green"}, {"trait_type": "Fur", "value": "Radioactive"}]'),
('5000', '0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B', 1, '0x4567890123456789012345678901234567890123', '0x4567890123456789012345678901234567890123', 'Clone X #5000', 'Clone X NFT by RTFKT', 'https://picsum.photos/400/400?random=15', '[{"trait_type": "DNA", "value": "Human"}, {"trait_type": "Eye Color", "value": "Blue"}]');

-- ============================================
-- 10. 区块链交易记录
-- ============================================

INSERT INTO transactions (tx_hash, chain_id, from_address, to_address, value, gas_used, gas_price, block_number, transaction_type, status, token_symbol, timestamp) VALUES
('0xabc123def456789012345678901234567890123456789012345678901234567890', 1, '0x1234567890123456789012345678901234567890', '0x2345678901234567890123456789012345678901', '1000000000000000000', '21000', '50000000000', 18500000, 'transfer', 'confirmed', 'ETH', NOW() - INTERVAL '1 hour'),
('0xdef456abc789012345678901234567890123456789012345678901234567890123', 1, '0x2345678901234567890123456789012345678901', '0x3456789012345678901234567890123456789012', '500000000000000000', '21000', '45000000000', 18500100, 'transfer', 'confirmed', 'ETH', NOW() - INTERVAL '30 minutes'),
('0x789012abc345678901234567890123456789012345678901234567890123456def', 1, '0x3456789012345678901234567890123456789012', '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', '0', '150000', '55000000000', 18500200, 'mint', 'confirmed', 'NFT', NOW() - INTERVAL '15 minutes'),
('0x345678def901234567890123456789012345678901234567890123456789012abc', 1, '0x4567890123456789012345678901234567890123', '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', '2000000000000000000', '180000', '60000000000', 18500300, 'swap', 'confirmed', 'ETH', NOW() - INTERVAL '5 minutes');

-- ============================================
-- 11. 代币余额
-- ============================================

INSERT INTO token_balances (wallet_address, token_address, chain_id, balance, symbol, decimals) VALUES
('0x1234567890123456789012345678901234567890', '0x0000000000000000000000000000000000000000', 1, '5000000000000000000', 'ETH', 18),
('0x1234567890123456789012345678901234567890', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', 1, '10000000000', 'USDC', 6),
('0x2345678901234567890123456789012345678901', '0x0000000000000000000000000000000000000000', 1, '3000000000000000000', 'ETH', 18),
('0x2345678901234567890123456789012345678901', '0xdAC17F958D2ee523a2206206994597C13D831ec7', 1, '50000000000', 'USDT', 6),
('0x3456789012345678901234567890123456789012', '0x0000000000000000000000000000000000000000', 1, '8000000000000000000', 'ETH', 18);

-- ============================================
-- 12. 通知数据
-- ============================================

INSERT INTO notifications (user_id, actor_id, type, title, content, target_type, target_id, is_read) VALUES
(1, 2, 'follow', 'New Follower', 'bob_defi started following you', 'user', 2, false),
(1, 3, 'like', 'New Like', 'charlie_nft liked your post', 'post', 1, false),
(1, 4, 'comment', 'New Comment', 'diana_dao commented on your post', 'post', 1, true),
(2, 1, 'follow', 'New Follower', 'alice_crypto started following you', 'user', 1, false),
(2, 5, 'like', 'New Like', 'eve_trader liked your post', 'post', 2, false),
(3, 1, 'like', 'New Like', 'alice_crypto liked your post', 'post', 3, true),
(3, 8, 'comment', 'New Comment', 'henry_metaverse commented on your post', 'post', 3, false),
(4, 1, 'follow', 'New Follower', 'alice_crypto started following you', 'user', 1, false),
(5, 2, 'mention', 'New Mention', 'You were mentioned in a post', 'post', 11, false);

-- ============================================
-- 13. 用户活动日志
-- ============================================

INSERT INTO user_activities (user_id, activity_type, target_type, target_id, ip_address) VALUES
(1, 'post_create', 'post', 1, '192.168.1.100'),
(1, 'post_like', 'post', 2, '192.168.1.100'),
(1, 'user_follow', 'user', 2, '192.168.1.100'),
(2, 'post_create', 'post', 2, '192.168.1.101'),
(2, 'comment_create', 'comment', 1, '192.168.1.101'),
(3, 'post_create', 'post', 3, '192.168.1.102'),
(3, 'post_like', 'post', 1, '192.168.1.102');

-- ============================================
-- 14. 更新计数器
-- ============================================

-- 更新用户帖子计数
UPDATE users u
SET post_count = (SELECT COUNT(*) FROM posts p WHERE p.author_id = u.id);

-- 更新话题标签帖子计数
UPDATE hashtags h
SET post_count = (SELECT COUNT(*) FROM post_hashtags ph WHERE ph.hashtag_id = h.id);

-- 显示统计信息
SELECT 'Database seeding completed!' as message;
SELECT 'Users created: ' || COUNT(*) as stat FROM users;
SELECT 'Posts created: ' || COUNT(*) as stat FROM posts;
SELECT 'Comments created: ' || COUNT(*) as stat FROM comments;
SELECT 'Follows created: ' || COUNT(*) as stat FROM follows;
SELECT 'Likes created: ' || COUNT(*) as stat FROM likes;
SELECT 'Hashtags created: ' || COUNT(*) as stat FROM hashtags;
SELECT 'NFTs created: ' || COUNT(*) as stat FROM nfts;
SELECT 'Transactions created: ' || COUNT(*) as stat FROM transactions;
SELECT 'Notifications created: ' || COUNT(*) as stat FROM notifications;
