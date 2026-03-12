#!/bin/bash
# ============================================================
# Vottery Migration Verification Test Runner
# Automated test execution for staging environment
# Usage: ./supabase/tests/run_verification_tests.sh STAGING_DB_URL
# ============================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  VOTTERY MIGRATION VERIFICATION SUITE${NC}"
echo -e "${BLUE}  Staging Environment Test Runner${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Validate arguments
STAGING_URL=$1
if [ -z "$STAGING_URL" ]; then
  echo -e "${RED}ERROR: STAGING_DB_URL is required${NC}"
  echo "Usage: $0 STAGING_DB_URL"
  echo "Example: $0 postgresql://postgres:password@db.staging.supabase.co:5432/postgres"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Timestamp for this run
RUN_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SUMMARY_LOG="$RESULTS_DIR/summary_$RUN_TIMESTAMP.log"

echo -e "${BLUE}Test run started: $(date)${NC}"
echo -e "${BLUE}Results directory: $RESULTS_DIR${NC}"
echo ""

# Function to run a test file and count results
run_test_file() {
  local test_name="$1"
  local test_file="$2"
  local expected_count="$3"
  local log_file="$RESULTS_DIR/${test_name}_$RUN_TIMESTAMP.log"

  echo -e "${BLUE}Running: $test_name...${NC}"

  if [ ! -f "$test_file" ]; then
    echo -e "${RED}ERROR: Test file not found: $test_file${NC}"
    echo "0"
    return 1
  fi

  # Run the test file and capture output
  if psql "$STAGING_URL" -f "$test_file" > "$log_file" 2>&1; then
    local passed_count
    passed_count=$(grep -c 'PASSED' "$log_file" 2>/dev/null || echo "0")
    local failed_count
    failed_count=$(grep -c 'FAILED\|ERROR' "$log_file" 2>/dev/null || echo "0")
    local warning_count
    warning_count=$(grep -c 'WARNING' "$log_file" 2>/dev/null || echo "0")

    if [ "$failed_count" -gt 0 ]; then
      echo -e "  ${RED}✗ FAILED: $passed_count/$expected_count passed, $failed_count failures${NC}"
      echo -e "  ${YELLOW}  Warnings: $warning_count${NC}"
      echo -e "  ${YELLOW}  Log: $log_file${NC}"
    else
      echo -e "  ${GREEN}✓ PASSED: $passed_count/$expected_count tests passed${NC}"
      if [ "$warning_count" -gt 0 ]; then
        echo -e "  ${YELLOW}  Warnings: $warning_count (review log for details)${NC}"
      fi
    fi
    echo "$passed_count"
  else
    echo -e "  ${RED}✗ ERROR: psql execution failed${NC}"
    echo -e "  ${YELLOW}  Log: $log_file${NC}"
    echo "0"
    return 1
  fi
}

# ============================================================
# STEP 1: RLS Policy Tests (15 tests)
# ============================================================
echo -e "${YELLOW}--- Step 1: RLS Policy Tests ---${NC}"
RLS_PASSED=$(run_test_file "rls_tests" "$SCRIPT_DIR/rls_policy_tests.sql" "15")
echo -e "  RLS tests passed: ${GREEN}$RLS_PASSED/15${NC}"
echo ""

# ============================================================
# STEP 2: Index Verification Tests (12 tests)
# ============================================================
echo -e "${YELLOW}--- Step 2: Index Verification Tests ---${NC}"
INDEX_PASSED=$(run_test_file "index_tests" "$SCRIPT_DIR/index_verification_tests.sql" "12")
echo -e "  Index tests passed: ${GREEN}$INDEX_PASSED/12${NC}"
echo ""

# ============================================================
# STEP 3: RPC Function Tests (8 tests)
# ============================================================
echo -e "${YELLOW}--- Step 3: RPC Function Tests ---${NC}"
RPC_PASSED=$(run_test_file "rpc_tests" "$SCRIPT_DIR/rpc_function_tests.sql" "8")
echo -e "  RPC tests passed: ${GREEN}$RPC_PASSED/8${NC}"
echo ""

