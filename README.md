# 🧩 NYT Crossword Downloader

A robust, feature-rich command-line tool for downloading and printing New York Times crossword puzzles with extensive customization options and enterprise-grade configuration management.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Tested](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)](#testing)

## ✨ Features

### 📅 **Flexible Puzzle Selection**
- **Recent puzzles** - Get today's or recent puzzles by offset
- **Specific dates** - Download any puzzle from the NYT archive 
- **Random selection** - Weighted random from historical (1942-1969) or modern (1994-present) eras
- **Smart fallback** - Automatic retry with expanded date ranges

### 🎨 **Format Options**
- **Large print** - Bigger text for easier reading
- **Left-handed (Southpaw)** - Optimized layout for left-handed solvers
- **Ink saver** - Reduced opacity to save printer ink
- **Solution mode** - Download puzzles with answers shown
- **Combine formats** - Mix and match any options

### ⚙️ **Advanced Configuration**
- **Comprehensive config file** - 80+ customizable settings
- **Environment overrides** - Set any option via environment variables
- **Default behaviors** - Configure preferred modes and formats
- **Validation** - Built-in validation for all settings
- **Three-tier priority** - Built-in defaults → Config file → Environment variables

### 🖨️ **Printing & Output**
- **Direct printing** - Send to any CUPS printer
- **Save to file** - Custom filename patterns with variables
- **Flexible printer handling** - Error, save, or prompt when no printer set
- **Progress indicators** - Visual feedback for downloads
- **Configurable verbosity** - Control output detail level

### 🛡️ **Reliability & Quality**
- **Comprehensive error handling** - Clear error messages and exit codes
- **Retry logic** - Configurable attempts for failed downloads
- **Input validation** - Date format and range checking
- **Test suite** - 25+ automated tests ensuring quality
- **Modular design** - Clean, maintainable code architecture

## 🚀 Quick Start

### Prerequisites
```bash
# Required dependencies
sudo apt-get install curl jq           # Ubuntu/Debian
brew install curl jq                   # macOS

# For printing (optional)
sudo apt-get install cups-client       # Ubuntu/Debian  
# CUPS is pre-installed on macOS
```

### Setup
1. **Clone the repository**
   ```bash
   git clone https://github.com/tbartram/nyt_crossword.git
   cd nyt_crossword
   ```

2. **Export NYT cookies**
   - Log into [nytimes.com](https://www.nytimes.com) in your browser
   - Use a browser extension to export cookies in Netscape format
   - Save as `cookies/www.nytimes.com_cookies.txt`

3. **Configure (optional)**
   ```bash
   # Edit config.sh to customize behavior
   vim config.sh
   ```

4. **Test installation**
   ```bash
   ./quick_test.sh
   ```

### Basic Usage
```bash
# Download and print today's puzzle
./get_crossword.sh

# Save today's puzzle to file
./get_crossword.sh -s

# Get yesterday's puzzle in large print
./get_crossword.sh -o 1 -l

# Download puzzle for specific date
./get_crossword.sh -d 2024-10-15

# Get random puzzle with ink saver
./get_crossword.sh -r -i

# Show what would be downloaded (dry run)
./get_crossword.sh -n
```

## 📖 Documentation

### Command Line Options
```
Usage: get_crossword.sh [OPTIONS]

SELECTION:
  -o OFFSET        Puzzle by index (0=today, 1=yesterday, etc.)
  -d DATE          Specific date (YYYY-MM-DD format)
  -r               Random puzzle from archive

OUTPUT:
  -p PRINTER       Printer name for direct printing
  -s               Save to file instead of printing
  -n               Dry run (show commands without executing)

FORMAT:
  -l               Large print version
  -L               Left-handed (southpaw) layout
  -i               Ink saver (reduced opacity)
  -S               Solution (with answers)

OTHER:
  -c COOKIE_FILE   Path to cookies.txt file
  -h               Show help
```

### Examples
```bash
# Print most recent puzzle on default printer
./get_crossword.sh -p "HP_LaserJet"

# Save large print version of specific date
./get_crossword.sh -d 2024-01-15 -l -s

# Random historical puzzle with multiple formats
./get_crossword.sh -r -l -L -i

# Use custom cookie file and save with verbose output
VERBOSITY=2 ./get_crossword.sh -c ~/my_cookies.txt -s

# Set random mode as default via environment
DEFAULT_MODE=random ./get_crossword.sh
```

## ⚙️ Configuration

The script uses a comprehensive configuration system with 80+ customizable settings:

### Quick Configuration
```bash
# Set defaults in config.sh
PRINTER="HP_LaserJet_Pro"           # Default printer
DEFAULT_LARGE_PRINT=true            # Always use large print
DEFAULT_MODE=random                 # Use random puzzles by default
VERBOSITY=2                         # More detailed output
```

### Environment Variables
Any configuration can be overridden via environment variables:
```bash
# Temporary overrides
DEFAULT_LARGE_PRINT=true PRINTER="Brother_Printer" ./get_crossword.sh

# Persistent environment settings
export VERBOSITY=2
export DEFAULT_MODE=random
```

### Configuration Categories
- **🔐 Authentication** - Cookie file paths and validation
- **🖨️ Printer Settings** - Default printers and options
- **📁 File System** - Save directories and filename patterns  
- **🎲 Random Selection** - Era weights and date buffers
- **🌐 API Settings** - Timeouts, retries, and limits
- **📤 Output** - Verbosity levels and progress indicators
- **✅ Validation** - Enable/disable various checks

See [`config.sh`](config.sh) for complete documentation of all options.

## 🧪 Testing

The project includes comprehensive testing infrastructure:

### Quick Tests (Recommended)
```bash
# Run essential tests (~3 seconds)
./quick_test.sh
```

### Full Test Suite
```bash
# Run comprehensive tests (25+ tests)
./test_suite.sh

# Run with detailed output
./test_suite.sh --verbose

# Test specific functionality
./test_suite.sh -p "config"
./test_suite.sh -p "error"
```

### Test Coverage
- ✅ **Basic functionality** - Core operations and modes
- ✅ **Configuration management** - File loading and overrides  
- ✅ **Format options** - All PDF format combinations
- ✅ **Error handling** - Invalid inputs and edge cases
- ✅ **Integration** - End-to-end workflows
- ✅ **Validation** - Input checking and configuration validation

See [TEST_README.md](TEST_README.md) for detailed testing documentation.

## 📱 Siri Shortcuts

The repository includes iOS Shortcuts for convenient voice-activated access to your crossword collection. Each shortcut connects to your server via SSH and executes the crossword script remotely.

### Available Shortcuts

- **📋 Print Today's Crossword** - *"Hey Siri, print today's crossword"*
- **📋 Print Yesterday's Crossword** - *"Hey Siri, print yesterday's crossword"*  
- **📋 Print Tomorrow's Crossword** - *"Hey Siri, print tomorrow's crossword"*
- **🎲 Print Random Crossword** - *"Hey Siri, print a random crossword"*
- **📅 Print Specific Crossword** - *"Hey Siri, print a specific crossword"*

### Quick Setup
1. **Transfer shortcuts** to your iOS device from the `siri_shortcuts/` directory
2. **Import each shortcut** - tap "Add Shortcut" when prompted
3. **Configure during import**:
   - **Remote Host**: Your server's IP or hostname
   - **Username**: SSH username for the server  
   - **Default Command**: Base command (e.g., `cd ~/nyt_crossword && ./get_crossword.sh`)
4. **Test manually** before using voice commands
5. **Enable Siri phrases** for hands-free operation

### Smart Features
- **⏰ Smart timing** - Tomorrow's crossword only works after release times (10PM Sun-Fri, 6PM Sat)
- **🔒 Secure SSH** - Encrypted connection to your server
- **⚙️ Flexible commands** - Customize with any script options (-l, -L, -i, -s, etc.)
- **🎙️ Voice activation** - Complete hands-free operation via Siri

**📚 Full documentation**: See [siri_shortcuts/README.md](siri_shortcuts/README.md) for complete setup instructions, troubleshooting, and customization options.

## 🏗️ Architecture

### Design Principles
- **🎯 Modular Functions** - Each function has a single responsibility
- **⚙️ Configuration-Driven** - Behavior controlled via config files
- **🛡️ Robust Error Handling** - Comprehensive validation and clear error messages
- **🔄 Utility Functions** - Reusable patterns for common operations
- **📝 Consistent Logging** - Configurable verbosity levels

### Code Quality Features
- **📋 No magic numbers** - All constants clearly defined
- **🔧 Function extraction** - Complex logic broken into focused functions
- **♻️ DRY principle** - Common patterns abstracted into utilities
- **✅ Input validation** - All user inputs validated
- **🧪 Test coverage** - Comprehensive automated testing

### Key Components
```
get_crossword.sh          # Main script
├── Configuration Loading  # Multi-tier config management
├── Utility Functions     # Common patterns (error handling, JSON parsing)
├── Core Functions        # Puzzle selection, URL building, validation
├── Main Logic           # Command parsing and workflow orchestration
└── Output Handling      # Printing, saving, progress reporting

config.sh                # Configuration file with 80+ settings
test_suite.sh            # Comprehensive test framework  
quick_test.sh            # Fast essential tests
```

## 🤝 Contributing

### Development Workflow
1. **Make changes** to the script
2. **Run quick tests** - `./quick_test.sh`
3. **Run full tests** - `./test_suite.sh`
4. **Add tests** for new functionality
5. **Update documentation** as needed

### Adding Features
1. Add configuration options to `config.sh`
2. Implement functionality in `get_crossword.sh`
3. Add corresponding tests to `test_suite.sh`
4. Update documentation

### Code Standards
- Follow existing function naming conventions
- Add comprehensive error handling
- Include configuration options for new features
- Write tests for new functionality
- Update help text and documentation

## 📋 Requirements

### System Requirements
- **Bash 4.0+** - Modern bash shell
- **curl** - For API calls and downloads
- **jq** - For JSON parsing
- **CUPS** - For printing (optional)

### NYT Subscription
- Active New York Times subscription
- Access to crossword puzzles
- Valid authentication cookies

### Supported Platforms
- ✅ **macOS** - Fully tested and supported
- ✅ **Linux** - Ubuntu, Debian, CentOS, etc.
- ✅ **WSL** - Windows Subsystem for Linux
- ⚠️ **Windows** - Requires WSL or Git Bash

## 🐛 Troubleshooting

### Common Issues

**"Command not found" errors**
```bash
# Make script executable
chmod +x get_crossword.sh quick_test.sh test_suite.sh
```

**"Cookie file not found"**
```bash
# Check cookie file path and format
ls -la cookies/
# Re-export cookies from browser
```

**"No puzzles found"**
```bash
# Check date range and subscription status
./get_crossword.sh -d 2024-01-01 -n  # Test with known date
```

**Printer not working**
```bash
# List available printers
lpstat -p -d

# Test printing
echo "test" | lpr -P "YourPrinterName"

# Use save mode instead
./get_crossword.sh -s
```

### Debug Mode
```bash
# Enable verbose output
VERBOSITY=3 ./get_crossword.sh -n

# Run with debug information
./test_suite.sh --verbose
```

### Getting Help
1. Check the [troubleshooting section](#troubleshooting)
2. Run tests to identify issues: `./quick_test.sh`
3. Enable verbose output: `VERBOSITY=2 ./get_crossword.sh`
4. Open an [issue](https://github.com/tbartram/nyt_crossword/issues) with:
   - Command you ran
   - Expected vs actual output
   - System information (OS, bash version)

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **New York Times** - For providing the crossword puzzles and API
- **curl & jq communities** - For excellent command-line tools
- **CUPS project** - For universal printing support

---

**⭐ Star this repo if you find it useful!**

Made with ❤️ for crossword enthusiasts who love the command line.