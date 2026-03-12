# Staging Deployment Guide
## Vottery Database Optimization - 4 Migration Files

**Migrations to Deploy:**
1. `20260228120000_security_rls_fixes.sql` - RLS policies for 50+ tables
2. `20260228130000_performance_indexes.sql` - 120+ strategic indexes
3. `20260228140000_query_optimizations.sql` - Materialized views + RPC functions
4. `20260228150000_cleanup.sql` - Post-optimization cleanup (if applicable)

---

## PRE-DEPLOYMENT CHECKLIST

### Environment Setup
- [ ] Supabase CLI installed: `supabase --version` (requires >= 1.27.0)
- [ ] Staging project linked: `supabase link --project-ref STAGING_REF`
- [ ] psql client available: `psql --version`
- [ ] Git working directory clean: `git status`

### Backup Production Database
```bash
# Create timestamped backup
supabase db dump --db-url $PRODUCTION_DB_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup file size (should be > 0)
ls -lh backup_*.sql
```

### Create Staging Branch
```bash
git checkout -b staging/db-optimization-$(date +%Y%m%d)
git push origin staging/db-optimization-$(date +%Y%m%d)
```

### Verify Staging Environment
```bash
# Confirm staging project is linked
supabase projects list

# Check current migration status
supabase migration list

# Verify staging DB URL is accessible
psql $STAGING_DB_URL -c "SELECT version();"
```

---

## MIGRATION EXECUTION STEPS

### Step 1: Review Migration Files
```bash
# Review all 4 migration files before applying
cat supabase/migrations/20260228120000_security_rls_fixes.sql | head -100
cat supabase/migrations/20260228130000_performance_indexes.sql | head -100
cat supabase/migrations/20260228140000_query_optimizations.sql | head -100

# Count total changes
grep -c 'CREATE\|ALTER\|DROP\|INSERT' supabase/migrations/20260228120000_security_rls_fixes.sql
grep -c 'CREATE INDEX' supabase/migrations/20260228130000_performance_indexes.sql
grep -c 'CREATE\|FUNCTION\|MATERIALIZED' supabase/migrations/20260228140000_query_optimizations.sql
```

### Step 2: Dry Run (Preview Changes)
```bash
# Preview schema diff without applying
supabase db diff --db-url $STAGING_DB_URL

# Check for potential conflicts
supabase db diff --db-url $STAGING_DB_URL --schema public
```

### Step 3: Push Migrations to Staging
```bash
# Apply all pending migrations to staging
supabase db push --db-url $STAGING_DB_URL

# Monitor output for errors
# Expected: "Applying migration 20260228120000_security_rls_fixes.sql"
# Expected: "Applying migration 20260228130000_performance_indexes.sql"
# Expected: "Applying migration 20260228140000_query_optimizations.sql"
```

### Step 4: Verify Migration Success
```bash
# Check all 4 migrations are applied
supabase migration list --db-url $STAGING_DB_URL

# Verify via psql
psql $STAGING_DB_URL -c "SELECT version, name, executed_at FROM supabase_migrations.schema_migrations ORDER BY executed_at DESC LIMIT 10;"
```

### Step 5: Run Test Suite
```bash
# Make test runner executable
chmod +x supabase/tests/run_verification_tests.sh

# Run full verification suite
./supabase/tests/run_verification_tests.sh $STAGING_DB_URL

# Or run individual test files
psql $STAGING_DB_URL -f supabase/tests/rls_policy_tests.sql
psql $STAGING_DB_URL -f supabase/tests/index_verification_tests.sql
psql $STAGING_DB_URL -f supabase/tests/rpc_function_tests.sql
psql $STAGING_DB_URL -f supabase/tests/materialized_view_tests.sql
psql $STAGING_DB_URL -f supabase/tests/performance_benchmark_tests.sql
```

### Step 6: Review Test Results
```bash
# Check results directory
ls -la supabase/tests/results/

# Review any failures
grep -l 'FAILED\|ERROR' supabase/tests/results/*.log

# View specific failure details
cat supabase/tests/results/rls_tests_*.log | grep -A 5 'FAILED'
```

---

## POST-DEPLOYMENT VERIFICATION

### Application Testing

#### 1. Authentication Flow
```bash
# Test user login via Supabase Auth
curl -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "testpassword"}'
```

