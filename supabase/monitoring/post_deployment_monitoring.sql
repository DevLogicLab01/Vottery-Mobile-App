-- ============================================================
-- POST-DEPLOYMENT MONITORING QUERIES
-- Run after deploying migrations to production
-- Monitors: errors, performance, indexes, cache, connections, bloat
-- ============================================================

\echo '======================================================'
\echo 'POST-DEPLOYMENT MONITORING REPORT'
\echo '======================================================'
\echo ''

-- ============================================================
-- 1. REAL-TIME ERROR MONITORING
-- ============================================================
\echo '--- 1. Database Error Statistics ---'

SELECT
  datname AS database,
  xact_commit AS transactions_committed,
  xact_rollback AS transactions_rolled_back,
  CASE
    WHEN xact_commit + xact_rollback > 0
    THEN ROUND(xact_rollback::NUMERIC / (xact_commit + xact_rollback) * 100, 4)
    ELSE 0
  END AS rollback_rate_pct,
  deadlocks,
  conflicts,
  temp_files,
  pg_size_pretty(temp_bytes) AS temp_data_size
FROM pg_stat_database
WHERE datname = current_database();

-- ============================================================
-- 2. QUERY PERFORMANCE MONITORING
-- ============================================================
\echo ''
\echo '--- 2. Top 20 Slowest Queries (pg_stat_statements) ---'

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') THEN
    RAISE NOTICE 'pg_stat_statements available - run: SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;';
  ELSE
    RAISE NOTICE 'pg_stat_statements not available - enable for query monitoring';
  END IF;
END $$;

-- Fallback: Active query monitoring
SELECT
  pid,
  state,
  ROUND(EXTRACT(EPOCH FROM (NOW() - query_start))::NUMERIC, 2) AS query_duration_seconds,
  LEFT(query, 100) AS query_preview,
  wait_event_type,
  wait_event
FROM pg_stat_activity
WHERE state != 'idle'
  AND query NOT LIKE '%pg_stat_activity%'
  AND query_start IS NOT NULL
ORDER BY query_duration_seconds DESC
LIMIT 10;

-- ============================================================
-- 3. INDEX USAGE MONITORING
-- ============================================================
\echo ''
\echo '--- 3. Index Usage Statistics ---'

SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS index_scans,
  idx_tup_read AS tuples_read,
  idx_tup_fetch AS tuples_fetched,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;

-- Unused indexes (potential cleanup candidates)
\echo ''
\echo '--- 3b. Potentially Unused Indexes (0 scans) ---'

SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  idx_scan AS scans_since_reset
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan = 0
  AND indexname NOT LIKE '%pkey%'
  AND indexname NOT LIKE '%unique%'
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 10;

-- ============================================================
-- 4. CACHE HIT RATE MONITORING
-- ============================================================
\echo ''
\echo '--- 4. Cache Hit Rate ---'

SELECT
  'Table Cache Hit Rate' AS metric,
  ROUND(
    SUM(heap_blks_hit)::NUMERIC /
    NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0) * 100,
    2
  ) AS hit_rate_pct,
  CASE
    WHEN ROUND(SUM(heap_blks_hit)::NUMERIC / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0) * 100, 2) >= 95
    THEN '✅ EXCELLENT'
    WHEN ROUND(SUM(heap_blks_hit)::NUMERIC / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0) * 100, 2) >= 90
    THEN '⚠️ ACCEPTABLE'
    ELSE '❌ NEEDS ATTENTION'
  END AS status
FROM pg_statio_user_tables
WHERE schemaname = 'public'

UNION ALL

SELECT
  'Index Cache Hit Rate' AS metric,
  ROUND(
    SUM(idx_blks_hit)::NUMERIC /
    NULLIF(SUM(idx_blks_hit) + SUM(idx_blks_read), 0) * 100,
    2
  ) AS hit_rate_pct,
  CASE
    WHEN ROUND(SUM(idx_blks_hit)::NUMERIC / NULLIF(SUM(idx_blks_hit) + SUM(idx_blks_read), 0) * 100, 2) >= 95
    THEN '✅ EXCELLENT'
    WHEN ROUND(SUM(idx_blks_hit)::NUMERIC / NULLIF(SUM(idx_blks_hit) + SUM(idx_blks_read), 0) * 100, 2) >= 90
    THEN '⚠️ ACCEPTABLE'
    ELSE '❌ NEEDS ATTENTION'
  END AS status
