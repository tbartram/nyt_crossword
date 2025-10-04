#!/usr/bin/env bash
# Configuration file for get_crossword.sh

# Path to cookies file (Netscape format)
COOKIES="./cookies/www.nytimes.com_cookies.txt"

# Default printer name
# Find your printer name with the command: lpstat -p
#PRINTER="Brother_HL_L2370DW_series"

# Default lpr options (as a space-separated string)
LPR_OPTS="-o media=Letter -o fit-to-page"

# Temporary directory (uses system default if not set)
TMPDIR="${TMPDIR:-/tmp}"