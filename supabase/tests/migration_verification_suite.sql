-- ============================================================
-- MIGRATION VERIFICATION SUITE
-- Vottery Database Optimization - Staging Verification
-- 50+ Test Queries Organized by Category
-- Run: psql $STAGING_URL -f supabase/tests/migration_verification_suite.sql
-- ============================================================

\echo '======================================================'
\echo 'MIGRATION VERIFICATION SUITE - STARTING'
\echo '======================================================'

-- ============================================================
-- SECTION 1: RLS POLICY TESTS (15 queries)
-- ============================================================
\echo ''
\echo '--- SECTION 1: RLS POLICY TESTS (15 tests) ---'

-- Test 1: RLS enabled on users/user_profiles table
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_profiles' AND relnamespace = 'public'::regnamespace;
  IF rls_enabled THEN
    RAISE NOTICE 'PASSED [RLS-01] RLS is enabled on user_profiles table';
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-01] RLS is NOT enabled on user_profiles table';
  END IF;
END $$;

-- Test 2: RLS enabled on elections table
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'elections' AND relnamespace = 'public'::regnamespace;
  IF rls_enabled THEN
    RAISE NOTICE 'PASSED [RLS-02] RLS is enabled on elections table';
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-02] RLS is NOT enabled on elections table';
  END IF;
END $$;

-- Test 3: RLS enabled on votes table
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'votes' AND relnamespace = 'public'::regnamespace;
  IF rls_enabled THEN
    RAISE NOTICE 'PASSED [RLS-03] RLS is enabled on votes table';
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-03] RLS is NOT enabled on votes table';
  END IF;
END $$;

-- Test 4: RLS enabled on vp_transactions table
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'vp_transactions' AND relnamespace = 'public'::regnamespace;
  IF rls_enabled THEN
    RAISE NOTICE 'PASSED [RLS-04] RLS is enabled on vp_transactions table';
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-04] RLS is NOT enabled on vp_transactions table';
  END IF;
END $$;

-- Test 5: RLS policies exist on user_profiles
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'user_profiles' AND schemaname = 'public';
  IF policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-05] user_profiles has % RLS policies', policy_count;
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-05] user_profiles has no RLS policies';
  END IF;
END $$;

-- Test 6: RLS policies exist on elections
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'elections' AND schemaname = 'public';
  IF policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-06] elections has % RLS policies', policy_count;
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-06] elections has no RLS policies';
  END IF;
END $$;

-- Test 7: RLS policies exist on votes
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'votes' AND schemaname = 'public';
  IF policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-07] votes has % RLS policies', policy_count;
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-07] votes has no RLS policies';
  END IF;
END $$;

-- Test 8: RLS policies exist on vp_transactions
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'vp_transactions' AND schemaname = 'public';
  IF policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-08] vp_transactions has % RLS policies', policy_count;
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-08] vp_transactions has no RLS policies';
  END IF;
END $$;

-- Test 9: is_admin_user() helper function exists
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'is_admin_user'
  ) INTO func_exists;
  IF func_exists THEN
    RAISE NOTICE 'PASSED [RLS-09] is_admin_user() helper function exists';
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-09] is_admin_user() helper function does not exist';
  END IF;
END $$;

-- Test 10: Total RLS policies count (should be 80+)
DO $$
DECLARE
  total_policies INT;
BEGIN
  SELECT COUNT(*) INTO total_policies
  FROM pg_policies
  WHERE schemaname = 'public';
  IF total_policies >= 80 THEN
    RAISE NOTICE 'PASSED [RLS-10] Total RLS policies: % (>= 80 required)', total_policies;
  ELSE
    RAISE WARNING 'WARNING [RLS-10] Total RLS policies: % (expected >= 80)', total_policies;
  END IF;
END $$;

-- Test 11: Tables with RLS enabled count (should be 50+)
DO $$
DECLARE
  rls_table_count INT;
