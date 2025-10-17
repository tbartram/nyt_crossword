#!/usr/bin/env bash
# Configuration file for get_crossword.sh
#
# This file contains all user-configurable settings for the crossword script.
# Copy this file and modify the settings below to customize the behavior.
#
# IMPORTANT: Uncomment (remove #) from any setting you want to customize!

#=============================================================================
# AUTHENTICATION SETTINGS
#=============================================================================

# Path to cookies file (Netscape format)
# How to get this:
#   1. Log into nytimes.com in your browser
#   2. Use a browser extension to export cookies in Netscape format
#   3. Save to the path below
COOKIES="./cookies/www.nytimes.com_cookies.txt"

#=============================================================================
# PRINTER SETTINGS
#=============================================================================

# Default printer name (uncomment and set to enable printing without -p flag)
# Find available printers: lpstat -p -d
# Examples:
#   PRINTER="Brother_HL_L2370DW_series"
#   PRINTER="HP_LaserJet_Pro_M404n"
#   PRINTER="Canon_PIXMA_TS3300_series"
#PRINTER=""

# Default lpr printing options (space-separated string)
# Common options:
#   -o media=Letter          # Paper size (Letter, A4, Legal)
#   -o fit-to-page           # Scale to fit page
#   -o number-up=2           # Print 2 pages per sheet
#   -o sides=two-sided-long-edge  # Duplex printing
#   -o orientation-requested=3    # Landscape mode
LPR_OPTS="-o media=Letter -o fit-to-page"

#=============================================================================
# FILE SYSTEM SETTINGS
#=============================================================================

# Temporary directory for downloaded files
# Uses system default if not set
TMPDIR="${TMPDIR:-/tmp}"

# Default save directory for -s option (if not specified, uses current directory)
# Example: SAVE_DIR="$HOME/Downloads/crosswords"
#SAVE_DIR=""

# Default filename pattern for saved files
# Available variables: {puzzle_id}, {date}, {timestamp}
# Examples:
#   "nyt-crossword-{puzzle_id}.pdf"           # Default
#   "crossword-{date}.pdf"                    # Date-based
#   "{date}-nyt-puzzle.pdf"                   # Date prefix
SAVE_FILENAME_PATTERN="nyt-crossword-{puzzle_id}.pdf"

#=============================================================================
# RANDOM PUZZLE SETTINGS
#=============================================================================

# Probability weights for random puzzle selection (must sum to 100)
# Higher values = more likely to be selected
RANDOM_HISTORICAL_WEIGHT=5    # 1942-1969 era
RANDOM_MODERN_WEIGHT=95       # 1994-present era

# Buffer days around random date for API calls (improves puzzle availability)
# Larger values = more puzzles found but wider date range
RANDOM_DATE_BUFFER_DAYS=90

#=============================================================================
# API SETTINGS
#=============================================================================

# Maximum number of puzzles to fetch from NYT API in one call
# Higher values = better random selection but slower API calls
PUZZLE_LIST_LIMIT=100

# Request timeout in seconds for API calls
REQUEST_TIMEOUT=30

# Number of retry attempts for failed API calls
MAX_RETRIES=3

#=============================================================================
# DEFAULT BEHAVIOR SETTINGS
#=============================================================================

# Default puzzle selection mode when no options given
# Options: "recent" (most recent), "random" (random puzzle)
DEFAULT_MODE="recent"

# Default puzzle format options (true/false)
# These can be overridden by command-line flags
DEFAULT_LARGE_PRINT=false
DEFAULT_LEFT_HANDED=false
DEFAULT_INK_SAVER=false
DEFAULT_SOLUTION=false

# Default action when no printer specified and not using -s or -n
# Options: "error" (show error), "save" (save to file), "prompt" (ask user)
NO_PRINTER_ACTION="error"

#=============================================================================
# OUTPUT SETTINGS
#=============================================================================

# Verbosity level for output messages
# 0=quiet (errors only), 1=normal, 2=verbose, 3=debug
VERBOSITY=1

# Whether to show progress indicators for downloads
SHOW_PROGRESS=true

# Whether to keep temporary files for debugging (they'll be in TMPDIR)
KEEP_TEMP_FILES=false

#=============================================================================
# VALIDATION SETTINGS
#=============================================================================

# Whether to validate downloaded PDFs (checks file format)
VALIDATE_DOWNLOADS=true

# Whether to check printer availability before attempting to print
CHECK_PRINTER_STATUS=true

# Whether to validate date ranges for random puzzle selection
VALIDATE_DATE_RANGES=true

# Default mode to use when no selection is specified
DEFAULT_MODE=recent
