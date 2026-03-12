# Production Deployment Checklist
## Vottery Database Optimization - 4 Migration Files

> ⚠️ **CRITICAL**: Complete ALL staging verification before proceeding.
> This checklist must be signed off by Dev Lead, CTO, and Security Lead.

---

## PRE-PRODUCTION REQUIREMENTS

### Staging Verification (Must be 100% Complete)
- [ ] ✅ All 50/50 staging tests passed (`run_verification_tests.sh` output)
- [ ] ✅ App tested for minimum 24 hours in staging environment
- [ ] ✅ Load testing completed: 1000 concurrent users handled
- [ ] ✅ Security audit passed: all RLS policies verified
- [ ] ✅ Performance benchmarks met: queries < 100ms average
- [ ] ✅ Cache hit rate > 95% confirmed
- [ ] ✅ Rollback procedures tested and verified in staging
- [ ] ✅ Materialized views refresh successfully (CONCURRENTLY)
- [ ] ✅ All 5 RPC functions return correct data

### Team Sign-Off
- [ ] Dev Lead approval: _________________ Date: _________
- [ ] CTO approval: _________________ Date: _________
- [ ] Security Lead approval: _________________ Date: _________

### Scheduling & Communication
- [ ] Maintenance window scheduled: _________________ (UTC)
- [ ] User notification sent (downtime alert, 48h advance notice)
- [ ] On-call engineer assigned: _________________
- [ ] Rollback engineer assigned: _________________
- [ ] Monitoring dashboards ready (Datadog, Sentry)
- [ ] Slack incident channel created: #deploy-db-optimization

---

## PRODUCTION DEPLOYMENT STEPS

### Step 1: Enable Maintenance Mode
```bash
# Set maintenance mode flag in feature flags
psql $PRODUCTION_DB_URL -c "
  UPDATE feature_flags SET enabled = false
  WHERE name IN ('vote_casting', 'election_creation')
    AND environment = 'production';
"

# Notify monitoring systems
echo "Maintenance mode enabled at $(date)" | tee -a deployment.log
```

### Step 2: Create Production Backup
```bash
# Full database backup with timestamp
supabase db dump --db-url $PRODUCTION_DB_URL > production_backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup integrity
wc -l production_backup_*.sql
ls -lh production_backup_*.sql

# Upload to secure storage
# aws s3 cp production_backup_*.sql s3://vottery-backups/db-optimization/
```

### Step 3: Push Migrations to Production
```bash
# Apply migrations in order
supabase db push --db-url $PRODUCTION_DB_URL

# Monitor for errors - expected output:
# Applying migration 20260228120000_security_rls_fixes.sql... OK
# Applying migration 20260228130000_performance_indexes.sql... OK
# Applying migration 20260228140000_query_optimizations.sql... OK
```

### Step 4: Run Verification Suite
```bash
# Run full test suite against production
./supabase/tests/run_verification_tests.sh $PRODUCTION_DB_URL

# Expected: All 50/50 tests passed
# If any failures: STOP and initiate rollback
```

### Step 5: Refresh Materialized Views
```bash
# Refresh with CONCURRENTLY to avoid table locks
psql $PRODUCTION_DB_URL -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_creator_leaderboard;"
psql $PRODUCTION_DB_URL -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_election_stats;"

# Verify refresh
psql $PRODUCTION_DB_URL -c "SELECT COUNT(*) FROM mv_creator_leaderboard;"
psql $PRODUCTION_DB_URL -c "SELECT COUNT(*) FROM mv_election_stats;"
```

### Step 6: Test Critical User Flows
```bash
# Test 1: User authentication
curl -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "$TEST_USER_EMAIL", "password": "$TEST_USER_PASSWORD"}'

# Test 2: Election feed RPC
psql $PRODUCTION_DB_URL -c "SELECT COUNT(*) FROM get_election_feed() LIMIT 1;"

# Test 3: VP transactions accessible
psql $PRODUCTION_DB_URL -c "SELECT COUNT(*) FROM vp_transactions LIMIT 1;"

# Test 4: Creator analytics RPC
psql $PRODUCTION_DB_URL -c "SELECT COUNT(*) FROM get_creator_analytics_summary() LIMIT 1;"
```

### Step 7: Monitor Error Rates (1 Hour)
```bash
# Run post-deployment monitoring queries
psql $PRODUCTION_DB_URL -f supabase/monitoring/post_deployment_monitoring.sql

# Watch error rates in Sentry dashboard
# Target: error rate < 0.1%

# Watch query performance in Datadog
# Target: p95 latency < 200ms

# Check slow query log
psql $PRODUCTION_DB_URL -c "
  SELECT query, calls, mean_exec_time, max_exec_time
  FROM pg_stat_statements
  WHERE mean_exec_time > 100
  ORDER BY mean_exec_time DESC
  LIMIT 10;
"
```

### Step 8: Disable Maintenance Mode
```bash
# Re-enable features after successful verification
psql $PRODUCTION_DB_URL -c "
  UPDATE feature_flags SET enabled = true
  WHERE name IN ('vote_casting', 'election_creation')
    AND environment = 'production';
"

echo "Maintenance mode disabled at $(date)" | tee -a deployment.log
```

---

## POST-DEPLOYMENT MONITORING (24 Hours)

### Hour 1: Critical Monitoring
- [ ] Error rate < 0.1% (check Sentry)
- [ ] API latency p95 < 200ms (check Datadog)
- [ ] No RLS policy failures in logs
- [ ] Database connections stable
- [ ] No user complaints in support channel

### Hours 2-6: Performance Monitoring
- [ ] Cache hit rate > 95%
- [ ] Index usage increasing (new indexes being used)
- [ ] Materialized view refresh completing successfully
- [ ] No deadlocks or lock contention

### Hours 6-24: Stability Monitoring
- [ ] Autovacuum running normally
- [ ] No table bloat accumulation
- [ ] Query performance stable
- [ ] All RPC functions responding correctly

---

## ROLLBACK TRIGGERS

Initiate immediate rollback if ANY of the following occur:

| Metric | Threshold | Action |
|--------|-----------|--------|
| Error rate | > 1% | Immediate rollback |
| Query latency (p95) | > 500ms | Immediate rollback |
| RLS policy failures | Any legitimate user blocked | Immediate rollback |
| User complaints | > 10/hour | Evaluate and rollback |
| Database connections | > 90% of max | Evaluate and rollback |
| Materialized view refresh | Failing repeatedly | Evaluate and rollback |

### Emergency Rollback Procedure
```bash
# EMERGENCY: Restore from backup
psql $PRODUCTION_DB_URL < production_backup_YYYYMMDD_HHMMSS.sql

# Remove applied migrations from tracking
psql $PRODUCTION_DB_URL -c "
  DELETE FROM supabase_migrations.schema_migrations
  WHERE version IN ('20260228120000', '20260228130000', '20260228140000');
"

# Verify rollback
supabase migration list --db-url $PRODUCTION_DB_URL

# Notify team
echo "ROLLBACK COMPLETED at $(date)" | tee -a deployment.log
```

---

## DEPLOYMENT LOG

| Step | Status | Time | Notes |
|------|--------|------|-------|
| Maintenance mode enabled | | | |
| Production backup created | | | |
| Migrations applied | | | |
| Verification suite passed | | | |
| Materialized views refreshed | | | |
| Critical flows tested | | | |
| Error monitoring (1hr) | | | |
| Maintenance mode disabled | | | |
| 24hr monitoring complete | | | |

**Deployment completed by:** _________________
**Deployment date/time:** _________________
**Total downtime:** _________________