FROM pg_statio_user_indexes
WHERE schemaname = 'public'

UNION ALL

SELECT
  'Database Cache Hit Rate' AS metric,
  ROUND(
    SUM(blks_hit)::NUMERIC / NULLIF(SUM(blks_hit) + SUM(blks_read), 0) * 100,
    2
  ) AS hit_rate_pct,
  CASE
    WHEN ROUND(SUM(blks_hit)::NUMERIC / NULLIF(SUM(blks_hit) + SUM(blks_read), 0) * 100, 2) >= 95
    THEN '✅ EXCELLENT'
    WHEN ROUND(SUM(blks_hit)::NUMERIC / NULLIF(SUM(blks_hit) + SUM(blks_read), 0) * 100, 2) >= 90
    THEN '⚠️ ACCEPTABLE'
    ELSE '❌ NEEDS ATTENTION'
  END AS status
FROM pg_stat_database
WHERE datname = current_database();

-- ============================================================
-- 5. CONNECTION POOL MONITORING
-- ============================================================
\echo ''
\echo '--- 5. Connection Pool Status ---'

SELECT
  state,
  COUNT(*) AS connection_count,
  ROUND(COUNT(*)::NUMERIC / (SELECT setting::INT FROM pg_settings WHERE name = 'max_connections') * 100, 2) AS pct_of_max
FROM pg_stat_activity
GROUP BY state
ORDER BY connection_count DESC;

SELECT
  'Max Connections' AS setting,
  setting AS value
FROM pg_settings
WHERE name = 'max_connections'

UNION ALL

SELECT
  'Total Active Connections',
  COUNT(*)::TEXT
FROM pg_stat_activity
WHERE state != 'idle';

-- ============================================================
-- 6. TABLE BLOAT MONITORING
-- ============================================================
\echo ''
\echo '--- 6. Table Size and Bloat (Top 20 by Size) ---'

SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
  pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS table_size,
  pg_size_pretty(
    pg_total_relation_size(schemaname || '.' || tablename) -
    pg_relation_size(schemaname || '.' || tablename)
  ) AS index_size,
  n_live_tup AS live_rows,
  n_dead_tup AS dead_rows,
  CASE
    WHEN n_live_tup > 0
    THEN ROUND(n_dead_tup::NUMERIC / n_live_tup * 100, 2)
    ELSE 0
  END AS dead_row_pct
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC
LIMIT 20;

-- ============================================================
-- 7. RLS POLICY HEALTH CHECK
-- ============================================================
\echo ''
\echo '--- 7. RLS Policy Health ---'

SELECT
  COUNT(*) AS total_policies,
  COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) AS select_policies,
  COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) AS insert_policies,
  COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) AS update_policies,
  COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) AS delete_policies,
  COUNT(CASE WHEN cmd = 'ALL' THEN 1 END) AS all_policies
FROM pg_policies
WHERE schemaname = 'public';

SELECT
  COUNT(*) AS tables_with_rls,
  (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') AS total_tables,
  ROUND(
    COUNT(*)::NUMERIC /
    NULLIF((SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public'), 0) * 100,
    1
  ) AS rls_coverage_pct
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relrowsecurity = true;

-- ============================================================
-- 8. MATERIALIZED VIEW FRESHNESS
-- ============================================================
\echo ''
\echo '--- 8. Materialized View Status ---'

SELECT
  schemaname,
  matviewname,
  hasindexes AS has_indexes,
  ispopulated AS is_populated
FROM pg_matviews
WHERE schemaname = 'public'
ORDER BY matviewname;

\echo ''
\echo '======================================================'
\echo 'POST-DEPLOYMENT MONITORING REPORT COMPLETE'
\echo 'Review metrics above against thresholds:'
\echo '  - Cache hit rate: >= 95%'
\echo '  - Error rate: < 0.1%'
\echo '  - Connection usage: < 80% of max'
\echo '  - Dead row ratio: < 10%'
\echo '======================================================'
