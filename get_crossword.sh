#!/usr/bin/env bash
set -uo pipefail

# Basic utility functions (needed for config loading)
error_exit() {
  local message="$1"
  local exit_code="${2:-1}"
  echo "ERROR: $message" >&2
  exit "$exit_code"
}

# Configuration loading and validation
load_and_validate_config() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local config_file="${script_dir}/config.sh"
  
  # Save environment variables if they exist
  local env_cookies="${COOKIES:-}"
  local env_lpr_opts="${LPR_OPTS:-}"
  local env_tmpdir="${TMPDIR:-}"
  local env_save_filename_pattern="${SAVE_FILENAME_PATTERN:-}"
  local env_random_historical_weight="${RANDOM_HISTORICAL_WEIGHT:-}"
  local env_random_modern_weight="${RANDOM_MODERN_WEIGHT:-}"
  local env_random_date_buffer_days="${RANDOM_DATE_BUFFER_DAYS:-}"
  local env_puzzle_list_limit="${PUZZLE_LIST_LIMIT:-}"
  local env_request_timeout="${REQUEST_TIMEOUT:-}"
  local env_max_retries="${MAX_RETRIES:-}"
  local env_default_mode="${DEFAULT_MODE:-}"
  local env_default_large_print="${DEFAULT_LARGE_PRINT:-}"
  local env_default_left_handed="${DEFAULT_LEFT_HANDED:-}"
  local env_default_ink_saver="${DEFAULT_INK_SAVER:-}"
  local env_default_solution="${DEFAULT_SOLUTION:-}"
  local env_no_printer_action="${NO_PRINTER_ACTION:-}"
  local env_verbosity="${VERBOSITY:-}"
  local env_show_progress="${SHOW_PROGRESS:-}"
  local env_keep_temp_files="${KEEP_TEMP_FILES:-}"
  local env_validate_downloads="${VALIDATE_DOWNLOADS:-}"
  local env_check_printer_status="${CHECK_PRINTER_STATUS:-}"
  local env_validate_date_ranges="${VALIDATE_DATE_RANGES:-}"
  
  # Set built-in defaults first
  COOKIES="./cookies/www.nytimes.com_cookies.txt"
  LPR_OPTS="-o media=Letter -o fit-to-page"
  TMPDIR="/tmp"
  SAVE_FILENAME_PATTERN="nyt-crossword-{puzzle_id}.pdf"
  RANDOM_HISTORICAL_WEIGHT=5
  RANDOM_MODERN_WEIGHT=95
  RANDOM_DATE_BUFFER_DAYS=90
  PUZZLE_LIST_LIMIT=100
  REQUEST_TIMEOUT=30
  MAX_RETRIES=3
  DEFAULT_MODE="recent"
  DEFAULT_LARGE_PRINT=false
  DEFAULT_LEFT_HANDED=false
  DEFAULT_INK_SAVER=false
  DEFAULT_SOLUTION=false
  NO_PRINTER_ACTION="error"
  VERBOSITY=1
  SHOW_PROGRESS=true
  KEEP_TEMP_FILES=false
  VALIDATE_DOWNLOADS=true
  CHECK_PRINTER_STATUS=true
  VALIDATE_DATE_RANGES=true
  
  # Load user config if available (this may override the defaults above)
  if [[ -f "$config_file" ]]; then
    if [[ ${env_verbosity:-$VERBOSITY} -ge 2 ]]; then
      echo "Loading configuration from: $config_file" >&2
    fi
    source "$config_file" || error_exit "Failed to load configuration from $config_file" 14
  else
    if [[ ${env_verbosity:-$VERBOSITY} -ge 1 ]]; then
      echo "WARNING: Config file not found at $config_file, using built-in defaults" >&2
    fi
  fi
  
  # Finally, restore environment variables if they were set
  [[ -n "$env_cookies" ]] && COOKIES="$env_cookies"
  [[ -n "$env_lpr_opts" ]] && LPR_OPTS="$env_lpr_opts"
  [[ -n "$env_tmpdir" ]] && TMPDIR="$env_tmpdir"
  [[ -n "$env_save_filename_pattern" ]] && SAVE_FILENAME_PATTERN="$env_save_filename_pattern"
  [[ -n "$env_random_historical_weight" ]] && RANDOM_HISTORICAL_WEIGHT="$env_random_historical_weight"
  [[ -n "$env_random_modern_weight" ]] && RANDOM_MODERN_WEIGHT="$env_random_modern_weight"
  [[ -n "$env_random_date_buffer_days" ]] && RANDOM_DATE_BUFFER_DAYS="$env_random_date_buffer_days"
  [[ -n "$env_puzzle_list_limit" ]] && PUZZLE_LIST_LIMIT="$env_puzzle_list_limit"
  [[ -n "$env_request_timeout" ]] && REQUEST_TIMEOUT="$env_request_timeout"
  [[ -n "$env_max_retries" ]] && MAX_RETRIES="$env_max_retries"
  [[ -n "$env_default_mode" ]] && DEFAULT_MODE="$env_default_mode"
  [[ -n "$env_default_large_print" ]] && DEFAULT_LARGE_PRINT="$env_default_large_print"
  [[ -n "$env_default_left_handed" ]] && DEFAULT_LEFT_HANDED="$env_default_left_handed"
  [[ -n "$env_default_ink_saver" ]] && DEFAULT_INK_SAVER="$env_default_ink_saver"
  [[ -n "$env_default_solution" ]] && DEFAULT_SOLUTION="$env_default_solution"
  [[ -n "$env_no_printer_action" ]] && NO_PRINTER_ACTION="$env_no_printer_action"
  [[ -n "$env_verbosity" ]] && VERBOSITY="$env_verbosity"
  [[ -n "$env_show_progress" ]] && SHOW_PROGRESS="$env_show_progress"
  [[ -n "$env_keep_temp_files" ]] && KEEP_TEMP_FILES="$env_keep_temp_files"
  [[ -n "$env_validate_downloads" ]] && VALIDATE_DOWNLOADS="$env_validate_downloads"
  [[ -n "$env_check_printer_status" ]] && CHECK_PRINTER_STATUS="$env_check_printer_status"
  [[ -n "$env_validate_date_ranges" ]] && VALIDATE_DATE_RANGES="$env_validate_date_ranges"
  
  # Validate configuration values
  validate_config
}

