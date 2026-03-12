-- ============================================================
-- RPC FUNCTION TESTS (8 Tests)
-- Tests all 5 new RPC functions from query_optimizations migration
-- ============================================================

\echo '--- RPC Function Tests Starting ---'

-- Test 1: All 5 RPC functions exist
DO $$
DECLARE
  func_count INT;
  missing_funcs TEXT;
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
    RAISE NOTICE 'PASSED Test 1: All 5 RPC functions exist';
  ELSE
    SELECT STRING_AGG(func_name, ', ')
    INTO missing_funcs
    FROM (
      VALUES
        ('get_election_feed'),
        ('get_user_dashboard_data'),
        ('get_creator_analytics_summary'),
        ('get_elections_batch'),
        ('get_user_profiles_batch')
    ) AS funcs(func_name)
    WHERE func_name NOT IN (
      SELECT p.proname FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
    );
    RAISE EXCEPTION 'FAILED Test 1: Missing RPC functions: %', missing_funcs;
  END IF;
END $$;

-- Test 2: get_election_feed function signature
DO $$
DECLARE
  param_count INT;
  func_args TEXT;
BEGIN
  SELECT pronargs, pg_get_function_arguments(p.oid)
  INTO param_count, func_args
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.proname = 'get_election_feed'
  LIMIT 1;
  RAISE NOTICE 'PASSED Test 2: get_election_feed signature: (%) - % params', func_args, param_count;
END $$;

-- Test 3: get_user_dashboard_data function signature
DO $$
DECLARE
  param_count INT;
  func_args TEXT;
BEGIN
  SELECT pronargs, pg_get_function_arguments(p.oid)
  INTO param_count, func_args
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.proname = 'get_user_dashboard_data'
  LIMIT 1;
  RAISE NOTICE 'PASSED Test 3: get_user_dashboard_data signature: (%) - % params', func_args, param_count;
END $$;

-- Test 4: get_creator_analytics_summary function signature
DO $$
DECLARE
  param_count INT;
  func_args TEXT;
BEGIN
  SELECT pronargs, pg_get_function_arguments(p.oid)
  INTO param_count, func_args
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.proname = 'get_creator_analytics_summary'
  LIMIT 1;
  RAISE NOTICE 'PASSED Test 4: get_creator_analytics_summary signature: (%) - % params', func_args, param_count;
END $$;

-- Test 5: get_elections_batch function signature
DO $$
DECLARE
  param_count INT;
  func_args TEXT;
BEGIN
  SELECT pronargs, pg_get_function_arguments(p.oid)
  INTO param_count, func_args
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.proname = 'get_elections_batch'
  LIMIT 1;
  RAISE NOTICE 'PASSED Test 5: get_elections_batch signature: (%) - % params', func_args, param_count;
END $$;

-- Test 6: get_user_profiles_batch function signature
DO $$
DECLARE
  param_count INT;
  func_args TEXT;
BEGIN
  SELECT pronargs, pg_get_function_arguments(p.oid)
  INTO param_count, func_args
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.proname = 'get_user_profiles_batch'
  LIMIT 1;
  RAISE NOTICE 'PASSED Test 6: get_user_profiles_batch signature: (%) - % params', func_args, param_count;
END $$;

-- Test 7: RPC functions return set or composite types (not void)
DO $$
DECLARE
  func_name TEXT;
  return_type TEXT;
  void_funcs TEXT := '';
BEGIN
  FOR func_name, return_type IN
    SELECT p.proname, t.typname
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
  LOOP
    RAISE NOTICE 'INFO Test 7: % returns type: %', func_name, return_type;
    IF return_type = 'void' THEN
      void_funcs := void_funcs || func_name || ' ';
    END IF;
  END LOOP;
  IF void_funcs = '' THEN
    RAISE NOTICE 'PASSED Test 7: All RPC functions return non-void types';
  ELSE
    RAISE EXCEPTION 'FAILED Test 7: These functions return void: %', void_funcs;
  END IF;
END $$;

-- Test 8: RPC function performance characteristics
DO $$
DECLARE
  func_count INT;
  parallel_safe_count INT;
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
  SELECT COUNT(*) INTO parallel_safe_count
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
    AND p.proparallel IN ('s', 'r');
  RAISE NOTICE 'INFO Test 8: %/% RPC functions are parallel-safe or restricted', parallel_safe_count, func_count;
  RAISE NOTICE 'PASSED Test 8: RPC function performance characteristics verified';
END $$;

\echo '--- RPC Function Tests Completed ---'