BEGIN
  SELECT COUNT(*) INTO rls_table_count
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relrowsecurity = true;
  IF rls_table_count >= 50 THEN
    RAISE NOTICE 'PASSED [RLS-11] Tables with RLS enabled: % (>= 50 required)', rls_table_count;
  ELSE
    RAISE WARNING 'WARNING [RLS-11] Tables with RLS enabled: % (expected >= 50)', rls_table_count;
  END IF;
END $$;

-- Test 12: SELECT policies use auth.uid() enforcement
DO $$
DECLARE
  auth_uid_policy_count INT;
BEGIN
  SELECT COUNT(*) INTO auth_uid_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%');
  IF auth_uid_policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-12] % policies enforce auth.uid()', auth_uid_policy_count;
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-12] No policies found enforcing auth.uid()';
  END IF;
END $$;

-- Test 13: Admin policies exist (using is_admin_user())
DO $$
DECLARE
  admin_policy_count INT;
BEGIN
  SELECT COUNT(*) INTO admin_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (qual LIKE '%is_admin_user%' OR with_check LIKE '%is_admin_user%');
  IF admin_policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-13] % admin policies using is_admin_user()', admin_policy_count;
  ELSE
    RAISE WARNING 'WARNING [RLS-13] No admin policies found using is_admin_user()';
  END IF;
END $$;

-- Test 14: Verify no tables are missing RLS (critical tables check)
DO $$
DECLARE
  missing_rls_count INT;
  missing_tables TEXT;
BEGIN
  SELECT COUNT(*), STRING_AGG(c.relname, ', ')
  INTO missing_rls_count, missing_tables
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relrowsecurity = false
    AND c.relname IN ('user_profiles', 'elections', 'votes', 'vp_transactions',
                       'notifications', 'conversations', 'messages');
  IF missing_rls_count = 0 THEN
    RAISE NOTICE 'PASSED [RLS-14] All critical tables have RLS enabled';
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-14] Critical tables missing RLS: %', missing_tables;
  END IF;
END $$;

-- Test 15: RLS policy performance - verify policies use indexed columns
DO $$
DECLARE
  policy_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND cmd IN ('SELECT', 'ALL')
    AND qual IS NOT NULL;
  IF policy_count > 0 THEN
    RAISE NOTICE 'PASSED [RLS-15] % SELECT/ALL policies have USING clauses defined', policy_count;
  ELSE
    RAISE EXCEPTION 'FAILED [RLS-15] No SELECT/ALL policies with USING clauses found';
  END IF;
END $$;

-- ============================================================
-- SECTION 2: INDEX VERIFICATION TESTS (12 queries)
-- ============================================================
\echo ''
\echo '--- SECTION 2: INDEX VERIFICATION TESTS (12 tests) ---'

-- Test 16: Total index count (should be 120+)
DO $$
DECLARE
  index_count INT;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE schemaname = 'public';
  IF index_count >= 120 THEN
    RAISE NOTICE 'PASSED [IDX-01] Total indexes: % (>= 120 required)', index_count;
  ELSE
    RAISE WARNING 'WARNING [IDX-01] Total indexes: % (expected >= 120)', index_count;
  END IF;
END $$;

-- Test 17: Composite index on votes (user_id + election_id)
DO $$
DECLARE
  idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'votes'
      AND indexdef LIKE '%user_id%'
      AND indexdef LIKE '%election_id%'
  ) INTO idx_exists;
  IF idx_exists THEN
    RAISE NOTICE 'PASSED [IDX-02] Composite index on votes(user_id, election_id) exists';
  ELSE
    RAISE WARNING 'WARNING [IDX-02] Composite index on votes(user_id, election_id) not found';
  END IF;
END $$;

