-- ==========================================
-- 002_NFT_TABLES.SQL
-- Part of OMEGA AGENT Database Schema
-- Tables 51 to 100 covering: NFT collections, tokens, market, bids, ownership, blocks/contracts
-- All monetary values as DECIMAL(38,18)
-- ==========================================

-- 51. nft_collections
CREATE TABLE nft_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    symbol VARCHAR(50) NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL,
    owner_id UUID NOT NULL,
    total_supply INTEGER DEFAULT 0,
    mint_price DECIMAL(38,18) DEFAULT 0.000000000000000000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 52. nft_tokens
CREATE TABLE nft_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    token_id VARCHAR(255) NOT NULL, -- unique ID or address identifier
    owner_id UUID NOT NULL,
    creator_id UUID NOT NULL,
    token_uri TEXT,
    is_burnt BOOLEAN DEFAULT FALSE,
    minted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (collection_id, token_id)
);

-- 53. nft_metadata
CREATE TABLE nft_metadata (
    token_id UUID PRIMARY KEY REFERENCES nft_tokens(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    external_url TEXT,
    raw_metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 54. nft_attributes
CREATE TABLE nft_attributes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    trait_type VARCHAR(100) NOT NULL,
    value VARCHAR(255) NOT NULL,
    display_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 55. nft_media
CREATE TABLE nft_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 56. nft_listings
CREATE TABLE nft_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL,
    price DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'sold', 'cancelled', 'expired'
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 57. nft_auctions
CREATE TABLE nft_auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL,
    reserve_price DECIMAL(38,18) NOT NULL,
    buyout_price DECIMAL(38,18),
    currency VARCHAR(10) DEFAULT 'ETH',
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 58. nft_bids
CREATE TABLE nft_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES nft_auctions(id) ON DELETE CASCADE,
    bidder_id UUID NOT NULL,
    amount DECIMAL(38,18) NOT NULL,
    status VARCHAR(50) DEFAULT 'placed', -- 'placed', 'won', 'refunded'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 59. nft_sales
CREATE TABLE nft_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL,
    buyer_id UUID NOT NULL,
    price DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    fee_amount DECIMAL(38,18) DEFAULT 0.000000000000000000,
    royalty_amount DECIMAL(38,18) DEFAULT 0.000000000000000000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 60. nft_offers
CREATE TABLE nft_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    offerer_id UUID NOT NULL,
    amount DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'expired'
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 61. nft_royalties
CREATE TABLE nft_royalties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL,
    percentage DECIMAL(5,2) NOT NULL, -- e.g. 5.50 for 5.5%
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 62. nft_royalty_payments
CREATE TABLE nft_royalty_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES nft_sales(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL,
    amount DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 63. nft_creators
CREATE TABLE nft_creators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 64. nft_creator_splits
CREATE TABLE nft_creator_splits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL,
    split_percentage DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 65. nft_ownership
CREATE TABLE nft_ownership (
    token_id UUID PRIMARY KEY REFERENCES nft_tokens(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL,
    quantity DECIMAL(38,18) DEFAULT 1.000000000000000000, -- for ERC1155 style support
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 66. nft_ownership_history
CREATE TABLE nft_ownership_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    previous_owner_id UUID NOT NULL,
    new_owner_id UUID NOT NULL,
    quantity DECIMAL(38,18) DEFAULT 1.000000000000000000,
    transferred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 67. nft_transfers
CREATE TABLE nft_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    from_address VARCHAR(255) NOT NULL,
    to_address VARCHAR(255) NOT NULL,
    quantity DECIMAL(38,18) DEFAULT 1.000000000000000000,
    tx_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 68. nft_burns
CREATE TABLE nft_burns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    burnt_by UUID NOT NULL,
    tx_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 69. nft_mints
CREATE TABLE nft_mints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    minter_id UUID NOT NULL,
    mint_cost DECIMAL(38,18) DEFAULT 0.000000000000000000,
    tx_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 70. nft_wallets
CREATE TABLE nft_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL,
    wallet_address VARCHAR(255) UNIQUE NOT NULL,
    blockchain_network VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 71. nft_wallet_balances
CREATE TABLE nft_wallet_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES nft_wallets(id) ON DELETE CASCADE,
    token_address VARCHAR(255) NOT NULL, -- Native token or ERC20 address
    balance DECIMAL(38,18) DEFAULT 0.000000000000000000,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (wallet_id, token_address)
);

-- 72. nft_wallet_transactions
CREATE TABLE nft_wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES nft_wallets(id) ON DELETE CASCADE,
    tx_hash VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(38,18) NOT NULL,
    direction VARCHAR(10) NOT NULL, -- 'inbound', 'outbound'
    fee DECIMAL(38,18) DEFAULT 0.000000000000000000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 73. nft_marketplace_fees
CREATE TABLE nft_marketplace_fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fee_name VARCHAR(100) UNIQUE NOT NULL,
    fee_percentage DECIMAL(5,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 74. nft_platform_revenue
CREATE TABLE nft_platform_revenue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_type VARCHAR(100) NOT NULL, -- 'marketplace_fee', 'mint_fee'
    amount DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 75. nft_categories
CREATE TABLE nft_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 76. nft_tags
CREATE TABLE nft_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag_name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 77. nft_tag_mappings
CREATE TABLE nft_tag_mappings (
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES nft_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (token_id, tag_id)
);

-- 78. nft_likes
CREATE TABLE nft_likes (
    user_id UUID NOT NULL,
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, token_id)
);

-- 79. nft_views
CREATE TABLE nft_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    viewer_id UUID, -- optional signed in user
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 80. nft_follows
CREATE TABLE nft_follows (
    follower_id UUID NOT NULL,
    followed_id UUID NOT NULL, -- can be user or agent
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id)
);

-- 81. nft_collections_follows
CREATE TABLE nft_collections_follows (
    user_id UUID NOT NULL,
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, collection_id)
);

-- 82. nft_reports
CREATE TABLE nft_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL,
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'resolved', 'dismissed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 83. nft_moderation
CREATE TABLE nft_moderation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID REFERENCES nft_reports(id) ON DELETE SET NULL,
    moderator_id UUID NOT NULL,
    action_taken VARCHAR(100) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 84. nft_ban_list
CREATE TABLE nft_ban_list (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID UNIQUE REFERENCES nft_tokens(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    banned_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 85. nft_analytics
CREATE TABLE nft_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    volume_traded DECIMAL(38,18) DEFAULT 0.000000000000000000,
    floor_price DECIMAL(38,18) DEFAULT 0.000000000000000000,
    avg_price DECIMAL(38,18) DEFAULT 0.000000000000000000,
    total_sales INTEGER DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 86. nft_price_history
CREATE TABLE nft_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    price DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 87. nft_floor_prices
CREATE TABLE nft_floor_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    floor_price DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 88. nft_volume
CREATE TABLE nft_volume (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    daily_volume DECIMAL(38,18) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETH',
    recorded_date DATE NOT NULL,
    UNIQUE (collection_id, recorded_date)
);

-- 89. blockchain_networks
CREATE TABLE blockchain_networks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    chain_id BIGINT UNIQUE NOT NULL,
    rpc_url TEXT NOT NULL,
    explorer_url TEXT,
    native_currency VARCHAR(10) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 90. blockchain_contracts
CREATE TABLE blockchain_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id UUID NOT NULL REFERENCES blockchain_networks(id) ON DELETE CASCADE,
    contract_address VARCHAR(255) NOT NULL,
    contract_type VARCHAR(100) NOT NULL, -- 'ERC721', 'ERC1155', 'Marketplace'
    abi TEXT,
    deployed_block BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (network_id, contract_address)
);

-- 91. blockchain_transactions
CREATE TABLE blockchain_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id UUID NOT NULL REFERENCES blockchain_networks(id) ON DELETE CASCADE,
    tx_hash VARCHAR(255) NOT NULL,
    from_address VARCHAR(255) NOT NULL,
    to_address VARCHAR(255),
    gas_used DECIMAL(38,18),
    gas_price DECIMAL(38,18),
    status VARCHAR(50) DEFAULT 'pending',
    block_number BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (network_id, tx_hash)
);

-- 92. blockchain_blocks
CREATE TABLE blockchain_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id UUID NOT NULL REFERENCES blockchain_networks(id) ON DELETE CASCADE,
    block_number BIGINT NOT NULL,
    block_hash VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (network_id, block_number)
);

-- 93. smart_contracts
CREATE TABLE smart_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    source_code TEXT,
    compiler_version VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 94. contract_events
CREATE TABLE contract_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES blockchain_contracts(id) ON DELETE CASCADE,
    event_name VARCHAR(100) NOT NULL,
    event_data JSONB,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 95. contract_calls
CREATE TABLE contract_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES blockchain_contracts(id) ON DELETE CASCADE,
    method_name VARCHAR(100) NOT NULL,
    arguments JSONB,
    caller_address VARCHAR(255) NOT NULL,
    result JSONB,
    success BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 96. nft_metadata_history
CREATE TABLE nft_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    old_metadata JSONB,
    new_metadata JSONB,
    updated_by UUID NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 97. nft_whitelists
CREATE TABLE nft_whitelists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    max_mints INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 98. nft_airdrops
CREATE TABLE nft_airdrops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    recipient_address VARCHAR(255) NOT NULL,
    quantity DECIMAL(38,18) DEFAULT 1.000000000000000000,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 99. nft_staking_pools
CREATE TABLE nft_staking_pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id) ON DELETE CASCADE,
    reward_rate DECIMAL(38,18) NOT NULL, -- reward per block/day
    reward_token VARCHAR(255) NOT NULL,
    total_staked INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 100. nft_staked_tokens
CREATE TABLE nft_staked_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL REFERENCES nft_staking_pools(id) ON DELETE CASCADE,
    token_id UUID NOT NULL REFERENCES nft_tokens(id) ON DELETE CASCADE,
    staker_id UUID NOT NULL,
    staked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    unstaked_at TIMESTAMP WITH TIME ZONE
);