validate_config() {
  # Validate weight values
  if ! [[ "$RANDOM_HISTORICAL_WEIGHT" =~ ^[0-9]+$ ]] || ! [[ "$RANDOM_MODERN_WEIGHT" =~ ^[0-9]+$ ]]; then
    error_exit "Random weights must be positive integers. Got: historical=$RANDOM_HISTORICAL_WEIGHT, modern=$RANDOM_MODERN_WEIGHT" 15
  fi
  
  local total_weight=$((RANDOM_HISTORICAL_WEIGHT + RANDOM_MODERN_WEIGHT))
  if (( total_weight != 100 )); then
    error_exit "Random weights must sum to 100. Got: $total_weight (historical=$RANDOM_HISTORICAL_WEIGHT + modern=$RANDOM_MODERN_WEIGHT)" 15
  fi
  
  # Validate numeric settings
  for setting in RANDOM_DATE_BUFFER_DAYS PUZZLE_LIST_LIMIT REQUEST_TIMEOUT MAX_RETRIES VERBOSITY; do
    local value="${!setting}"
    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value < 0 )); then
      error_exit "Configuration $setting must be a non-negative integer. Got: $value" 15
    fi
  done
  
  # Validate ranges
  if (( PUZZLE_LIST_LIMIT < 1 || PUZZLE_LIST_LIMIT > 1000 )); then
    error_exit "PUZZLE_LIST_LIMIT must be between 1 and 1000. Got: $PUZZLE_LIST_LIMIT" 15
  fi
  
  if (( REQUEST_TIMEOUT < 1 || REQUEST_TIMEOUT > 300 )); then
    error_exit "REQUEST_TIMEOUT must be between 1 and 300 seconds. Got: $REQUEST_TIMEOUT" 15
  fi
  
  if (( VERBOSITY > 3 )); then
    error_exit "VERBOSITY must be between 0 and 3. Got: $VERBOSITY" 15
  fi
  
  # Validate boolean settings
  for setting in DEFAULT_LARGE_PRINT DEFAULT_LEFT_HANDED DEFAULT_INK_SAVER DEFAULT_SOLUTION SHOW_PROGRESS KEEP_TEMP_FILES VALIDATE_DOWNLOADS CHECK_PRINTER_STATUS VALIDATE_DATE_RANGES; do
    local value="${!setting}"
    if [[ "$value" != "true" && "$value" != "false" ]]; then
      error_exit "Configuration $setting must be 'true' or 'false'. Got: $value" 15
    fi
  done
  
  # Validate enum settings
  case "$DEFAULT_MODE" in
    recent|random) ;;
    *) error_exit "DEFAULT_MODE must be 'recent' or 'random'. Got: $DEFAULT_MODE" 15 ;;
  esac
  
  case "$NO_PRINTER_ACTION" in
    error|save|prompt) ;;
    *) error_exit "NO_PRINTER_ACTION must be 'error', 'save', or 'prompt'. Got: $NO_PRINTER_ACTION" 15 ;;
  esac
  
  # Validate filename pattern
  if [[ "$SAVE_FILENAME_PATTERN" != *"{puzzle_id}"* ]]; then
    error_exit "SAVE_FILENAME_PATTERN must contain {puzzle_id} placeholder. Got: $SAVE_FILENAME_PATTERN" 15
  fi
  
  # Validate directories exist or can be created
  if [[ -n "${SAVE_DIR:-}" ]]; then
    if [[ ! -d "$SAVE_DIR" ]]; then
      if ! mkdir -p "$SAVE_DIR" 2>/dev/null; then
        error_exit "Cannot create SAVE_DIR: $SAVE_DIR" 15
      fi
    fi
  fi
  
  # Validate TMPDIR
  if [[ ! -d "$TMPDIR" ]]; then
    if ! mkdir -p "$TMPDIR" 2>/dev/null; then
      error_exit "Cannot create TMPDIR: $TMPDIR" 15
    fi
  fi
  
  if [[ $VERBOSITY -ge 3 ]]; then
    echo "DEBUG: Configuration validation passed" >&2
  fi
}