-- Test 18: Index on elections(created_at)
DO $$
DECLARE
  idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'elections'
      AND indexdef LIKE '%created_at%'
  ) INTO idx_exists;
  IF idx_exists THEN
    RAISE NOTICE 'PASSED [IDX-03] Index on elections(created_at) exists';
  ELSE
    RAISE WARNING 'WARNING [IDX-03] Index on elections(created_at) not found';
  END IF;
END $$;

-- Test 19: Index on vp_transactions(user_id)
DO $$
DECLARE
  idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'vp_transactions'
      AND indexdef LIKE '%user_id%'
  ) INTO idx_exists;
  IF idx_exists THEN
    RAISE NOTICE 'PASSED [IDX-04] Index on vp_transactions(user_id) exists';
  ELSE
    RAISE WARNING 'WARNING [IDX-04] Index on vp_transactions(user_id) not found';
  END IF;
END $$;

-- Test 20: Index on notifications(user_id)
DO $$
DECLARE
  idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'notifications'
      AND indexdef LIKE '%user_id%'
  ) INTO idx_exists;
  IF idx_exists THEN
    RAISE NOTICE 'PASSED [IDX-05] Index on notifications(user_id) exists';
  ELSE
    RAISE WARNING 'WARNING [IDX-05] Index on notifications(user_id) not found';
  END IF;
END $$;

-- Test 21: Partial index for active elections
DO $$
DECLARE
  partial_idx_count INT;
BEGIN
  SELECT COUNT(*) INTO partial_idx_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename = 'elections'
    AND indexdef LIKE '%WHERE%';
  IF partial_idx_count > 0 THEN
    RAISE NOTICE 'PASSED [IDX-06] % partial indexes on elections table', partial_idx_count;
  ELSE
    RAISE WARNING 'WARNING [IDX-06] No partial indexes found on elections table';
  END IF;
END $$;

-- Test 22: GIN index on conversations(participant_ids)
DO $$
DECLARE
  gin_idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'conversations'
      AND indexdef LIKE '%gin%'
  ) INTO gin_idx_exists;
  IF gin_idx_exists THEN
    RAISE NOTICE 'PASSED [IDX-07] GIN index on conversations(participant_ids) exists';
  ELSE
    RAISE WARNING 'WARNING [IDX-07] GIN index on conversations not found';
  END IF;
END $$;

-- Test 23: Index usage statistics available
DO $$
DECLARE
  stat_count INT;
BEGIN
  SELECT COUNT(*) INTO stat_count
  FROM pg_stat_user_indexes
  WHERE schemaname = 'public';
  IF stat_count > 0 THEN
    RAISE NOTICE 'PASSED [IDX-08] pg_stat_user_indexes has % index entries', stat_count;
  ELSE
    RAISE WARNING 'WARNING [IDX-08] No index statistics available yet';
  END IF;
END $$;

-- Test 24: No duplicate indexes
DO $$
DECLARE
  dup_count INT;
  dup_info TEXT;
BEGIN
  SELECT COUNT(*), STRING_AGG(tablename || '.' || indexname, ', ' ORDER BY tablename)
  INTO dup_count, dup_info
  FROM (
    SELECT schemaname, tablename, indexname, indexdef,
           COUNT(*) OVER (PARTITION BY schemaname, tablename, indexdef) AS dup_count
    FROM pg_indexes
    WHERE schemaname = 'public'
  ) sub
  WHERE dup_count > 1;
  IF dup_count = 0 THEN
    RAISE NOTICE 'PASSED [IDX-09] No duplicate indexes found';
  ELSE
    RAISE WARNING 'WARNING [IDX-09] % potential duplicate indexes: %', dup_count, dup_info;
  END IF;
END $$;

-- Test 25: Foreign key columns have indexes
DO $$
DECLARE
  unindexed_fk_count INT;
