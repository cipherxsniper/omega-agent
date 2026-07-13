-- ==========================================
-- 004_INDEXES_AND_VIEWS.SQL
-- Part of OMEGA AGENT Database Schema
-- All major indexes, partitioning, and 20+ materialized views for $86B scale performance
-- ==========================================

-- INDEXES FOR $86 BILLION SCALE QUERY PERFORMANCE
CREATE INDEX idx_nft_tokens_owner ON nft_tokens(owner_id);
CREATE INDEX idx_nft_tokens_collection ON nft_tokens(collection_id);
CREATE INDEX idx_nft_listings_active ON nft_listings(token_id, price) WHERE status = 'active';
CREATE INDEX idx_nft_sales_token_price ON nft_sales(token_id, price DESC);
CREATE INDEX idx_nft_sales_seller_buyer ON nft_sales(seller_id, buyer_id);
CREATE INDEX idx_financial_transactions_acc ON financial_transactions(source_account_id, destination_account_id, amount);
CREATE INDEX idx_financial_ledger_acc_ts ON financial_ledger(account_id, created_at DESC);
CREATE INDEX idx_agent_memory_lookup ON agent_memory(agent_id, importance DESC);
CREATE INDEX idx_agent_actions_status ON agent_actions(agent_id, status);
CREATE INDEX idx_api_requests_key_path ON api_requests(api_key_id, path, created_at DESC);
CREATE INDEX idx_analytics_events_name_ts ON analytics_events(event_name, created_at DESC);
CREATE INDEX idx_search_vector ON search_index USING gin(search_vector);
CREATE INDEX idx_events_type_created ON events(event_type, created_at DESC);
CREATE INDEX idx_discord_messages_ch ON discord_messages(channel_id, created_at DESC);
CREATE INDEX idx_telegram_messages_ch ON telegram_messages(chat_id, created_at DESC);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);

-- 20+ MATERIALIZED VIEWS FOR COMMON ANALYTICS/OPERATIONS

-- 1. mv_collection_stats
CREATE MATERIALIZED VIEW mv_collection_stats AS
SELECT 
    c.id AS collection_id,
    c.name,
    COUNT(t.id) AS total_items,
    COALESCE(SUM(s.price), 0) AS total_volume,
    COALESCE(MIN(l.price), 0) AS floor_price,
    COALESCE(AVG(s.price), 0) AS average_price,
    COUNT(DISTINCT t.owner_id) AS unique_owners
FROM nft_collections c
LEFT JOIN nft_tokens t ON t.collection_id = c.id AND t.is_burnt = FALSE
LEFT JOIN nft_listings l ON l.token_id = t.id AND l.status = 'active'
LEFT JOIN nft_sales s ON s.token_id = t.id
GROUP BY c.id, c.name;
CREATE UNIQUE INDEX idx_mv_collection_stats_id ON mv_collection_stats(collection_id);

-- 2. mv_user_wealth
CREATE MATERIALIZED VIEW mv_user_wealth AS
SELECT 
    fa.owner_id AS user_id,
    COALESCE(SUM(fb.balance), 0) AS total_fiat_crypto_balance,
    COUNT(DISTINCT nt.id) AS total_nfts_owned
FROM financial_accounts fa
JOIN financial_balances fb ON fb.account_id = fa.id
LEFT JOIN nft_tokens nt ON nt.owner_id = fa.owner_id AND nt.is_burnt = FALSE
WHERE fa.owner_type = 'user'
GROUP BY fa.owner_id;
CREATE UNIQUE INDEX idx_mv_user_wealth ON mv_user_wealth(user_id);

-- 3. mv_agent_performance_summary
CREATE MATERIALIZED VIEW mv_agent_performance_summary AS
SELECT 
    ap.agent_id,
    a.name,
    COUNT(ap.id) AS total_metrics,
    AVG(ap.metric_value) FILTER (WHERE ap.metric_name = 'accuracy') AS avg_accuracy,
    AVG(ap.metric_value) FILTER (WHERE ap.metric_name = 'latency') AS avg_latency
FROM agent_performance ap
JOIN agents a ON a.id = ap.agent_id
GROUP BY ap.agent_id, a.name;
CREATE UNIQUE INDEX idx_mv_agent_perf ON mv_agent_performance_summary(agent_id);

