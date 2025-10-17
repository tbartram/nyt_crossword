# Test Suite for NYT Crossword Script

This directory contains a comprehensive test suite for the `get_crossword.sh` script. The test suite validates functionality, configuration management, error handling, and user interface behaviors.

## Quick Start

### Run Quick Tests (Recommended)
```bash
./quick_test.sh
```
Runs 8 essential tests covering the most important functionality in under 10 seconds.

### Run Full Test Suite
```bash
./test_suite.sh
```
Runs comprehensive test suite with 25+ tests covering all functionality.

### Run Specific Tests
```bash
./test_suite.sh -p "Basic"          # Run tests with "Basic" in the name
./test_suite.sh -p "config"         # Run configuration tests
./test_suite.sh -p "error"          # Run error handling tests
./test_suite.sh --verbose           # Run with detailed output
```

## Test Categories

### 🔧 Basic Functionality Tests
- ✅ **Basic dry-run functionality** - Core script execution
- ✅ **Help option display** - Usage information
- ✅ **Offset option parsing** - Recent puzzle selection
- ✅ **Date option parsing** - Specific date selection  
- ✅ **Random option functionality** - Random puzzle selection

### ⚙️ Configuration Tests
- ✅ **Configuration file loading** - config.sh parsing
- ✅ **Environment variable override** - CLI environment control
- ✅ **Default mode settings** - recent vs random defaults
- ✅ **Default format options** - large print, left-handed, etc.

### 🎨 Format Option Tests
- ✅ **Large print flag** (-l) - URL parameter generation
- ✅ **Left-handed flag** (-L) - Southpaw URL parameter
- ✅ **Ink saver flag** (-i) - Block opacity parameter
- ✅ **Solution flag** (-S) - Answer file generation
- ✅ **Multiple format flags** - Combined parameters

### 🚨 Error Handling Tests
- ✅ **Invalid date format rejection** - YYYY-MM-DD validation
- ✅ **Invalid date value rejection** - Calendar date validation
- ✅ **Missing cookie file error** - File existence checking
- ✅ **Conflicting options error** - Mutually exclusive flags
- ✅ **Invalid offset error** - Numeric validation

### 🔍 Validation Tests
- ✅ **Configuration weight validation** - Random era percentages
- ✅ **Configuration boolean validation** - true/false settings
- ✅ **Date range validation** - Era boundary checking
- ✅ **URL parameter construction** - Proper encoding

### 📄 Output Format Tests
- ✅ **Verbosity level handling** - Message filtering
- ✅ **URL construction** - Parameter joining
- ✅ **Log message formatting** - Consistent output

### 🛠️ Utility Function Tests
- ✅ **Date validation function** - Internal date checking
- ✅ **Tilde expansion function** - Home directory handling
- ✅ **File path resolution** - Absolute path handling

### 🔄 Integration Tests
- ✅ **Full workflow: recent puzzle** - End-to-end recent mode
- ✅ **Full workflow: random puzzle** - End-to-end random mode
- ✅ **Full workflow: specific date** - End-to-end date mode

## Test Framework Features

### 🎯 Smart Test Execution
- **Automatic dry-run mode** - Never downloads actual files
- **Isolated test environment** - Temporary directories and config backups
- **Pattern matching** - Run specific subsets of tests
- **Verbose output** - Detailed debugging information

### 🛡️ Safety Features
- **Configuration backup/restore** - Preserves original config.sh
- **Temporary file cleanup** - Automatic cleanup on exit
- **Error isolation** - Failed tests don't affect others
- **Network mocking** - Tests work offline

### 📊 Reporting
- **Pass/fail summary** - Clear test results
- **Colored output** - Visual success/failure indicators
- **Detailed error messages** - Debugging information
- **Test count tracking** - Progress monitoring

## Usage Examples

### Development Workflow
```bash
# Quick validation after changes
./quick_test.sh

# Full validation before commits
./test_suite.sh

# Debug specific functionality
./test_suite.sh -p "config" --verbose

# Test error handling
./test_suite.sh -p "error" --verbose
```

### Continuous Integration
```bash
# Add to CI pipeline
./quick_test.sh || exit 1
```

### Adding New Tests
1. Add test function to `test_suite.sh`
2. Follow naming convention: `test_description_here()`
3. Use helper functions: `assert_contains()`, `assert_not_contains()`
4. Register test in main() function with `run_test`

### Test Function Template
```bash
test_new_functionality() {
    local output
    output=$(run_crossword --new-flag)
    
    assert_contains "$output" "expected text" &&
    assert_not_contains "$output" "unexpected text"
}
```

## Helper Functions

### `run_crossword(args...)`
- Executes crossword script with given arguments
- Automatically adds `-n` (dry-run) if not present
- Captures both stdout and stderr
- Returns combined output

### `assert_contains(output, expected)`
- Checks if output contains expected text
- Returns 0 if found, 1 if not found
- Logs detailed error messages

### `assert_not_contains(output, unexpected)`
- Checks if output does NOT contain text
- Returns 0 if not found, 1 if found

### `log_test(level, message)`
- Logs messages with appropriate formatting
- Levels: INFO, PASS, FAIL, WARN, ERROR
- Colored output for easy scanning

## Troubleshooting

### Test Failures
1. **Check verbose output**: Add `--verbose` flag
2. **Run individual tests**: Use `-p` pattern matching
3. **Check script directly**: Run `./get_crossword.sh -n`
4. **Verify dependencies**: Ensure curl, jq are installed

### Configuration Issues
1. **Backup restored**: Original config.sh is automatically restored
2. **Permission errors**: Ensure test scripts are executable
3. **Path issues**: Run tests from script directory

### Common Issues
- **"Command not found"**: Make scripts executable with `chmod +x`
- **"Unbound variable"**: Check bash version and script compatibility
- **Test hangs**: Some tests may require network access (mocked in test suite)

## Files

- 📋 **test_suite.sh** - Comprehensive test framework (25+ tests)
- ⚡ **quick_test.sh** - Fast essential tests (8 tests, ~3 seconds)
- 📚 **TEST_README.md** - This documentation

## Contributing

When adding new features to `get_crossword.sh`:

1. ✅ Add corresponding tests to `test_suite.sh`
2. ✅ Update `quick_test.sh` if core functionality changes
3. ✅ Run full test suite before submitting changes
4. ✅ Document new test functions in this README

---

**Status**: ✅ All tests passing  
**Coverage**: Core functionality, configuration, error handling, formats  
**Last Updated**: Configuration Management improvements (#5)