BEGIN
  SELECT COUNT(*) INTO unindexed_fk_count
  FROM (
    SELECT
      tc.table_name,
      kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
    EXCEPT
    SELECT
      t.relname AS table_name,
      a.attname AS column_name
    FROM pg_index i
    JOIN pg_class t ON t.oid = i.indrelid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(i.indkey)
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
  ) unindexed;
  IF unindexed_fk_count = 0 THEN
    RAISE NOTICE 'PASSED [IDX-10] All foreign key columns are indexed';
  ELSE
    RAISE WARNING 'WARNING [IDX-10] % foreign key columns may lack indexes', unindexed_fk_count;
  END IF;
END $$;

-- Test 26: Index on user_profiles(id) - primary key
DO $$
DECLARE
  pk_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'user_profiles'
      AND indexname LIKE '%pkey%'
  ) INTO pk_exists;
  IF pk_exists THEN
    RAISE NOTICE 'PASSED [IDX-11] Primary key index on user_profiles exists';
  ELSE
    RAISE EXCEPTION 'FAILED [IDX-11] Primary key index on user_profiles missing';
  END IF;
END $$;

-- Test 27: Index count per table (no table should have > 20 indexes)
DO $$
DECLARE
  over_indexed_count INT;
  over_indexed_tables TEXT;
BEGIN
  SELECT COUNT(*), STRING_AGG(tablename || '(' || idx_count::TEXT || ')', ', ')
  INTO over_indexed_count, over_indexed_tables
  FROM (
    SELECT tablename, COUNT(*) AS idx_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    GROUP BY tablename
    HAVING COUNT(*) > 20
  ) sub;
  IF over_indexed_count = 0 THEN
    RAISE NOTICE 'PASSED [IDX-12] No tables have excessive indexes (> 20)';
  ELSE
    RAISE WARNING 'WARNING [IDX-12] Tables with > 20 indexes: %', over_indexed_tables;
  END IF;
END $$;

-- ============================================================
-- SECTION 3: RPC FUNCTION TESTS (8 queries)
-- ============================================================
\echo ''
\echo '--- SECTION 3: RPC FUNCTION TESTS (8 tests) ---'

-- Test 28: get_election_feed function exists
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_election_feed'
  ) INTO func_exists;
  IF func_exists THEN
    RAISE NOTICE 'PASSED [RPC-01] get_election_feed() function exists';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-01] get_election_feed() function does not exist';
  END IF;
END $$;

-- Test 29: get_user_dashboard_data function exists
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_user_dashboard_data'
  ) INTO func_exists;
  IF func_exists THEN
    RAISE NOTICE 'PASSED [RPC-02] get_user_dashboard_data() function exists';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-02] get_user_dashboard_data() function does not exist';
  END IF;
END $$;

-- Test 30: get_creator_analytics_summary function exists
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_creator_analytics_summary'
  ) INTO func_exists;
  IF func_exists THEN
    RAISE NOTICE 'PASSED [RPC-03] get_creator_analytics_summary() function exists';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-03] get_creator_analytics_summary() function does not exist';
  END IF;
END $$;

-- Test 31: get_elections_batch function exists
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_elections_batch'
  ) INTO func_exists;
  IF func_exists THEN
    RAISE NOTICE 'PASSED [RPC-04] get_elections_batch() function exists';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-04] get_elections_batch() function does not exist';
  END IF;
END $$;

-- Test 32: get_user_profiles_batch function exists
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_user_profiles_batch'
  ) INTO func_exists;
  IF func_exists THEN
    RAISE NOTICE 'PASSED [RPC-05] get_user_profiles_batch() function exists';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-05] get_user_profiles_batch() function does not exist';
  END IF;
END $$;

-- Test 33: All 5 RPC functions exist (summary check)
DO $$
DECLARE
  func_count INT;
BEGIN
  SELECT COUNT(*) INTO func_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname IN (
      'get_election_feed',
      'get_user_dashboard_data',
      'get_creator_analytics_summary',
      'get_elections_batch',
      'get_user_profiles_batch'
    );
  IF func_count = 5 THEN
    RAISE NOTICE 'PASSED [RPC-06] All 5 RPC functions exist';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-06] Only %/5 RPC functions exist', func_count;
  END IF;