# Load configuration early
load_and_validate_config

# Constants (some values come from configuration)
readonly HISTORICAL_ERA_START="1942-02-15"
readonly HISTORICAL_ERA_END="1969-12-31"
readonly MODERN_ERA_START="1994-01-01"
readonly LEAP_YEAR_FEB_DAYS=29
readonly REGULAR_FEB_DAYS=28

# Configuration-derived constants (set after config loading)
readonly HISTORICAL_WEIGHT="$RANDOM_HISTORICAL_WEIGHT"
readonly MODERN_WEIGHT="$RANDOM_MODERN_WEIGHT"

# Convert LPR_OPTS string to array for use with lpr command
IFS=' ' read -ra LPR_OPTS_ARRAY <<< "$LPR_OPTS"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-c cookie_file] [-o OFFSET | -d DATE | -r] [-p printer] [-s] [-n] [-l] [-L] [-i] [-S] [-h]
  -c COOKIE_FILE   Path to cookies.txt (Netscape format). Default: $COOKIES
  -o OFFSET        Which puzzle to fetch by index:
                     0  = most recent (default)
                     1  = second most recent
                     2  = third most recent
                     -1 = same as 1 (accepts negative for convenience)
  -d DATE          Fetch puzzle for specific date (YYYY-MM-DD format)
  -r               Fetch a random puzzle from across different eras (${HISTORICAL_ERA_START%-*}-present)
  -p PRINTER       lpr printer name. Required for printing (unless -s or -n)
  -s               Save PDF to local file instead of printing (prints filename)
  -n               Dry-run: show URL and curl command only, do not download/print
  -l               Large print version
  -L               Left-handed (southpaw) version
  -i               Ink saver version (reduced opacity)
  -S               Solution version (answers shown)
  -h               Show this help

Configuration is loaded from config.sh in the same directory as this script.
Examples:
  $(basename "$0")                      # print most recent puzzle
  $(basename "$0") -o 1                 # print second most recent
  $(basename "$0") -d 2025-10-01        # print puzzle for October 1, 2025
  $(basename "$0") -r                   # print a random puzzle from entire archive
  $(basename "$0") -c /path/cookies.txt -s
EOF
  exit 1
}

# Functions
validate_date() {
  local date="$1"
  
  if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "ERROR: Date must be in YYYY-MM-DD format. Got: '$date'" >&2
    return 1
  fi
  
  # Validate it's a real date using date command (cross-platform)
  # Try GNU date first (Linux), then BSD date (macOS)
  if command -v date >/dev/null 2>&1; then
    if ! (date -d "$date" >/dev/null 2>&1 || date -j -f "%Y-%m-%d" "$date" >/dev/null 2>&1); then
      echo "ERROR: Invalid date: '$date'" >&2
      return 1
    fi
  fi
  
  return 0
}