-- 4. mv_daily_platform_revenue
CREATE MATERIALIZED VIEW mv_daily_platform_revenue AS
SELECT 
    DATE_TRUNC('day', created_at) AS day,
    source_type,
    SUM(amount) AS total_revenue,
    currency
FROM nft_platform_revenue
GROUP BY DATE_TRUNC('day', created_at), source_type, currency;
CREATE UNIQUE INDEX idx_mv_daily_rev ON mv_daily_platform_revenue(day, source_type, currency);

-- 5. mv_leaderboard_rankings
CREATE MATERIALIZED VIEW mv_leaderboard_rankings AS
SELECT 
    ol.agent_id,
    a.name,
    ol.aggregate_score,
    ol.rank,
    ol.updated_at
FROM oracle_leaderboard ol
JOIN agents a ON a.id = ol.agent_id;
CREATE UNIQUE INDEX idx_mv_leaderboard ON mv_leaderboard_rankings(agent_id);

-- 6. mv_active_listings
CREATE MATERIALIZED VIEW mv_active_listings AS
SELECT 
    l.id AS listing_id,
    l.token_id,
    l.price,
    l.currency,
    l.seller_id,
    l.expires_at
FROM nft_listings l
WHERE l.status = 'active';
CREATE UNIQUE INDEX idx_mv_active_list ON mv_active_listings(listing_id);

-- 7. mv_top_bids
CREATE MATERIALIZED VIEW mv_top_bids AS
SELECT DISTINCT ON (auction_id)
    id AS bid_id,
    auction_id,
    bidder_id,
    amount,
    created_at
FROM nft_bids
ORDER BY auction_id, amount DESC, created_at ASC;
CREATE UNIQUE INDEX idx_mv_top_bids ON mv_top_bids(auction_id);

-- 8. mv_nft_sales_daily_volume
CREATE MATERIALIZED VIEW mv_nft_sales_daily_volume AS
SELECT 
    DATE_TRUNC('day', created_at) AS day,
    COUNT(id) AS sales_count,
    SUM(price) AS total_volume,
    currency
FROM nft_sales
GROUP BY DATE_TRUNC('day', created_at), currency;
CREATE UNIQUE INDEX idx_mv_sales_daily ON mv_nft_sales_daily_volume(day, currency);

-- 9. mv_agent_goals_completion_rate
CREATE MATERIALIZED VIEW mv_agent_goals_completion_rate AS
SELECT 
    agent_id,
    COUNT(id) AS total_goals,
    COUNT(id) FILTER (WHERE status = 'completed') AS completed_goals,
    (COUNT(id) FILTER (WHERE status = 'completed')::decimal / COUNT(id)::decimal) * 100 AS completion_rate
FROM agent_goals
GROUP BY agent_id;
CREATE UNIQUE INDEX idx_mv_goals_rate ON mv_agent_goals_completion_rate(agent_id);

-- 10. mv_api_requests_hourly_load
CREATE MATERIALIZED VIEW mv_api_requests_hourly_load AS
SELECT 
    DATE_TRUNC('hour', created_at) AS hour,
    method,
    path,
    COUNT(id) AS request_count,
    AVG(latency_ms) AS avg_latency
FROM api_requests
GROUP BY DATE_TRUNC('hour', created_at), method, path;
CREATE UNIQUE INDEX idx_mv_api_load ON mv_api_requests_hourly_load(hour, method, path);

-- 11. mv_task_backlog
CREATE MATERIALIZED VIEW mv_task_backlog AS
SELECT 
    status,
    priority,
    COUNT(id) AS task_count
FROM tasks
GROUP BY status, priority;
CREATE UNIQUE INDEX idx_mv_task_backlog ON mv_task_backlog(status, priority);

-- 12. mv_user_audit_count
CREATE MATERIALIZED VIEW mv_user_audit_count AS
SELECT 
    user_id,
    COUNT(id) AS total_actions,
    MAX(created_at) AS last_action_at
FROM user_audit
GROUP BY user_id;
CREATE UNIQUE INDEX idx_mv_user_audit ON mv_user_audit_count(user_id);

-- 13. mv_oracle_grade_distributions
CREATE MATERIALIZED VIEW mv_oracle_grade_distributions AS
SELECT 
    grade,
    COUNT(id) AS total_grades,
    AVG(score) AS average_score
FROM oracle_grades
GROUP BY grade;
CREATE UNIQUE INDEX idx_mv_grade_dist ON mv_oracle_grade_distributions(grade);

