#!/usr/bin/env bash
#
# Test Suite for get_crossword.sh
#
# This test suite validates functionality of the crossword script including:
# - Command-line option parsing
# - Configuration management
# - Error handling
# - URL generation
# - Output formatting
# - Environment variable overrides
#
# Usage: ./test_suite.sh [--verbose] [--pattern PATTERN]
#

set -euo pipefail

# Test framework variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CROSSWORD_SCRIPT="$SCRIPT_DIR/get_crossword.sh"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
VERBOSE=false
TEST_PATTERN=""
TEMP_DIR=""
ORIGINAL_CONFIG=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test framework functions
setup_test_environment() {
    # Create temporary directory for test files
    TEMP_DIR=$(mktemp -d)
    
    # Backup original config if it exists
    if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
        ORIGINAL_CONFIG="$TEMP_DIR/config.sh.backup"
        cp "$SCRIPT_DIR/config.sh" "$ORIGINAL_CONFIG"
    fi
    
    # Create test cookies file
    mkdir -p "$TEMP_DIR/cookies"
    echo "# Test cookies file" > "$TEMP_DIR/cookies/test_cookies.txt"
    
    if [[ $VERBOSE == true ]]; then
        echo "Test environment setup in: $TEMP_DIR"
    fi
}

cleanup_test_environment() {
    # Restore original config
    if [[ -n "$ORIGINAL_CONFIG" && -f "$ORIGINAL_CONFIG" ]]; then
        cp "$ORIGINAL_CONFIG" "$SCRIPT_DIR/config.sh"
    fi
    
    # Clean up temp directory
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

log_test() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        INFO)  [[ $VERBOSE == true ]] && echo -e "${BLUE}[INFO]${NC} $message" ;;
        PASS)  echo -e "${GREEN}[PASS]${NC} $message" ;;
        FAIL)  echo -e "${RED}[FAIL]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
    esac
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    # Skip test if pattern specified and doesn't match
    if [[ -n "$TEST_PATTERN" && "$test_name" != *"$TEST_PATTERN"* ]]; then
        return 0
    fi
    
    ((TESTS_RUN++))
    
    log_test INFO "Running test: $test_name"
    
    if $test_function; then
        ((TESTS_PASSED++))
        log_test PASS "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_test FAIL "$test_name"
        return 1
    fi
}

