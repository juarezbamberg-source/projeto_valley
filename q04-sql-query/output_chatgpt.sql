WITH 
-- ===============================================================
-- 1. Base data: join transactions, accounts, users for last complete month
--    Assumes typical columns: transaction_id, user_id, account_id, transaction_type, amount, status, created_at
--    accounts: account_id, user_id (if needed)
--    users: user_id, username, email
--    Filter to last complete month using CURRENT_DATE dynamically
-- ===============================================================
base AS (
    SELECT 
        t.transaction_id,
        t.user_id,
        t.account_id,
        t.transaction_type,
        t.amount,
        t.status,
        t.created_at,
        u.username,
        u.email
    FROM transactions t
    JOIN users u ON t.user_id = u.user_id
    JOIN accounts a ON t.account_id = a.account_id  -- included but not used further, ensures referential integrity
    WHERE t.created_at >= date_trunc('month', CURRENT_DATE) - INTERVAL '1 month'
      AND t.created_at <  date_trunc('month', CURRENT_DATE)
),
-- ===============================================================
-- 2. Aggregations by transaction type (débito, crédito, etc.)
--    Calculate: count, total amount, average amount, stddev, failure rate
-- ===============================================================
agg_by_type AS (
    SELECT 
        transaction_type,
        COUNT(*)                                               AS tx_count,
        SUM(amount)                                            AS total_amount,
        AVG(amount)::numeric(12,2)                             AS avg_amount,
        STDDEV_SAMP(amount)::numeric(12,2)                     AS stddev_amount,
        ROUND(
            SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)::numeric 
            / NULLIF(COUNT(*),0) * 100, 
        2)::numeric(5,2)                                       AS failure_rate_pct,
        COUNT(CASE WHEN status = 'failed' THEN 1 END)          AS failed_tx_count
    FROM base
    GROUP BY transaction_type
),
-- ===============================================================
-- 3. Anomaly detection:
--    For each transaction, compare its amount to the per-type average ± 2*stddev.
--    Identify transactions where:
--        amount > (avg + 2*stddev)  OR  failure_rate_pct > 5%
--    Also flag overall failure rate >5% per type (already in agg_by_type)
-- ===============================================================
anomalies AS (
    SELECT 
        b.transaction_id,
        b.user_id,
        b.transaction_type,
        b.amount,
        b.status,
        b.created_at,
        a.avg_amount,
        a.stddev_amount,
        a.failure_rate_pct,
        CASE 
            WHEN a.stddev_amount IS DISTINCT FROM 0 
                 AND b.amount > (a.avg_amount + 2 * a.stddev_amount)
            THEN 'High Value Anomaly'
            WHEN b.status = 'failed' 
            THEN 'Failed Transaction'
            ELSE NULL
        END AS anomaly_type,
        CASE 
            WHEN a.failure_rate_pct > 5 THEN 'High Failure Rate in Type'
            ELSE NULL
        END AS type_level_anomaly
    FROM base b
    LEFT JOIN agg_by_type a ON b.transaction_type = a.transaction_type
    WHERE (a.stddev_amount IS NOT NULL AND b.amount > (a.avg_amount + 2 * a.stddev_amount))
       OR b.status = 'failed'
       OR a.failure_rate_pct > 5
),
-- ===============================================================
-- 4. Top 10 users by total transaction volume (sum of amounts)
-- ===============================================================
top_users AS (
    SELECT 
        user_id,
        username,
        email,
        SUM(amount)                                          AS total_volume,
        COUNT(*)                                             AS tx_count,
        RANK() OVER (ORDER BY SUM(amount) DESC)              AS rank
    FROM base
    GROUP BY user_id, username, email
    LIMIT 10
),
-- ===============================================================
-- 5. Daily and weekly trends for the last complete month
--    Uses date_trunc to group by day and by week
-- ===============================================================
daily_trends AS (
    SELECT 
        DATE(created_at)                                     AS day,
        transaction_type,
        COUNT(*)                                             AS tx_count,
        SUM(amount)                                          AS daily_total
    FROM base
    GROUP BY day, transaction_type
    ORDER BY day
),
weekly_trends AS (
    SELECT 
        date_trunc('week', created_at)::DATE                 AS week_start,
        transaction_type,
        COUNT(*)                                             AS tx_count,
        SUM(amount)                                          AS weekly_total
    FROM base
    GROUP BY week_start, transaction_type
    ORDER BY week_start
)
-- ===============================================================
-- FINAL OUTPUT: Structured JSON report containing all CTEs
-- ===============================================================
SELECT jsonb_build_object(
    'report_month', to_char(date_trunc('month', CURRENT_DATE) - INTERVAL '1 month', 'YYYY-MM'),
    'aggregation_by_type', (SELECT jsonb_agg(row_to_json(agg_by_type.*)) FROM agg_by_type),
    'anomalies', (SELECT jsonb_agg(jsonb_build_object(
                     'transaction_id', a.transaction_id,
                     'user_id', a.user_id,
                     'type', a.transaction_type,
                     'amount', a.amount,
                     'status', a.status,
                     'anomaly', a.anomaly_type,
                     'type_level_anomaly', a.type_level_anomaly
                   )) FROM anomalies a),
    'top_10_users_by_volume', (SELECT jsonb_agg(jsonb_build_object(
                                  'rank', t.rank,
                                  'user_id', t.user_id,
                                  'username', t.username,
                                  'total_volume', t.total_volume,
                                  'tx_count', t.tx_count
                                )) FROM top_users t),
    'daily_trends', (SELECT jsonb_agg(row_to_json(d.*)) FROM daily_trends d),
    'weekly_trends', (SELECT jsonb_agg(row_to_json(w.*)) FROM weekly_trends w)
) AS monthly_report;

-- ===============================================================
-- PERFORMANCE SUGGESTIONS (comments only - no DDL):
-- 1. Indexes to consider (test with EXPLAIN ANALYZE):
--    CREATE INDEX idx_transactions_created_at ON transactions(created_at);
--    CREATE INDEX idx_transactions_type_status ON transactions(transaction_type, status);
--    CREATE INDEX idx_transactions_user_amount ON transactions(user_id, amount);
--    CREATE INDEX idx_users_user_id ON users(user_id);
--    CREATE INDEX idx_accounts_account_id ON accounts(account_id);
-- 2. Run: EXPLAIN ANALYZE <query> to identify full table scans.
-- 3. For very large datasets, consider partitioning transactions by month.
-- 4. Ensure work_mem is sufficient for hash aggregations.
-- 5. The CTE 'base' acts as a filter; materialize it if reused many times? 
--    PostgreSQL 12+ inlines CTEs by default, but for heavy reuse consider 
--    explicit temporary table if performance degrades.
-- ===============================================================