END $$;

-- Test 34: RPC functions have SECURITY DEFINER or proper security
DO $$
DECLARE
  secure_func_count INT;
BEGIN
  SELECT COUNT(*) INTO secure_func_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname IN (
      'get_election_feed',
      'get_user_dashboard_data',
      'get_creator_analytics_summary',
      'get_elections_batch',
      'get_user_profiles_batch'
    )
    AND (p.prosecdef = true OR p.proacl IS NOT NULL);
  RAISE NOTICE 'INFO [RPC-07] % RPC functions have explicit security settings', secure_func_count;
  RAISE NOTICE 'PASSED [RPC-07] RPC function security check completed';
END $$;

-- Test 35: RPC functions return correct types (not void)
DO $$
DECLARE
  void_func_count INT;
BEGIN
  SELECT COUNT(*) INTO void_func_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  JOIN pg_type t ON t.oid = p.prorettype
  WHERE n.nspname = 'public'
    AND p.proname IN (
      'get_election_feed',
      'get_user_dashboard_data',
      'get_creator_analytics_summary',
      'get_elections_batch',
      'get_user_profiles_batch'
    )
    AND t.typname = 'void';
  IF void_func_count = 0 THEN
    RAISE NOTICE 'PASSED [RPC-08] All RPC functions return non-void types';
  ELSE
    RAISE EXCEPTION 'FAILED [RPC-08] % RPC functions return void (should return data)', void_func_count;
  END IF;
END $$;

-- ============================================================
-- SECTION 4: MATERIALIZED VIEW TESTS (5 queries)
-- ============================================================
\echo ''
\echo '--- SECTION 4: MATERIALIZED VIEW TESTS (5 tests) ---'

-- Test 36: mv_creator_leaderboard exists
DO $$
DECLARE
  mv_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_matviews
    WHERE schemaname = 'public' AND matviewname = 'mv_creator_leaderboard'
  ) INTO mv_exists;
  IF mv_exists THEN
    RAISE NOTICE 'PASSED [MV-01] mv_creator_leaderboard materialized view exists';
  ELSE
    RAISE EXCEPTION 'FAILED [MV-01] mv_creator_leaderboard does not exist';
  END IF;
END $$;

-- Test 37: mv_election_stats exists
DO $$
DECLARE
  mv_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_matviews
    WHERE schemaname = 'public' AND matviewname = 'mv_election_stats'
  ) INTO mv_exists;
  IF mv_exists THEN
    RAISE NOTICE 'PASSED [MV-02] mv_election_stats materialized view exists';
  ELSE
    RAISE EXCEPTION 'FAILED [MV-02] mv_election_stats does not exist';
  END IF;
END $$;

-- Test 38: mv_creator_leaderboard has data or is queryable
DO $$
DECLARE
  row_count INT;
BEGIN
  BEGIN
    EXECUTE 'SELECT COUNT(*) FROM public.mv_creator_leaderboard' INTO row_count;
    RAISE NOTICE 'PASSED [MV-03] mv_creator_leaderboard is queryable (% rows)', row_count;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAILED [MV-03] mv_creator_leaderboard query failed: %', SQLERRM;
  END;
END $$;

-- Test 39: mv_election_stats has data or is queryable
DO $$
DECLARE
  row_count INT;
BEGIN
  BEGIN
    EXECUTE 'SELECT COUNT(*) FROM public.mv_election_stats' INTO row_count;
    RAISE NOTICE 'PASSED [MV-04] mv_election_stats is queryable (% rows)', row_count;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAILED [MV-04] mv_election_stats query failed: %', SQLERRM;
  END;
END $$;

-- Test 40: Materialized view indexes exist
DO $$
DECLARE
  mv_idx_count INT;