expand_tilde_path() {
  local path="$1"
  if [[ "$path" == ~* ]]; then
    echo "${path/#\~/$HOME}"
  else
    echo "$path"
  fi
}

select_random_era() {
  local weight_choice=$((RANDOM % 100))
  
  if [[ $weight_choice -lt $MODERN_WEIGHT ]]; then
    # Modern era - higher probability
    echo "$MODERN_ERA_START" "$(date +%Y-%m-%d)" "modern (${MODERN_ERA_START%-*}-present)"
  else
    # Historical era - lower probability  
    echo "$HISTORICAL_ERA_START" "$HISTORICAL_ERA_END" "historical (${HISTORICAL_ERA_START%-*}-${HISTORICAL_ERA_END%-*})"
  fi
}

generate_random_date_in_era() {
  local era_start="$1"
  local era_end="$2"
  
  if [[ "$era_start" == "$HISTORICAL_ERA_START" ]]; then
    # Historical era has very few puzzles, so use the full date range
    echo "$era_start" "$era_end" "$era_start"
    return
  fi
  
  # For all other eras: pick a random year, then a random date within that year
  local era_start_year=$(echo "$era_start" | cut -d- -f1)
  local era_end_year=$(echo "$era_end" | cut -d- -f1)
  local year_range=$((era_end_year - era_start_year + 1))
  local random_year=$((era_start_year + RANDOM % year_range))
  
  # Pick a random month and day
  local random_month=$((1 + RANDOM % 12))
  
  # Calculate the correct number of days for the selected month and year
  local days_in_month
  case $random_month in
    1|3|5|7|8|10|12) days_in_month=31 ;;  # Jan, Mar, May, Jul, Aug, Oct, Dec
    4|6|9|11) days_in_month=30 ;;         # Apr, Jun, Sep, Nov
    2)
      # February - check for leap year
      if (( (random_year % 4 == 0 && random_year % 100 != 0) || random_year % 400 == 0 )); then
        days_in_month=$LEAP_YEAR_FEB_DAYS  # Leap year
      else
        days_in_month=$REGULAR_FEB_DAYS    # Regular year
      fi
      ;;
  esac
  
  local random_day=$((1 + RANDOM % days_in_month))
  
  # Format the random date
  local random_date=$(printf "%04d-%02d-%02d" $random_year $random_month $random_day)
  
  # Create a buffer around the random date (configurable days to get more puzzles in API call)
  local buffer_start buffer_end
  if command -v date >/dev/null 2>&1; then
    if date -d "$random_date" >/dev/null 2>&1; then
      # GNU date (Linux)
      buffer_start=$(date -d "$random_date - $RANDOM_DATE_BUFFER_DAYS days" +%Y-%m-%d 2>/dev/null || echo "$era_start")
      buffer_end=$(date -d "$random_date + $RANDOM_DATE_BUFFER_DAYS days" +%Y-%m-%d 2>/dev/null || echo "$era_end")
    elif date -j -f "%Y-%m-%d" "$random_date" >/dev/null 2>&1; then
      # BSD date (macOS)  
      buffer_start=$(date -j -v-${RANDOM_DATE_BUFFER_DAYS}d -f "%Y-%m-%d" "$random_date" +%Y-%m-%d 2>/dev/null || echo "$era_start")
      buffer_end=$(date -j -v+${RANDOM_DATE_BUFFER_DAYS}d -f "%Y-%m-%d" "$random_date" +%Y-%m-%d 2>/dev/null || echo "$era_end")
    else
      buffer_start="$era_start"
      buffer_end="$era_end"
    fi
  else
    buffer_start="$era_start"
    buffer_end="$era_end"
  fi
  
  echo "$buffer_start" "$buffer_end" "$random_date"
}

build_puzzle_list_url() {
  local start_date="$1"
  local end_date="$2"
  
  echo "https://www.nytimes.com/svc/crosswords/v3/289669378/puzzles.json?sort_order=desc&sort_by=print_date&date_start=${start_date}&date_end=${end_date}&limit=${PUZZLE_LIST_LIMIT}"
}