#### 2. RLS Policy Verification
```bash
# Test that authenticated users can access own data
psql $STAGING_DB_URL -c "
  SET LOCAL ROLE authenticated;
  SELECT COUNT(*) FROM user_profiles;
"

# Test that anon users are blocked from sensitive tables
psql $STAGING_DB_URL -c "
  SET LOCAL ROLE anon;
  SELECT COUNT(*) FROM vp_transactions;
" 2>&1 | grep -i 'denied\|permission\|policy'
```

#### 3. RPC Function Testing
```bash
# Test get_election_feed RPC
psql $STAGING_DB_URL -c "SELECT * FROM get_election_feed() LIMIT 5;"

# Test get_elections_batch RPC
psql $STAGING_DB_URL -c "SELECT * FROM get_elections_batch(ARRAY[]::UUID[]) LIMIT 5;"
```

#### 4. Materialized View Refresh
```bash
# Refresh materialized views
psql $STAGING_DB_URL -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_creator_leaderboard;"
psql $STAGING_DB_URL -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_election_stats;"

# Verify data
psql $STAGING_DB_URL -c "SELECT COUNT(*) FROM mv_creator_leaderboard;"
psql $STAGING_DB_URL -c "SELECT COUNT(*) FROM mv_election_stats;"
```

### Performance Monitoring
```bash
# Check query response times (target: < 100ms)
psql $STAGING_DB_URL -c "
  EXPLAIN ANALYZE SELECT * FROM elections WHERE status = 'active' LIMIT 20;
"

# Check cache hit rate (target: > 95%)
psql $STAGING_DB_URL -c "
  SELECT
    ROUND(SUM(blks_hit)::NUMERIC / NULLIF(SUM(blks_hit) + SUM(blks_read), 0) * 100, 2) AS cache_hit_rate
  FROM pg_stat_database
  WHERE datname = current_database();
"

# Check index usage
psql $STAGING_DB_URL -c "
  SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
  FROM pg_stat_user_indexes
  WHERE schemaname = 'public'
  ORDER BY idx_scan DESC
  LIMIT 20;
"
```

### Load Testing (Simulate 1000 Concurrent Users)
```bash
# Install pgbench if not available
# apt-get install postgresql-client

# Initialize pgbench
pgbench -i -s 10 $STAGING_DB_URL

# Run load test: 1000 clients, 60 seconds
pgbench -c 1000 -j 10 -T 60 $STAGING_DB_URL

# Monitor during load test
psql $STAGING_DB_URL -c "
  SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;
"
```

---

## ROLLBACK PROCEDURES

### Immediate Rollback (If Critical Issues)
```bash
# Option 1: Reset staging to pre-migration state
supabase db reset --db-url $STAGING_DB_URL

# Option 2: Restore from backup
psql $STAGING_DB_URL < backup_YYYYMMDD_HHMMSS.sql

# Option 3: Revert specific migration
psql $STAGING_DB_URL -c "
  DELETE FROM supabase_migrations.schema_migrations
  WHERE version IN ('20260228120000', '20260228130000', '20260228140000');
"
```

### Rollback Triggers
- Error rate > 1% after deployment
- Query latency > 500ms (p95)
- RLS policy failures blocking legitimate users
- Materialized view refresh failures
- Any data integrity issues

### Post-Rollback Verification
```bash
# Verify rollback success
supabase migration list --db-url $STAGING_DB_URL

# Test basic functionality
psql $STAGING_DB_URL -c "SELECT COUNT(*) FROM elections;"
psql $STAGING_DB_URL -c "SELECT COUNT(*) FROM votes;"
```

---

## STAGING SIGN-OFF CRITERIA

Before promoting to production, confirm:

- [ ] All 50/50 migration verification tests passed
- [ ] Flutter app login works in staging
- [ ] Vote casting works with new RLS policies
- [ ] VP transactions accessible to correct users
- [ ] Creator analytics RPC functions return data
- [ ] Admin dashboard accessible to admin users
- [ ] Query response times < 100ms average
- [ ] Cache hit rate > 95%
- [ ] Error rate < 0.1%
- [ ] Load test: 1000 concurrent users handled
- [ ] Materialized views refresh successfully
- [ ] No RLS policy regressions
- [ ] 24-hour staging soak test completed