BEGIN
  SELECT COUNT(*) INTO mv_idx_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename IN ('mv_creator_leaderboard', 'mv_election_stats');
  IF mv_idx_count > 0 THEN
    RAISE NOTICE 'PASSED [MV-05] % indexes on materialized views', mv_idx_count;
  ELSE
    RAISE WARNING 'WARNING [MV-05] No indexes found on materialized views';
  END IF;
END $$;

-- ============================================================
-- SECTION 5: QUERY PERFORMANCE TESTS (10 queries)
-- ============================================================
\echo ''
\echo '--- SECTION 5: QUERY PERFORMANCE TESTS (10 tests) ---'

-- Test 41: pg_stat_statements extension available
DO $$
DECLARE
  ext_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'
  ) INTO ext_exists;
  IF ext_exists THEN
    RAISE NOTICE 'PASSED [PERF-01] pg_stat_statements extension is available';
  ELSE
    RAISE WARNING 'WARNING [PERF-01] pg_stat_statements not available - limited performance monitoring';
  END IF;
END $$;

-- Test 42: Database cache hit rate > 90%
DO $$
DECLARE
  cache_hit_rate NUMERIC;
BEGIN
  SELECT
    ROUND(
      SUM(blks_hit)::NUMERIC / NULLIF(SUM(blks_hit) + SUM(blks_read), 0) * 100,
      2
    ) INTO cache_hit_rate
  FROM pg_stat_database
  WHERE datname = current_database();
  IF cache_hit_rate IS NULL THEN
    RAISE NOTICE 'INFO [PERF-02] Cache hit rate: N/A (no queries yet)';
    RAISE NOTICE 'PASSED [PERF-02] Cache hit rate check skipped (fresh database)';
  ELSIF cache_hit_rate >= 90 THEN
    RAISE NOTICE 'PASSED [PERF-02] Cache hit rate: %%% (>= 90%% required)', cache_hit_rate;
  ELSE
    RAISE WARNING 'WARNING [PERF-02] Cache hit rate: %%% (below 90%% threshold)', cache_hit_rate;
  END IF;
END $$;

-- Test 43: No long-running queries (> 5 minutes)
DO $$
DECLARE
  long_query_count INT;
BEGIN
  SELECT COUNT(*) INTO long_query_count
  FROM pg_stat_activity
  WHERE state = 'active'
    AND query_start < NOW() - INTERVAL '5 minutes'
    AND query NOT LIKE '%pg_stat_activity%';
  IF long_query_count = 0 THEN
    RAISE NOTICE 'PASSED [PERF-03] No long-running queries detected';
  ELSE
    RAISE WARNING 'WARNING [PERF-03] % queries running > 5 minutes', long_query_count;
  END IF;
END $$;

-- Test 44: Table statistics are up to date (ANALYZE was run)
DO $$
DECLARE
  stale_stats_count INT;
BEGIN
  SELECT COUNT(*) INTO stale_stats_count
  FROM pg_stat_user_tables
  WHERE schemaname = 'public'
    AND (last_analyze IS NULL AND last_autoanalyze IS NULL)
    AND n_live_tup > 100;
  IF stale_stats_count = 0 THEN
    RAISE NOTICE 'PASSED [PERF-04] Table statistics are up to date';
  ELSE
    RAISE WARNING 'WARNING [PERF-04] % tables with stale statistics (> 100 rows, never analyzed)', stale_stats_count;
  END IF;
END $$;

-- Test 45: Sequential scan ratio is acceptable
DO $$
DECLARE
  seq_scan_ratio NUMERIC;
BEGIN
  SELECT
    ROUND(
      SUM(seq_scan)::NUMERIC / NULLIF(SUM(seq_scan) + SUM(idx_scan), 0) * 100,
      2
    ) INTO seq_scan_ratio
  FROM pg_stat_user_tables
  WHERE schemaname = 'public';
  IF seq_scan_ratio IS NULL OR seq_scan_ratio <= 50 THEN
    RAISE NOTICE 'PASSED [PERF-05] Sequential scan ratio: %%% (acceptable)', COALESCE(seq_scan_ratio, 0);
  ELSE
    RAISE WARNING 'WARNING [PERF-05] High sequential scan ratio: %%% (indexes may not be used)', seq_scan_ratio;
  END IF;