# Helper function to run crossword script and capture output
run_crossword() {
    local args=()
    
    # Copy arguments to array
    while [[ $# -gt 0 ]]; do
        args+=("$1")
        shift
    done
    
    # Always use dry-run mode for tests to avoid actual downloads
    local has_dry_run=false
    for arg in "${args[@]:-}"; do
        if [[ "$arg" == "-n" ]]; then
            has_dry_run=true
            break
        fi
    done
    
    if [[ $has_dry_run == false ]]; then
        args+=("-n")
    fi
    
    # Capture both stdout and stderr
    "$CROSSWORD_SCRIPT" "${args[@]}" 2>&1 || true
}

# Helper function to check if output contains expected text
assert_contains() {
    local output="$1"
    local expected="$2"
    local test_description="${3:-}"
    
    if [[ "$output" == *"$expected"* ]]; then
        [[ $VERBOSE == true ]] && log_test INFO "✓ Found expected text: '$expected'"
        return 0
    else
        log_test ERROR "✗ Expected text not found: '$expected'"
        [[ $VERBOSE == true ]] && log_test ERROR "Actual output: $output"
        return 1
    fi
}

# Helper function to check if output does NOT contain text
assert_not_contains() {
    local output="$1"
    local unexpected="$2"
    
    if [[ "$output" != *"$unexpected"* ]]; then
        [[ $VERBOSE == true ]] && log_test INFO "✓ Correctly does not contain: '$unexpected'"
        return 0
    else
        log_test ERROR "✗ Found unexpected text: '$unexpected'"
        return 1
    fi
}

# Helper function to check exit code
assert_exit_code() {
    local actual_output="$1"
    local expected_code="$2"
    
    # Extract exit code from output (our run_crossword function captures it)
    if [[ "$actual_output" == *"Command exited with code $expected_code"* ]] || 
       [[ $expected_code == 0 && "$actual_output" != *"Command exited with code"* ]]; then
        [[ $VERBOSE == true ]] && log_test INFO "✓ Exit code $expected_code as expected"
        return 0
    else
        log_test ERROR "✗ Expected exit code $expected_code"
        return 1
    fi
}

# =============================================================================
# BASIC FUNCTIONALITY TESTS
# =============================================================================

test_basic_dry_run() {
    local output
    output=$(run_crossword)
    
    if [[ $VERBOSE == true ]]; then
        echo "DEBUG: Output length: ${#output}" >&2
        echo "DEBUG: First 100 chars: ${output:0:100}" >&2
    fi
    
    assert_contains "$output" "Dry-run: would run:" &&
    assert_contains "$output" "curl" &&
    assert_contains "$output" "nytimes.com"
}

test_help_option() {
    local output
    output=$(run_crossword -h)
    
    assert_contains "$output" "Usage:" &&
    assert_contains "$output" "Examples:"
}

test_offset_option() {
    local output
    output=$(run_crossword -o 1)
    
    assert_contains "$output" "Fetching puzzle list (index: 1)"
}

test_date_option() {
    local output
    output=$(run_crossword -d 2024-01-01)
    
    assert_contains "$output" "Fetching puzzle list to find puzzle for date: 2024-01-01"
}

test_random_option() {
    local output
    output=$(run_crossword -r)
    
    assert_contains "$output" "Fetching puzzle list for random selection" &&
    assert_contains "$output" "era"
}

# =============================================================================
# CONFIGURATION TESTS
# =============================================================================

test_config_loading() {
    # Create a test config file
    local test_config="$TEMP_DIR/test_config.sh"
    cat > "$test_config" << 'EOF'
# Test configuration
COOKIES="./test_cookies.txt"
VERBOSITY=2
DEFAULT_LARGE_PRINT=true
EOF

    # Copy to main location
    cp "$test_config" "$SCRIPT_DIR/config.sh"
    
    local output
    output=$(run_crossword)
    
    assert_contains "$output" "Loading configuration from:"
}

test_environment_override() {
    local output
    output=$(VERBOSITY=2 run_crossword)
    
    assert_contains "$output" "Loading configuration from:"
}

test_default_mode_random() {
    local output
    output=$(DEFAULT_MODE=random VERBOSITY=2 run_crossword)
    
    assert_contains "$output" "Using default random mode" &&
    assert_contains "$output" "random selection"
}

test_default_large_print() {
    local output
    output=$(DEFAULT_LARGE_PRINT=true run_crossword)
    
    assert_contains "$output" "large_print=true"
}

# =============================================================================
# FORMAT OPTION TESTS
# =============================================================================

test_large_print_flag() {
    local output
    output=$(run_crossword -l)
    
    assert_contains "$output" "large_print=true"
}

test_left_handed_flag() {
    local output
    output=$(run_crossword -L)
    
    assert_contains "$output" "southpaw=true"
}

test_ink_saver_flag() {
    local output
    output=$(run_crossword -i)
    
    assert_contains "$output" "block_opacity=30"
}

test_solution_flag() {
    local output
    output=$(run_crossword -S)
    
    assert_contains "$output" ".ans.pdf"
}

test_multiple_format_flags() {
    local output
    output=$(run_crossword -l -L -i)
    
    assert_contains "$output" "large_print=true" &&
    assert_contains "$output" "southpaw=true" &&
    assert_contains "$output" "block_opacity=30"
}

# =============================================================================
# ERROR HANDLING TESTS
# =============================================================================

test_invalid_date_format() {
    local output
    output=$(run_crossword -d "invalid-date" 2>&1)
    
    assert_contains "$output" "ERROR: Date must be in YYYY-MM-DD format"
}

test_invalid_date_value() {
    local output
    output=$(run_crossword -d "2024-13-45" 2>&1)
    
    assert_contains "$output" "ERROR: Invalid date"
}

test_missing_cookie_file() {
    local output
    output=$(run_crossword -c "/nonexistent/cookies.txt" 2>&1)
    
    assert_contains "$output" "ERROR" &&
    assert_contains "$output" "cookie file not found"
}

test_conflicting_options() {
    local output
    output=$(run_crossword -r -d 2024-01-01 2>&1)
    
    assert_contains "$output" "ERROR: Cannot use multiple selection options"
}

test_invalid_offset() {
    local output
    output=$(run_crossword -o "abc" 2>&1)
    
    assert_contains "$output" "ERROR: offset must be an integer"
}

# =============================================================================
# VALIDATION TESTS
# =============================================================================

test_config_validation_weights() {
    # Create invalid config
    cat > "$SCRIPT_DIR/config.sh" << 'EOF'
RANDOM_HISTORICAL_WEIGHT=60
RANDOM_MODERN_WEIGHT=30
EOF

    local output
    output=$(run_crossword 2>&1)
    
    assert_contains "$output" "ERROR" &&
    assert_contains "$output" "must sum to 100"
}

test_config_validation_boolean() {
    # Create invalid config
    cat > "$SCRIPT_DIR/config.sh" << 'EOF'
DEFAULT_LARGE_PRINT=maybe
EOF

    local output
    output=$(run_crossword 2>&1)
    
    assert_contains "$output" "ERROR" &&
    assert_contains "$output" "must be 'true' or 'false'"
}

# =============================================================================
# OUTPUT FORMAT TESTS
# =============================================================================

test_verbosity_levels() {
    local output_quiet output_normal output_verbose
    
    output_quiet=$(VERBOSITY=0 run_crossword 2>&1)
    output_normal=$(VERBOSITY=1 run_crossword 2>&1)
    output_verbose=$(VERBOSITY=2 run_crossword 2>&1)
    
    # Quiet should have less output than normal
    [[ ${#output_quiet} -lt ${#output_normal} ]] &&
    # Verbose should have more output than normal  
    [[ ${#output_verbose} -gt ${#output_normal} ]] &&
    # Verbose should contain loading message
    assert_contains "$output_verbose" "Loading configuration"
}

test_url_construction() {
    local output
    output=$(run_crossword -d 2024-01-01 -l -L -i)
    
    # Should contain all URL parameters
    assert_contains "$output" "large_print=true" &&
    assert_contains "$output" "southpaw=true" &&
    assert_contains "$output" "block_opacity=30" &&
    # Parameters should be properly joined with &
    assert_contains "$output" "large_print=true&southpaw=true&block_opacity=30"
}

# =============================================================================
# UTILITY FUNCTION TESTS
# =============================================================================

test_date_validation_function() {
    # Test valid dates by checking script accepts them
    local output1 output2
    output1=$(run_crossword -d "2024-01-01" 2>&1)
    output2=$(run_crossword -d "2024-12-31" 2>&1)
    
    assert_not_contains "$output1" "ERROR: Date must be in YYYY-MM-DD format" &&
    assert_not_contains "$output2" "ERROR: Date must be in YYYY-MM-DD format"
}

test_expand_tilde_function() {
    local output
    output=$(run_crossword -c "~/nonexistent.txt" 2>&1)
    
    # Should expand ~ to home directory in error message
    assert_contains "$output" "$HOME" &&
    assert_not_contains "$output" "~/"
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

test_full_workflow_recent() {
    local output
    output=$(VERBOSITY=2 run_crossword -l -s)
    
    assert_contains "$output" "Loading configuration" &&
    assert_contains "$output" "Fetching puzzle list" &&
    assert_contains "$output" "large_print=true" &&
    assert_contains "$output" "Dry-run: would run:"
}

test_full_workflow_random() {
    local output
    output=$(VERBOSITY=2 run_crossword -r -i)
    
    assert_contains "$output" "random selection" &&
    assert_contains "$output" "Selected random puzzle" &&
    assert_contains "$output" "block_opacity=30"
}

test_full_workflow_date() {
    local output
    output=$(run_crossword -d 2024-06-15 -L -S)
    
    assert_contains "$output" "date: 2024-06-15" &&
    assert_contains "$output" ".ans.pdf" &&
    assert_contains "$output" "southpaw=true"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run the test suite for get_crossword.sh

OPTIONS:
    --verbose, -v       Enable verbose output
    --pattern, -p PATTERN  Run only tests matching PATTERN
    --help, -h          Show this help message

EXAMPLES:
    $0                  Run all tests
    $0 --verbose        Run all tests with detailed output
    $0 -p config        Run only tests with 'config' in the name
    $0 -p error         Run only error handling tests
EOF
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --pattern|-p)
                TEST_PATTERN="$2"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
    
    # Check if crossword script exists
    if [[ ! -f "$CROSSWORD_SCRIPT" ]]; then
        log_test ERROR "Crossword script not found: $CROSSWORD_SCRIPT"
        exit 1
    fi
    
    echo "🧪 Running test suite for get_crossword.sh"
    echo "📁 Script location: $CROSSWORD_SCRIPT"
    [[ -n "$TEST_PATTERN" ]] && echo "🔍 Test pattern: $TEST_PATTERN"
    echo ""
    
    # Setup test environment
    setup_test_environment
    trap cleanup_test_environment EXIT
    
    # Run all tests
    echo "=== Basic Functionality Tests ==="
    run_test "Basic dry-run functionality" test_basic_dry_run
    run_test "Help option display" test_help_option
    run_test "Offset option parsing" test_offset_option
    run_test "Date option parsing" test_date_option
    run_test "Random option functionality" test_random_option
    
    echo ""
    echo "=== Configuration Tests ==="
    run_test "Configuration file loading" test_config_loading
    run_test "Environment variable override" test_environment_override
    run_test "Default mode random setting" test_default_mode_random
    run_test "Default large print setting" test_default_large_print
    
    echo ""
    echo "=== Format Option Tests ==="
    run_test "Large print flag" test_large_print_flag
    run_test "Left-handed flag" test_left_handed_flag
    run_test "Ink saver flag" test_ink_saver_flag
    run_test "Solution flag" test_solution_flag
    run_test "Multiple format flags" test_multiple_format_flags
    
    echo ""
    echo "=== Error Handling Tests ==="
    run_test "Invalid date format rejection" test_invalid_date_format
    run_test "Invalid date value rejection" test_invalid_date_value
    run_test "Missing cookie file error" test_missing_cookie_file
    run_test "Conflicting options error" test_conflicting_options
    run_test "Invalid offset error" test_invalid_offset
    
    echo ""
    echo "=== Validation Tests ==="
    run_test "Configuration weight validation" test_config_validation_weights
    run_test "Configuration boolean validation" test_config_validation_boolean
    
    echo ""
    echo "=== Output Format Tests ==="
    run_test "Verbosity level handling" test_verbosity_levels
    run_test "URL parameter construction" test_url_construction
    
    echo ""
    echo "=== Utility Function Tests ==="
    run_test "Date validation function" test_date_validation_function
    run_test "Tilde expansion function" test_expand_tilde_function
    
    echo ""
    echo "=== Integration Tests ==="
    run_test "Full workflow: recent puzzle" test_full_workflow_recent
    run_test "Full workflow: random puzzle" test_full_workflow_random
    run_test "Full workflow: specific date" test_full_workflow_date
    
    # Print summary
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
        echo ""
        echo "❌ Some tests failed. Please review the output above."
        exit 1
    else
        echo -e "Tests failed: ${GREEN}0${NC}"
        echo ""
        echo "✅ All tests passed! 🎉"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"