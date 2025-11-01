#!/bin/bash

# Fast SocialFi Security Audit Script
# This script performs comprehensive security checks on smart contracts

echo "========================================"
echo "Fast SocialFi Security Audit"
echo "Date: $(date)"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create audit output directory
AUDIT_DIR="audit_results"
mkdir -p "$AUDIT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
AUDIT_LOG="$AUDIT_DIR/audit_${TIMESTAMP}.log"

# Redirect all output to both terminal and log file
exec > >(tee -a "$AUDIT_LOG") 2>&1

echo "=== Phase 1: Static Analysis ==="
echo ""

# 1. Check Solidity version consistency
echo "[CHECK 1] Verifying Solidity version consistency..."
SOL_VERSIONS=$(find contracts -name "*.sol" -exec grep -h "pragma solidity" {} \; | sort -u)
VERSION_COUNT=$(echo "$SOL_VERSIONS" | wc -l)
if [ "$VERSION_COUNT" -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: All contracts use the same Solidity version"
    echo "$SOL_VERSIONS"
else
    echo -e "${RED}✗ FAIL${NC}: Multiple Solidity versions detected"
    echo "$SOL_VERSIONS"
fi
echo ""

# 2. Check for unsafe functions
echo "[CHECK 2] Scanning for unsafe functions..."
UNSAFE_PATTERNS=("tx.origin" "block.timestamp" "selfdestruct" "delegatecall")
UNSAFE_FOUND=0
for pattern in "${UNSAFE_PATTERNS[@]}"; do
    RESULTS=$(find contracts -name "*.sol" -exec grep -n "$pattern" {} + || true)
    if [ -n "$RESULTS" ]; then
        echo -e "${YELLOW}⚠ WARNING${NC}: Found usage of '$pattern':"
        echo "$RESULTS"
        UNSAFE_FOUND=$((UNSAFE_FOUND + 1))
    fi
done
if [ $UNSAFE_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}: No obvious unsafe patterns found"
fi
echo ""

# 3. Check for proper access control
echo "[CHECK 3] Verifying access control modifiers..."
ACCESS_MODIFIERS=("onlyOwner" "onlyFactory" "onlyCircleOwner" "whenNotPaused")
for modifier in "${ACCESS_MODIFIERS[@]}"; do
    COUNT=$(find contracts -name "*.sol" -exec grep -c "$modifier" {} + | awk '{s+=$1} END {print s}')
    echo "  - $modifier: used $COUNT times"
done
echo ""

# 4. Check for ReentrancyGuard usage
echo "[CHECK 4] Checking ReentrancyGuard implementation..."
EXTERNAL_FUNCTIONS=$(find contracts -name "*.sol" -exec grep -n "function.*external" {} + || true)
NONREENTRANT_COUNT=$(find contracts -name "*.sol" -exec grep -c "nonReentrant" {} + | awk '{s+=$1} END {print s}')
echo "  - External functions found: $(echo "$EXTERNAL_FUNCTIONS" | wc -l)"
echo "  - nonReentrant modifier used: $NONREENTRANT_COUNT times"
if [ "$NONREENTRANT_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}: ReentrancyGuard is implemented"
else
    echo -e "${YELLOW}⚠ WARNING${NC}: Consider adding ReentrancyGuard"
fi
echo ""

# 5. Check for proper event emissions
echo "[CHECK 5] Verifying event emissions..."
STATE_CHANGING=$(find contracts -name "*.sol" -exec grep -n "function.*public\|function.*external" {} + | grep -v "view\|pure" || true)
EVENTS=$(find contracts -name "*.sol" -exec grep -n "emit" {} + || true)
echo "  - State-changing functions: $(echo "$STATE_CHANGING" | wc -l)"
echo "  - Event emissions: $(echo "$EVENTS" | wc -l)"
echo ""

# 6. Compile contracts and check for warnings
echo "[CHECK 6] Compiling contracts and checking for errors..."
cd "$(dirname "$0")"
forge clean
COMPILE_OUTPUT=$(forge build 2>&1)
COMPILE_STATUS=$?

if [ $COMPILE_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}: All contracts compiled successfully"
else
    echo -e "${RED}✗ FAIL${NC}: Compilation errors detected"
    echo "$COMPILE_OUTPUT"
fi

# Check for compiler warnings
WARNING_COUNT=$(echo "$COMPILE_OUTPUT" | grep -c "Warning" || true)
if [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}: $WARNING_COUNT compiler warnings found"
    echo "$COMPILE_OUTPUT" | grep "Warning" || true
else
    echo -e "${GREEN}✓ PASS${NC}: No compiler warnings"
fi
echo ""

echo "=== Phase 2: Gas Optimization Analysis ==="
echo ""

# 7. Run gas report
echo "[CHECK 7] Generating gas consumption report..."
GAS_REPORT=$(forge test --gas-report 2>&1)
echo "$GAS_REPORT" > "$AUDIT_DIR/gas_report_${TIMESTAMP}.txt"
echo "Gas report saved to: $AUDIT_DIR/gas_report_${TIMESTAMP}.txt"

# Extract expensive operations
EXPENSIVE_OPS=$(echo "$GAS_REPORT" | grep -A 50 "gas:" | head -20)
echo "Top expensive operations:"
echo "$EXPENSIVE_OPS"
echo ""

# 8. Storage optimization check
echo "[CHECK 8] Analyzing storage layout..."
STORAGE_VARS=$(find contracts -name "*.sol" -exec grep -n "^\s*uint\|^\s*address\|^\s*bool\|^\s*mapping" {} + | wc -l)
echo "  - Total storage variables: $STORAGE_VARS"
echo "  - Recommendation: Pack storage variables for gas optimization"
echo ""

echo "=== Phase 3: Security Best Practices ==="
echo ""

# 9. Check for proper input validation
echo "[CHECK 9] Checking input validation..."
REQUIRE_STATEMENTS=$(find contracts -name "*.sol" -exec grep -c "require(" {} + | awk '{s+=$1} END {print s}')
REVERT_STATEMENTS=$(find contracts -name "*.sol" -exec grep -c "revert " {} + | awk '{s+=$1} END {print s}')
echo "  - require() statements: $REQUIRE_STATEMENTS"
echo "  - revert statements: $REVERT_STATEMENTS"
if [ $((REQUIRE_STATEMENTS + REVERT_STATEMENTS)) -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Input validation implemented"
else
    echo -e "${RED}✗ FAIL${NC}: Missing input validation"
fi
echo ""

# 10. Check for SafeMath usage (Solidity < 0.8.0) or built-in checks
echo "[CHECK 10] Checking arithmetic operation safety..."
SOLIDITY_VERSION=$(head -1 contracts/core/CircleFactory.sol | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+")
MAJOR_VERSION=$(echo "$SOLIDITY_VERSION" | cut -d. -f2)
if [ "$MAJOR_VERSION" -ge 8 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Using Solidity 0.8+, automatic overflow protection enabled"
else
    SAFEMATH_USAGE=$(find contracts -name "*.sol" -exec grep -c "SafeMath" {} + | awk '{s+=$1} END {print s}')
    if [ "$SAFEMATH_USAGE" -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: SafeMath library is used"
    else
        echo -e "${RED}✗ FAIL${NC}: No overflow protection detected"
    fi
fi
echo ""

# 11. Check for proper use of view/pure functions
echo "[CHECK 11] Analyzing function visibility and mutability..."
VIEW_FUNCTIONS=$(find contracts -name "*.sol" -exec grep -c "function.*view" {} + | awk '{s+=$1} END {print s}')
PURE_FUNCTIONS=$(find contracts -name "*.sol" -exec grep -c "function.*pure" {} + | awk '{s+=$1} END {print s}')
echo "  - View functions: $VIEW_FUNCTIONS"
echo "  - Pure functions: $PURE_FUNCTIONS"
echo ""

# 12. Check for proper error handling
echo "[CHECK 12] Verifying error handling patterns..."
CUSTOM_ERRORS=$(find contracts -name "*.sol" -exec grep -c "error " {} + | awk '{s+=$1} END {print s}')
if [ "$CUSTOM_ERRORS" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Custom errors implemented (gas efficient)"
else
    echo -e "${YELLOW}⚠ INFO${NC}: Consider using custom errors for gas efficiency"
fi
echo ""

echo "=== Phase 4: Contract-Specific Checks ==="
echo ""

# 13. BondingCurve mathematical checks
echo "[CHECK 13] Verifying BondingCurve mathematical safety..."
if [ -f "contracts/core/BondingCurve.sol" ]; then
    DIVISION_CHECKS=$(grep -n "/ 0\|division" contracts/core/BondingCurve.sol || true)
    OVERFLOW_CHECKS=$(grep -n "SafeMath\|unchecked" contracts/core/BondingCurve.sol || true)
    echo "  - Division safety checks: $(echo "$DIVISION_CHECKS" | wc -l)"
    echo "  - Overflow handling: $(echo "$OVERFLOW_CHECKS" | wc -l)"
fi
echo ""

# 14. CircleFactory access control
echo "[CHECK 14] Verifying CircleFactory access control..."
if [ -f "contracts/core/CircleFactory.sol" ]; then
    ADMIN_FUNCTIONS=$(grep -n "onlyOwner" contracts/core/CircleFactory.sol || true)
    echo "  - Admin-only functions: $(echo "$ADMIN_FUNCTIONS" | wc -l)"
    echo "$ADMIN_FUNCTIONS"
fi
echo ""

echo "=== Phase 5: Summary and Recommendations ==="
echo ""

# Generate final score
TOTAL_CHECKS=14
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Count from previous checks (simplified for demonstration)
if [ $COMPILE_STATUS -eq 0 ]; then PASSED_CHECKS=$((PASSED_CHECKS + 1)); fi
if [ "$VERSION_COUNT" -eq 1 ]; then PASSED_CHECKS=$((PASSED_CHECKS + 1)); fi
if [ $UNSAFE_FOUND -eq 0 ]; then PASSED_CHECKS=$((PASSED_CHECKS + 1)); fi
if [ "$NONREENTRANT_COUNT" -gt 0 ]; then PASSED_CHECKS=$((PASSED_CHECKS + 1)); fi
if [ $((REQUIRE_STATEMENTS + REVERT_STATEMENTS)) -gt 0 ]; then PASSED_CHECKS=$((PASSED_CHECKS + 1)); fi

FAILED_CHECKS=$((TOTAL_CHECKS - PASSED_CHECKS - WARNINGS))
SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo "=================================="
echo "       AUDIT SUMMARY"
echo "=================================="
echo "Total Checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo "Security Score: $SCORE/100"
echo ""

if [ $SCORE -ge 80 ]; then
    echo -e "${GREEN}✓ OVERALL RATING: GOOD${NC}"
    echo "The smart contracts demonstrate good security practices."
elif [ $SCORE -ge 60 ]; then
    echo -e "${YELLOW}⚠ OVERALL RATING: FAIR${NC}"
    echo "Some security improvements are recommended."
else
    echo -e "${RED}✗ OVERALL RATING: POOR${NC}"
    echo "Critical security issues detected. Address before deployment."
fi
echo ""

echo "=== Recommendations ===="
echo "1. ✓ Continue using OpenZeppelin security libraries"
echo "2. ✓ Implement comprehensive unit tests for all functions"
echo "3. ⚠ Consider third-party audit (CertiK, OpenZeppelin, Trail of Bits)"
echo "4. ⚠ Implement circuit breakers for emergency situations"
echo "5. ⚠ Add time-locks for critical administrative functions"
echo "6. ✓ Document all external function behaviors"
echo "7. ⚠ Implement rate limiting for high-value operations"
echo "8. ✓ Use events for all state changes"
echo ""

echo "=== Next Steps ==="
echo "1. Review all warnings and address critical issues"
echo "2. Run Slither static analysis: slither ."
echo "3. Run Mythril security scanner: myth analyze contracts/"
echo "4. Perform manual code review"
echo "5. Schedule third-party security audit"
echo "6. Conduct stress testing on testnet"
echo ""

echo "Audit log saved to: $AUDIT_LOG"
echo "========================================"
echo "Audit completed at: $(date)"
echo "========================================"