fetch_puzzle_list() {
  local url="$1"
  local cookie_file="$2"
  
  curl --fail -sS -b "$cookie_file" -L "$url" || error_exit "Failed to fetch puzzle list. Check network, cookie freshness, and that you are authenticated." 5
}

build_pdf_url() {
  local puzzle_id="$1"
  local large_print="$2"
  local left_handed="$3"
  local ink_saver="$4"
  local solution="$5"
  
  local base_url="https://www.nytimes.com/svc/crosswords/v2/puzzle/${puzzle_id}"
  local file_suffix=""
  local url_params=""
  
  # Handle solution special case
  if [[ "$solution" == true ]]; then
    file_suffix=".ans"
    base_url="${base_url}.ans.pdf"
    # only ink saver applies to solution
    if [[ "$ink_saver" == true ]]; then
      url_params="block_opacity=30"
    fi
  else
    base_url="${base_url}.pdf"
    # Build URL parameters for regular puzzles
    if [[ "$large_print" == true ]]; then
      url_params="large_print=true"
    fi
    if [[ "$left_handed" == true ]]; then
      if [[ -n "$url_params" ]]; then
        url_params="${url_params}&southpaw=true"
      else
        url_params="southpaw=true"
      fi
    fi
    if [[ "$ink_saver" == true ]]; then
      if [[ -n "$url_params" ]]; then
        url_params="${url_params}&block_opacity=30"
      else
        url_params="block_opacity=30"
      fi
    fi
  fi
  
  # Append URL parameters if any
  if [[ -n "$url_params" ]]; then
    base_url="${base_url}?${url_params}"
  fi
  
  echo "$base_url" "$file_suffix"
}

# Additional utility functions
parse_json() {
  local json_data="$1"
  shift  # Remove first argument, rest are jq arguments
  printf '%s' "$json_data" | jq -r "$@"
}

download_with_auth() {
  local url="$1"
  local cookie_file="$2"
  local output_file="$3"
  local error_message="$4"
  
  # Build curl command with timeout and retry logic
  local curl_cmd="curl --fail -sS -b \"$cookie_file\" -L --max-time $REQUEST_TIMEOUT"
  
  if [[ "$SHOW_PROGRESS" == "true" && $VERBOSITY -ge 1 ]]; then
    curl_cmd="$curl_cmd --progress-bar"
  fi
  
  local attempt=1
  while (( attempt <= MAX_RETRIES )); do
    if [[ $VERBOSITY -ge 2 ]]; then
      echo "Download attempt $attempt of $MAX_RETRIES..." >&2
    fi
    
    if [[ -n "$output_file" ]]; then
      if eval "$curl_cmd \"$url\" -o \"$output_file\""; then
        return 0
      fi
    else
      if eval "$curl_cmd \"$url\""; then
        return 0
      fi
    fi
    
    if (( attempt < MAX_RETRIES )); then
      if [[ $VERBOSITY -ge 1 ]]; then
        echo "Download failed, retrying in 2 seconds..." >&2
      fi
      sleep 2
    fi
    ((attempt++))
  done
  
  error_exit "$error_message (after $MAX_RETRIES attempts)" 7
}

require_command() {
  local cmd="$1"
  local error_message="${2:-required command '$cmd' not found. Install it and try again.}"
  local exit_code="${3:-2}"
  
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error_exit "$error_message" "$exit_code"
  fi
}

validate_file_exists() {
  local file="$1"
  local error_message="${2:-file not found: $file}"
  local exit_code="${3:-4}"
  
  if [[ ! -f "$file" ]]; then
    error_exit "$error_message" "$exit_code"
  fi
}

# Configuration-aware utility functions
log_message() {
  local level="$1"
  local message="$2"
  
  if (( level <= VERBOSITY )); then
    case "$level" in
      0) echo "ERROR: $message" >&2 ;;
      1) echo "$message" ;;
      2) echo "INFO: $message" >&2 ;;
      3) echo "DEBUG: $message" >&2 ;;
    esac
  fi
}

validate_printer() {
  local printer_name="$1"
  
  if [[ "$CHECK_PRINTER_STATUS" != "true" ]]; then
    return 0
  fi
  
  if ! command -v lpstat >/dev/null 2>&1; then
    log_message 2 "lpstat not available, skipping printer validation"
    return 0
  fi
  
  if ! lpstat -p "$printer_name" >/dev/null 2>&1; then
    error_exit "Printer '$printer_name' not found or not available. Check with: lpstat -p" 16
  fi
  
  log_message 2 "Printer '$printer_name' is available"
}

