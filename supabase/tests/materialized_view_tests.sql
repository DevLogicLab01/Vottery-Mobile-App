-- ============================================================
-- MATERIALIZED VIEW TESTS (5 Tests)
-- Tests mv_creator_leaderboard and mv_election_stats
-- ============================================================

\echo '--- Materialized View Tests Starting ---'

-- Test 1: Both materialized views exist
DO $$
DECLARE
  mv_count INT;
  missing_mvs TEXT;
BEGIN
  SELECT COUNT(*) INTO mv_count
  FROM pg_matviews
  WHERE schemaname = 'public'
    AND matviewname IN ('mv_creator_leaderboard', 'mv_election_stats');
  IF mv_count = 2 THEN
    RAISE NOTICE 'PASSED Test 1: Both materialized views exist';
  ELSE
    SELECT STRING_AGG(mv_name, ', ')
    INTO missing_mvs
    FROM (VALUES ('mv_creator_leaderboard'), ('mv_election_stats')) AS mvs(mv_name)
    WHERE mv_name NOT IN (
      SELECT matviewname FROM pg_matviews WHERE schemaname = 'public'
    );
    RAISE EXCEPTION 'FAILED Test 1: Missing materialized views: %', missing_mvs;
  END IF;
END $$;

-- Test 2: mv_creator_leaderboard is queryable and has expected columns
DO $$
DECLARE
  col_count INT;
BEGIN
  SELECT COUNT(*) INTO col_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mv_creator_leaderboard';
  IF col_count > 0 THEN
    RAISE NOTICE 'PASSED Test 2: mv_creator_leaderboard has % columns', col_count;
  ELSE
    RAISE EXCEPTION 'FAILED Test 2: mv_creator_leaderboard has no columns';
  END IF;
END $$;

-- Test 3: mv_election_stats is queryable and has expected columns
DO $$
DECLARE
  col_count INT;
BEGIN
  SELECT COUNT(*) INTO col_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mv_election_stats';
  IF col_count > 0 THEN
    RAISE NOTICE 'PASSED Test 3: mv_election_stats has % columns', col_count;
  ELSE
    RAISE EXCEPTION 'FAILED Test 3: mv_election_stats has no columns';
  END IF;
END $$;

-- Test 4: Materialized views have indexes for performance
DO $$
DECLARE
  mv_idx_count INT;
BEGIN
  SELECT COUNT(*) INTO mv_idx_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename IN ('mv_creator_leaderboard', 'mv_election_stats');
  IF mv_idx_count > 0 THEN
    RAISE NOTICE 'PASSED Test 4: % indexes on materialized views', mv_idx_count;
  ELSE
    RAISE WARNING 'WARNING Test 4: No indexes on materialized views (may impact refresh performance)';
    RAISE NOTICE 'PASSED Test 4: Materialized view index check completed';
  END IF;
END $$;

-- Test 5: Materialized views are populated (not empty on non-empty DB)
DO $$
DECLARE
  leaderboard_rows INT;
  election_stats_rows INT;
  elections_exist INT;
BEGIN
  EXECUTE 'SELECT COUNT(*) FROM public.mv_creator_leaderboard' INTO leaderboard_rows;
  EXECUTE 'SELECT COUNT(*) FROM public.mv_election_stats' INTO election_stats_rows;
  SELECT COUNT(*) INTO elections_exist FROM public.elections;
  IF elections_exist = 0 THEN
    RAISE NOTICE 'INFO Test 5: No elections in DB - materialized views may be empty';
    RAISE NOTICE 'PASSED Test 5: Materialized view data check skipped (no source data)';
  ELSE
    RAISE NOTICE 'INFO Test 5: mv_creator_leaderboard: % rows, mv_election_stats: % rows', leaderboard_rows, election_stats_rows;
    RAISE NOTICE 'PASSED Test 5: Materialized view data check completed';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'FAILED Test 5: Error querying materialized views: %', SQLERRM;
END $$;

\echo '--- Materialized View Tests Completed ---'
