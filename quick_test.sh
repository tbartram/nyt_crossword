#!/usr/bin/env bash
# Quick test runner - runs the most important tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🧪 Running Quick Test Suite for get_crossword.sh"
echo ""

# Test 1: Basic dry-run functionality
echo "1️⃣  Testing basic dry-run functionality..."
output=$(./get_crossword.sh -n 2>&1 || true)
if [[ "$output" == *"Dry-run: would run:"* && "$output" == *"curl"* ]]; then
    echo "✅ PASS - Basic functionality works"
else
    echo "❌ FAIL - Basic functionality broken"
    echo "Output: $output"
fi

# Test 2: Help option
echo ""
echo "2️⃣  Testing help option..."
output=$(./get_crossword.sh -h 2>&1 || true)
if [[ "$output" == *"Usage:"* && "$output" == *"Examples:"* ]]; then
    echo "✅ PASS - Help option works"
else
    echo "❌ FAIL - Help option broken"
fi

# Test 3: Large print flag
echo ""
echo "3️⃣  Testing large print flag..."
output=$(./get_crossword.sh -l -n 2>&1 || true)
if [[ "$output" == *"large_print=true"* ]]; then
    echo "✅ PASS - Large print flag works"
else
    echo "❌ FAIL - Large print flag broken"
fi

# Test 4: Configuration override
echo ""
echo "4️⃣  Testing configuration override..."
output=$(DEFAULT_LARGE_PRINT=true ./get_crossword.sh -n 2>&1 || true)
if [[ "$output" == *"large_print=true"* ]]; then
    echo "✅ PASS - Configuration override works"
else
    echo "❌ FAIL - Configuration override broken"
fi

# Test 5: Error handling
echo ""
echo "5️⃣  Testing error handling..."
output=$(./get_crossword.sh -d "invalid" -n 2>&1 || true)
if [[ "$output" == *"ERROR"* && "$output" == *"Date must be in YYYY-MM-DD format"* ]]; then
    echo "✅ PASS - Error handling works"
else
    echo "❌ FAIL - Error handling broken"
fi

# Test 6: Random mode
echo ""
echo "6️⃣  Testing random mode..."
output=$(./get_crossword.sh -r -n 2>&1 || true)
if [[ "$output" == *"random selection"* && "$output" == *"era"* ]]; then
    echo "✅ PASS - Random mode works"
else
    echo "❌ FAIL - Random mode broken"
fi

# Test 7: Multiple flags
echo ""
echo "7️⃣  Testing multiple format flags..."
output=$(./get_crossword.sh -l -L -i -n 2>&1 || true)
if [[ "$output" == *"large_print=true"* && "$output" == *"southpaw=true"* && "$output" == *"block_opacity=30"* ]]; then
    echo "✅ PASS - Multiple format flags work"
else
    echo "❌ FAIL - Multiple format flags broken"
fi

# Test 8: Date selection
echo ""
echo "8️⃣  Testing date selection..."
output=$(./get_crossword.sh -d 2024-01-01 -n 2>&1 || true)
if [[ "$output" == *"date: 2024-01-01"* ]]; then
    echo "✅ PASS - Date selection works"
else
    echo "❌ FAIL - Date selection broken"
fi

echo ""
echo "🎯 Quick test suite completed!"
echo "Run './test_suite.sh --verbose' for comprehensive testing."