format_filename() {
  local pattern="$1"
  local puzzle_id="$2"
  local puzzle_date="$3"
  local timestamp="$4"
  
  local filename="$pattern"
  filename="${filename//\{puzzle_id\}/$puzzle_id}"
  filename="${filename//\{date\}/$puzzle_date}"
  filename="${filename//\{timestamp\}/$timestamp}"
  
  echo "$filename"
}

get_save_path() {
  local filename="$1"
  
  if [[ -n "${SAVE_DIR:-}" ]]; then
    echo "${SAVE_DIR%/}/$filename"
  else
    echo "$filename"
  fi
}

handle_no_printer_action() {
  case "$NO_PRINTER_ACTION" in
    error)
      error_exit "No printer specified. Use -p PRINTER, set PRINTER in config.sh, or use -s to save to file or -n for dry-run." 11
      ;;
    save)
      log_message 1 "No printer specified, saving to file instead"
      save_only=true
      ;;
    prompt)
      echo "No printer specified. What would you like to do?"
      echo "1) Save to file"
      echo "2) Specify printer name"
      echo "3) Cancel"
      read -p "Choice (1-3): " choice
      case "$choice" in
        1) save_only=true ;;
        2) 
          read -p "Enter printer name: " PRINTER
          if [[ -z "$PRINTER" ]]; then
            error_exit "No printer name provided" 11
          fi
          ;;
        3|*) error_exit "Operation cancelled" 0 ;;
      esac
      ;;
  esac
}

# Initialize defaults from configuration (convert string booleans to script booleans)
cookie_file="$COOKIES"
offset=0
target_date=""
random_puzzle=false
save_only=false
dry_run=false
large_print=false
left_handed=false
ink_saver=false
solution=false

# Convert configuration string booleans to script booleans
if [[ "$DEFAULT_LARGE_PRINT" == "true" ]]; then large_print=true; fi
if [[ "$DEFAULT_LEFT_HANDED" == "true" ]]; then left_handed=true; fi  
if [[ "$DEFAULT_INK_SAVER" == "true" ]]; then ink_saver=true; fi
if [[ "$DEFAULT_SOLUTION" == "true" ]]; then solution=true; fi

# parse options
while getopts ":c:o:d:rp:snlLiSh" opt; do
  case "$opt" in
    c) cookie_file="$OPTARG" ;;
    o) offset="$OPTARG" ;;
    d) target_date="$OPTARG" ;;
    r) random_puzzle=true ;;
    p) PRINTER="$OPTARG" ;;
    s) save_only=true ;;
    n) dry_run=true ;;
    l) large_print=true ;;
    L) left_handed=true ;;
    i) ink_saver=true ;;
    S) solution=true ;;
    h) usage ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage ;;
    :) echo "Missing argument for -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# Validate that selection options are mutually exclusive
selection_count=0
[[ -n "$target_date" ]] && ((selection_count++))
[[ "$offset" != "0" ]] && ((selection_count++))
[[ "$random_puzzle" == true ]] && ((selection_count++))

if (( selection_count > 1 )); then
  error_exit "Cannot use multiple selection options (-o, -d, -r) together." 12
fi

# Apply default mode if no explicit selection was specified
if (( selection_count == 0 && offset == 0 )); then
  case "$DEFAULT_MODE" in
    random)
      random_puzzle=true
      log_message 2 "Using default random mode"
      ;;
    recent)
      # offset=0 is already the default, no change needed
      log_message 2 "Using default recent mode"
      ;;
  esac
fi

# Validate date format if provided
if [[ -n "$target_date" ]]; then
  if ! validate_date "$target_date"; then
    exit 13
  fi
fi

# Expand ~ in cookie path if present
cookie_file="$(expand_tilde_path "$cookie_file")"

# Validate printer is set if we need to print
if ! $save_only && ! $dry_run; then
  if [[ -z "${PRINTER:-}" ]]; then
    handle_no_printer_action
  else
    validate_printer "$PRINTER"
  fi
fi

# validate dependencies
for cmd in curl jq; do
  if [[ "$cmd" == "jq" ]]; then
    require_command "$cmd" "required command '$cmd' not found. Install it and try again.
  On Ubuntu/Debian: sudo apt-get install jq
  On macOS with Homebrew: brew install jq"
  else
    require_command "$cmd"
  fi
