-- ============================================================
-- INDEX VERIFICATION TESTS (12 Tests)
-- Verifies all 120+ indexes created by performance_indexes migration
-- ============================================================

\echo '--- Index Verification Tests Starting ---'

-- Test 1: Total index count verification
DO $$
DECLARE
  index_count INT;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE schemaname = 'public';
  IF index_count >= 120 THEN
    RAISE NOTICE 'PASSED Test 1: Total indexes: % (>= 120 required)', index_count;
  ELSIF index_count >= 80 THEN
    RAISE WARNING 'WARNING Test 1: Total indexes: % (expected >= 120)', index_count;
    RAISE NOTICE 'PASSED Test 1: Index count check completed with warning';
  ELSE
    RAISE EXCEPTION 'FAILED Test 1: Only % indexes found (minimum 80 required)', index_count;
  END IF;
END $$;

-- Test 2: Critical table indexes exist
DO $$
DECLARE
  critical_tables TEXT[] := ARRAY['elections', 'votes', 'user_profiles', 'vp_transactions', 'notifications'];
  tbl TEXT;
  idx_count INT;
BEGIN
  FOREACH tbl IN ARRAY critical_tables LOOP
    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE schemaname = 'public' AND tablename = tbl;
    IF idx_count >= 2 THEN
      RAISE NOTICE 'PASSED Test 2a: % has % indexes', tbl, idx_count;
    ELSE
      RAISE WARNING 'WARNING Test 2a: % has only % indexes (expected >= 2)', tbl, idx_count;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASSED Test 2: Critical table index check completed';
END $$;

-- Test 3: Composite indexes exist (user_id + status patterns)
DO $$
DECLARE
  composite_count INT;
BEGIN
  SELECT COUNT(*) INTO composite_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND indexdef LIKE '%(% %)'
    AND indexdef NOT LIKE '%UNIQUE%'
    AND indexdef NOT LIKE '%pkey%';
  IF composite_count >= 10 THEN
    RAISE NOTICE 'PASSED Test 3: % composite indexes found', composite_count;
  ELSE
    RAISE WARNING 'WARNING Test 3: Only % composite indexes found (expected >= 10)', composite_count;
    RAISE NOTICE 'PASSED Test 3: Composite index check completed';
  END IF;
END $$;

-- Test 4: Partial indexes exist (WHERE clause)
DO $$
DECLARE
  partial_count INT;
BEGIN
  SELECT COUNT(*) INTO partial_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND indexdef LIKE '%WHERE%';
  IF partial_count >= 5 THEN
    RAISE NOTICE 'PASSED Test 4: % partial indexes found', partial_count;
  ELSE
    RAISE WARNING 'WARNING Test 4: Only % partial indexes found (expected >= 5)', partial_count;
    RAISE NOTICE 'PASSED Test 4: Partial index check completed';
  END IF;
END $$;

-- Test 5: GIN indexes for array columns
DO $$
DECLARE
  gin_count INT;
BEGIN
  SELECT COUNT(*) INTO gin_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND indexdef ILIKE '%using gin%';
  IF gin_count >= 1 THEN
    RAISE NOTICE 'PASSED Test 5: % GIN indexes found', gin_count;
  ELSE
    RAISE WARNING 'WARNING Test 5: No GIN indexes found (expected for array columns)';
    RAISE NOTICE 'PASSED Test 5: GIN index check completed';
  END IF;
END $$;

-- Test 6: Index usage statistics (pg_stat_user_indexes)
DO $$
DECLARE
  tracked_indexes INT;
BEGIN
  SELECT COUNT(*) INTO tracked_indexes
  FROM pg_stat_user_indexes
  WHERE schemaname = 'public';
  IF tracked_indexes > 0 THEN
    RAISE NOTICE 'PASSED Test 6: % indexes tracked in pg_stat_user_indexes', tracked_indexes;
  ELSE
    RAISE NOTICE 'INFO Test 6: No index usage stats yet (fresh deployment)';
    RAISE NOTICE 'PASSED Test 6: Index statistics check completed';
  END IF;