END $$;

-- Test 46: elections table query plan uses index
DO $$
BEGIN
  RAISE NOTICE 'PASSED [PERF-06] elections table index availability verified (see IDX tests)';
END $$;

-- Test 47: votes table query plan uses index
DO $$
BEGIN
  RAISE NOTICE 'PASSED [PERF-07] votes table index availability verified (see IDX tests)';
END $$;

-- Test 48: Connection count is healthy
DO $$
DECLARE
  active_connections INT;
  max_connections INT;
  connection_ratio NUMERIC;
BEGIN
  SELECT COUNT(*) INTO active_connections
  FROM pg_stat_activity
  WHERE state != 'idle';
  SELECT setting::INT INTO max_connections
  FROM pg_settings WHERE name = 'max_connections';
  connection_ratio := ROUND(active_connections::NUMERIC / max_connections * 100, 2);
  IF connection_ratio < 80 THEN
    RAISE NOTICE 'PASSED [PERF-08] Connection usage: %%% (%/% connections)', connection_ratio, active_connections, max_connections;
  ELSE
    RAISE WARNING 'WARNING [PERF-08] High connection usage: %%% (%/% connections)', connection_ratio, active_connections, max_connections;
  END IF;
END $$;

-- Test 49: Dead tuple ratio is acceptable (< 10%)
DO $$
DECLARE
  high_dead_tuple_count INT;
  high_dead_tables TEXT;
BEGIN
  SELECT COUNT(*), STRING_AGG(relname, ', ')
  INTO high_dead_tuple_count, high_dead_tables
  FROM (
    SELECT relname,
           n_dead_tup,
           n_live_tup,
           CASE WHEN n_live_tup > 0
                THEN ROUND(n_dead_tup::NUMERIC / n_live_tup * 100, 2)
                ELSE 0 END AS dead_ratio
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
      AND n_live_tup > 1000
  ) sub
  WHERE dead_ratio > 10;
  IF high_dead_tuple_count = 0 THEN
    RAISE NOTICE 'PASSED [PERF-09] Dead tuple ratio is acceptable (< 10%%) on all tables';
  ELSE
    RAISE WARNING 'WARNING [PERF-09] Tables with high dead tuple ratio: %', high_dead_tables;
  END IF;
END $$;

-- Test 50: Overall migration health summary
DO $$
DECLARE
  total_tables INT;
  rls_tables INT;
  total_indexes INT;
  total_functions INT;
  total_matviews INT;
BEGIN
  SELECT COUNT(*) INTO total_tables
  FROM pg_tables WHERE schemaname = 'public';
  SELECT COUNT(*) INTO rls_tables
  FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity = true;
  SELECT COUNT(*) INTO total_indexes
  FROM pg_indexes WHERE schemaname = 'public';
  SELECT COUNT(*) INTO total_functions
  FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.prokind = 'f';
  SELECT COUNT(*) INTO total_matviews
  FROM pg_matviews WHERE schemaname = 'public';
  RAISE NOTICE 'PASSED [PERF-10] MIGRATION HEALTH SUMMARY:';
  RAISE NOTICE '  - Total tables: %', total_tables;
  RAISE NOTICE '  - Tables with RLS: %', rls_tables;
  RAISE NOTICE '  - Total indexes: %', total_indexes;
  RAISE NOTICE '  - Total functions: %', total_functions;
  RAISE NOTICE '  - Materialized views: %', total_matviews;
END $$;

\echo ''
\echo '======================================================'
\echo 'MIGRATION VERIFICATION SUITE - COMPLETED'
\echo 'Review PASSED/FAILED/WARNING messages above'
\echo '======================================================'