done

# lpr is required for printing; if save_only or dry_run we can skip it
if ! $save_only && ! $dry_run; then
  require_command "lpr" "'lpr' not found. Install/CUPS or use -s to save to file instead."
fi

# normalize offset: allow negative for convenience
# Our mapping: 0 => results[0] (most recent), 1 => results[1] (second most recent), etc.
if [[ -z "$target_date" && "$random_puzzle" == false ]]; then
  if ! [[ "$offset" =~ ^-?[0-9]+$ ]]; then
    error_exit "offset must be an integer. Got: '$offset'" 3
  fi
  if (( offset < 0 )); then
    index=$(( -offset ))
  else
    index=$offset
  fi
fi

# Ensure cookie file exists
validate_file_exists "$cookie_file" "cookie file not found: $cookie_file
Make sure you've exported cookies for https://www.nytimes.com (Netscape cookies.txt format)."

# build URL to list puzzles based on selection mode
if [[ "$random_puzzle" == true ]]; then
  # Select random era and generate date
  read -r era_start era_end era_desc <<< "$(select_random_era)"
  read -r buffer_start buffer_end random_date <<< "$(generate_random_date_in_era "$era_start" "$era_end")"
  
  LIST_URL="$(build_puzzle_list_url "$buffer_start" "$buffer_end")"
  log_message 1 "Fetching puzzle list for random selection from $era_desc era (around $random_date)..."
else
  # For offset or date-based selection
  if [[ -n "$target_date" ]]; then
    # For specific date requests, use date range API to access historical puzzles
    LIST_URL="$(build_puzzle_list_url "$target_date" "$target_date")"
    log_message 1 "Fetching puzzle list to find puzzle for date: $target_date..."
  else
    # For offset-based selection, use the standard URL (recent puzzles only)
    LIST_URL="https://www.nytimes.com/svc/crosswords/v3/289669378/puzzles.json?publish_type=daily&sort_order=desc&sort_by=print_date"
    log_message 1 "Fetching puzzle list (index: $index) from NYT..."
  fi
fi

# fetch list, fail on HTTP errors (--fail), be quiet but show errors (-sS), follow redirects (-L)
# we pass cookies via -b cookie_file (curl will read Netscape format)
list_json="$(fetch_puzzle_list "$LIST_URL" "$cookie_file")"

# extract puzzle id based on selection mode
if [[ "$random_puzzle" == true ]]; then
  # First check if results is null (no puzzles for the selected era)
  results_check="$(parse_json "$list_json" '.results // "null"')"
  if [[ "$results_check" == "null" ]]; then
    echo "No puzzles found around $random_date, falling back to full era range..." >&2
    # Fall back to full era range
    LIST_URL="$(build_puzzle_list_url "$era_start" "$era_end")"
    list_json="$(fetch_puzzle_list "$LIST_URL" "$cookie_file")"
    results_check="$(parse_json "$list_json" '.results // "null"')"
    if [[ "$results_check" == "null" ]]; then
      error_exit "No puzzles found in the $era_desc era at all. This is unexpected - please try again." 6
    fi
  fi
  
  # Get total number of puzzles available
  puzzle_count="$(parse_json "$list_json" '.results | length')"
  
  if [[ "$puzzle_count" == "0" ]]; then
    error_exit "No puzzles found for random selection in the $era_desc era." 6
  fi
  
  # Generate random index (0-based)
  random_index=$((RANDOM % puzzle_count))
  puzzid="$(parse_json "$list_json" --argjson idx "$random_index" '.results[$idx].puzzle_id // empty')"
  puzzle_date="$(parse_json "$list_json" --argjson idx "$random_index" '.results[$idx].print_date // empty')"
  
  log_message 1 "Selected random puzzle from $puzzle_date (puzzle $((random_index + 1)) of $puzzle_count available)"
  
elif [[ -n "$target_date" ]]; then
  # Find puzzle by date
  # First check if results is null (no puzzles for that date)
  results_check="$(parse_json "$list_json" '.results // "null"')"
  if [[ "$results_check" == "null" ]]; then
    error_exit "No puzzle found for date $target_date. This date may not have had a published puzzle." 6
  fi
  
  puzzid="$(parse_json "$list_json" --arg date "$target_date" '.results[] | select(.print_date == $date) | .puzzle_id // empty' | head -1)"
  
  if [[ -z "$puzzid" || "$puzzid" == "null" ]]; then
    echo "ERROR: Could not find puzzle for date $target_date. Available dates (first 10):" >&2
    parse_json "$list_json" '.results[0:10] | .[] | .print_date' 2>/dev/null || true
    exit 6
  fi