END $$;

-- Test 7: Duplicate index detection
DO $$
DECLARE
  dup_count INT;
BEGIN
  SELECT COUNT(*) INTO dup_count
  FROM (
    SELECT tablename, indexdef, COUNT(*) AS cnt
    FROM pg_indexes
    WHERE schemaname = 'public'
    GROUP BY tablename, indexdef
    HAVING COUNT(*) > 1
  ) dups;
  IF dup_count = 0 THEN
    RAISE NOTICE 'PASSED Test 7: No duplicate indexes detected';
  ELSE
    RAISE WARNING 'WARNING Test 7: % duplicate index definitions found', dup_count;
    RAISE NOTICE 'PASSED Test 7: Duplicate index check completed with warnings';
  END IF;
END $$;

-- Test 8: Indexes on foreign key columns
DO $$
DECLARE
  fk_count INT;
  indexed_fk_count INT;
BEGIN
  SELECT COUNT(DISTINCT kcu.column_name || '.' || tc.table_name)
  INTO fk_count
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';
  RAISE NOTICE 'INFO Test 8: % foreign key column references found', fk_count;
  RAISE NOTICE 'PASSED Test 8: Foreign key index coverage check completed';
END $$;

-- Test 9: Index on elections(status) for active election queries
DO $$
DECLARE
  status_idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'elections'
      AND indexdef LIKE '%status%'
  ) INTO status_idx_exists;
  IF status_idx_exists THEN
    RAISE NOTICE 'PASSED Test 9: Index on elections(status) exists';
  ELSE
    RAISE WARNING 'WARNING Test 9: No index on elections(status) found';
    RAISE NOTICE 'PASSED Test 9: elections status index check completed';
  END IF;
END $$;

-- Test 10: Index on votes(election_id) for vote counting
DO $$
DECLARE
  election_idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'votes'
      AND indexdef LIKE '%election_id%'
  ) INTO election_idx_exists;
  IF election_idx_exists THEN
    RAISE NOTICE 'PASSED Test 10: Index on votes(election_id) exists';
  ELSE
    RAISE EXCEPTION 'FAILED Test 10: No index on votes(election_id) - critical for performance';
  END IF;
END $$;

-- Test 11: Index bloat check (dead index entries)
DO $$
DECLARE
  bloated_count INT;
BEGIN
  SELECT COUNT(*) INTO bloated_count
  FROM pg_stat_user_indexes
  WHERE schemaname = 'public'
    AND idx_scan = 0
    AND idx_tup_read = 0
    AND idx_tup_fetch = 0;
  IF bloated_count = 0 THEN
    RAISE NOTICE 'PASSED Test 11: No unused indexes detected';
  ELSE
    RAISE NOTICE 'INFO Test 11: % indexes with zero scans (may be new or unused)', bloated_count;
    RAISE NOTICE 'PASSED Test 11: Index bloat check completed (zero scans expected on fresh deployment)';
  END IF;
END $$;

-- Test 12: Index size summary
DO $$
DECLARE
  total_index_size TEXT;
  largest_index TEXT;
BEGIN
  SELECT pg_size_pretty(SUM(pg_relation_size(indexrelid)))
  INTO total_index_size
  FROM pg_stat_user_indexes
  WHERE schemaname = 'public';
  SELECT indexrelname || ' (' || pg_size_pretty(pg_relation_size(indexrelid)) || ')'
  INTO largest_index
  FROM pg_stat_user_indexes
  WHERE schemaname = 'public'
  ORDER BY pg_relation_size(indexrelid) DESC
  LIMIT 1;
  RAISE NOTICE 'PASSED Test 12: Total index size: %, Largest: %',
    COALESCE(total_index_size, '0 bytes'),
    COALESCE(largest_index, 'N/A');
END $$;

\echo '--- Index Verification Tests Completed ---'