-- 14. mv_financial_ledger_aggregates
CREATE MATERIALIZED VIEW mv_financial_ledger_aggregates AS
SELECT 
    account_id,
    COUNT(id) AS entry_count,
    SUM(amount) AS net_flow
FROM financial_ledger
GROUP BY account_id;
CREATE UNIQUE INDEX idx_mv_ledger_agg ON mv_financial_ledger_aggregates(account_id);

-- 15. mv_knowledge_base_density
CREATE MATERIALIZED VIEW mv_knowledge_base_density AS
SELECT 
    kb_id,
    COUNT(DISTINCT source_node_id) AS unique_source_nodes,
    COUNT(id) AS total_edges
FROM knowledge_edges
GROUP BY kb_id;
CREATE UNIQUE INDEX idx_mv_kb_density ON mv_knowledge_base_density(kb_id);

-- 16. mv_unresolved_compliance_violations
CREATE MATERIALIZED VIEW mv_unresolved_compliance_violations AS
SELECT 
    cv.id AS violation_id,
    cv.check_id,
    cv.severity,
    cv.created_at,
    cc.checked_entity_type,
    cc.checked_entity_id
FROM compliance_violations cv
JOIN compliance_checks cc ON cc.id = cv.check_id
WHERE cv.remediated = FALSE;
CREATE UNIQUE INDEX idx_mv_unresolved_comp ON mv_unresolved_compliance_violations(violation_id);

-- 17. mv_discord_activity
CREATE MATERIALIZED VIEW mv_discord_activity AS
SELECT 
    channel_id,
    sender_id,
    COUNT(id) AS total_messages,
    MAX(created_at) AS last_message_at
FROM discord_messages
GROUP BY channel_id, sender_id;
CREATE UNIQUE INDEX idx_mv_discord_act ON mv_discord_activity(channel_id, sender_id);

-- 18. mv_telegram_activity
CREATE MATERIALIZED VIEW mv_telegram_activity AS
SELECT 
    chat_id,
    sender_id,
    COUNT(id) AS total_messages,
    MAX(created_at) AS last_message_at
FROM telegram_messages
GROUP BY chat_id, sender_id;
CREATE UNIQUE INDEX idx_mv_tg_act ON mv_telegram_activity(chat_id, sender_id);

-- 19. mv_twitter_engagement
CREATE MATERIALIZED VIEW mv_twitter_engagement AS
SELECT 
    account_id,
    COUNT(id) AS total_tweets,
    SUM(likes_count) AS total_likes,
    SUM(retweets_count) AS total_retweets
FROM twitter_tweets
GROUP BY account_id;
CREATE UNIQUE INDEX idx_mv_twitter_eng ON mv_twitter_engagement(account_id);

-- 20. mv_ab_test_metrics
CREATE MATERIALIZED VIEW mv_ab_test_metrics AS
SELECT 
    test_id,
    assigned_variant,
    COUNT(id) AS allocation_count
FROM ab_test_allocations
GROUP BY test_id, assigned_variant;
CREATE UNIQUE INDEX idx_mv_ab_test ON mv_ab_test_metrics(test_id, assigned_variant);

-- 21. mv_security_threat_levels
CREATE MATERIALIZED VIEW mv_security_threat_levels AS
SELECT 
    source_ip,
    threat_level,
    COUNT(id) AS incident_count,
    MAX(created_at) AS last_seen_at
FROM security_events
GROUP BY source_ip, threat_level;
CREATE UNIQUE INDEX idx_mv_sec_threat ON mv_security_threat_levels(source_ip, threat_level);


-- PARTITIONING STRATEGY FOR LARGE SCALE SYSTEM TABLES
-- Because we need high throughput for transactions, logs, and events, we suggest partitioning
-- the following major system tables. PostgreSql native partitioning syntax:

/*
CREATE TABLE financial_ledger_partitioned (
    id UUID,
    transaction_id UUID NOT NULL,
    account_id UUID NOT NULL,
    amount DECIMAL(38,18) NOT NULL,
    balance_snapshot DECIMAL(38,18) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE api_requests_partitioned (
    id UUID,
    api_key_id UUID,
    method VARCHAR(10) NOT NULL,
    path TEXT NOT NULL,
    status_code INTEGER NOT NULL,
    latency_ms INTEGER,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE analytics_events_partitioned (
    id UUID,
    user_id UUID,
    event_name VARCHAR(100) NOT NULL,
    properties JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);
*/