else
  # Find puzzle by index
  puzzid="$(parse_json "$list_json" --argjson idx "$index" '.results[$idx].puzzle_id // empty')"
  
  if [[ -z "$puzzid" || "$puzzid" == "null" ]]; then
    echo "ERROR: Could not find puzzle id at index $index. The puzzle list may be shorter than requested or your cookies may not grant access." >&2
    # optionally print some debugging info (first few results)
    echo "First few puzzle ids (for debugging):"
    parse_json "$list_json" '.results[0:5] | .[]?.puzzle_id' 2>/dev/null || true
    exit 6
  fi
fi

# build PDF url
read -r pdf_url file_suffix <<< "$(build_pdf_url "$puzzid" "$large_print" "$left_handed" "$ink_saver" "$solution")"

# prepare temporary filename
timestamp=$(date +%Y%m%dT%H%M%S)
tmp_pdf="${TMPDIR%/}/nyt-puzzle-${puzzid}${file_suffix}-${timestamp}.pdf"

log_message 2 "Puzzle id: $puzzid"
log_message 2 "PDF URL: $pdf_url"

if $dry_run; then
  echo "Dry-run: would run:"
  echo "  curl -L -b \"$cookie_file\" \"$pdf_url\" -o \"$tmp_pdf\""
  exit 0
fi

log_message 1 "Downloading PDF..."
# download with curl, fail on HTTP error, follow redirects
download_with_auth "$pdf_url" "$cookie_file" "$tmp_pdf" "Failed to download PDF. Possible causes: expired cookies, access denied, or URL changed."

# Validate PDF if enabled in configuration
if [[ "$VALIDATE_DOWNLOADS" == "true" ]]; then
  if [[ ! -s "$tmp_pdf" ]]; then
    error_exit "Downloaded PDF is empty." 8
  fi
  if ! head -c 4 "$tmp_pdf" | grep -q '%PDF'; then
    log_message 0 "Downloaded file does not appear to be a PDF (first bytes do not start with %PDF)."
    if [[ "$KEEP_TEMP_FILES" == "true" ]]; then
      log_message 1 "File saved at: $tmp_pdf for inspection."
    fi
    exit 9
  fi
  log_message 2 "PDF validation passed"
fi

if $save_only; then
  # Get puzzle date for filename formatting
  puzzle_date=""
  if [[ "$random_puzzle" == true ]]; then
    puzzle_date="$(parse_json "$list_json" --argjson idx "$random_index" '.results[$idx].print_date // empty')"
  elif [[ -n "$target_date" ]]; then
    puzzle_date="$target_date"
  else
    puzzle_date="$(parse_json "$list_json" --argjson idx "$index" '.results[$idx].print_date // empty')"
  fi
  
  # Format filename using pattern and get full save path
  timestamp=$(date +%Y%m%dT%H%M%S)
  out_name="$(format_filename "$SAVE_FILENAME_PATTERN" "$puzzid" "$puzzle_date" "$timestamp")"
  out_path="$(get_save_path "$out_name")"
  
  mv "$tmp_pdf" "$out_path"
  log_message 1 "Saved PDF to: $out_path"
  exit 0
fi

# Print via lpr. Use array expansion for LPR_OPTS.
log_message 1 "Sending PDF to printer '$PRINTER'..."
if ! lpr -P "$PRINTER" "${LPR_OPTS_ARRAY[@]}" "$tmp_pdf"; then
  if [[ "$KEEP_TEMP_FILES" == "true" ]]; then
    error_exit "Printing failed. File is saved at: $tmp_pdf" 10
  else
    error_exit "Printing failed. File was: $tmp_pdf" 10
  fi
fi

log_message 1 "Printed successfully."

# Clean up temporary file unless configured to keep them
if [[ "$KEEP_TEMP_FILES" == "true" ]]; then
  log_message 2 "Keeping temporary file at: $tmp_pdf"
else
  log_message 2 "Cleaning up temporary file..."
  rm -f "$tmp_pdf"
fi

log_message 1 "Done."
exit 0