# ============================================================
# STEP 4: Materialized View Tests (5 tests)
# ============================================================
echo -e "${YELLOW}--- Step 4: Materialized View Tests ---${NC}"
MV_PASSED=$(run_test_file "mv_tests" "$SCRIPT_DIR/materialized_view_tests.sql" "5")
echo -e "  Materialized view tests passed: ${GREEN}$MV_PASSED/5${NC}"
echo ""

# ============================================================
# STEP 5: Performance Benchmark Tests (10 tests)
# ============================================================
echo -e "${YELLOW}--- Step 5: Performance Benchmark Tests ---${NC}"
PERF_PASSED=$(run_test_file "perf_tests" "$SCRIPT_DIR/performance_benchmark_tests.sql" "10")
echo -e "  Performance tests passed: ${GREEN}$PERF_PASSED/10${NC}"
echo ""

# ============================================================
# STEP 6: Full Suite Verification (50 tests)
# ============================================================
echo -e "${YELLOW}--- Step 6: Full Migration Verification Suite ---${NC}"
SUITE_LOG="$RESULTS_DIR/full_suite_$RUN_TIMESTAMP.log"
if psql "$STAGING_URL" -f "$SCRIPT_DIR/migration_verification_suite.sql" > "$SUITE_LOG" 2>&1; then
  SUITE_PASSED=$(grep -c 'PASSED' "$SUITE_LOG" 2>/dev/null || echo "0")
  SUITE_FAILED=$(grep -c 'FAILED\|ERROR' "$SUITE_LOG" 2>/dev/null || echo "0")
  echo -e "  Full suite: ${GREEN}$SUITE_PASSED/50 passed${NC}, ${RED}$SUITE_FAILED failed${NC}"
else
  echo -e "  ${RED}Full suite execution failed${NC}"
  SUITE_PASSED=0
fi
echo ""

# ============================================================
# CALCULATE TOTALS
# ============================================================
TOTAL_PASSED=$((RLS_PASSED + INDEX_PASSED + RPC_PASSED + MV_PASSED + PERF_PASSED))
TOTAL_TESTS=50

# Write summary log
{
  echo "======================================================"
  echo "MIGRATION VERIFICATION SUMMARY"
  echo "Run: $(date)"
  echo "======================================================"
  echo "RLS Policy Tests:        $RLS_PASSED/15"
  echo "Index Verification:      $INDEX_PASSED/12"
  echo "RPC Function Tests:      $RPC_PASSED/8"
  echo "Materialized View Tests: $MV_PASSED/5"
  echo "Performance Benchmarks:  $PERF_PASSED/10"
  echo "------------------------------------------------------"
  echo "TOTAL:                   $TOTAL_PASSED/$TOTAL_TESTS"
  echo "======================================================"
} > "$SUMMARY_LOG"

# ============================================================
# FINAL RESULT
# ============================================================
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  TEST SUMMARY${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "  RLS Policy Tests:        ${GREEN}$RLS_PASSED/15${NC}"
echo -e "  Index Verification:      ${GREEN}$INDEX_PASSED/12${NC}"
echo -e "  RPC Function Tests:      ${GREEN}$RPC_PASSED/8${NC}"
echo -e "  Materialized View Tests: ${GREEN}$MV_PASSED/5${NC}"
echo -e "  Performance Benchmarks:  ${GREEN}$PERF_PASSED/10${NC}"
echo -e "${BLUE}------------------------------------------------------${NC}"
echo -e "  TOTAL: ${GREEN}$TOTAL_PASSED/$TOTAL_TESTS${NC}"
echo ""

if [ "$TOTAL_PASSED" -eq "$TOTAL_TESTS" ]; then
  echo -e "${GREEN}✅ All $TOTAL_TESTS tests passed! Ready for production deployment.${NC}"
  echo -e "${GREEN}   Summary log: $SUMMARY_LOG${NC}"
  exit 0
else
  FAILED_COUNT=$((TOTAL_TESTS - TOTAL_PASSED))
  echo -e "${RED}❌ $FAILED_COUNT tests failed. Review logs in: $RESULTS_DIR${NC}"
  echo -e "${YELLOW}   Summary log: $SUMMARY_LOG${NC}"
  echo -e "${YELLOW}   Fix failures before proceeding to production.${NC}"
  exit 1
fi
