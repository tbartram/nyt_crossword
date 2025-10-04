#!/usr/bin/env bash
set -uo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.sh"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  echo "WARNING: Config file not found at $CONFIG_FILE, using built-in defaults" >&2
  # Fallback defaults if config file is missing
  COOKIES="./cookies/www.nytimes.com_cookies.txt"
  LPR_OPTS="-o media=Letter -o fit-to-page"
  TMPDIR="${TMPDIR:-/tmp}"
  # No default PRINTER - must be set via config or command line
fi

# Convert LPR_OPTS string to array for use with lpr command
IFS=' ' read -ra LPR_OPTS_ARRAY <<< "$LPR_OPTS"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-c cookie_file] [-o OFFSET | -d DATE | -r] [-p printer] [-s] [-n] [-h]
  -c COOKIE_FILE   Path to cookies.txt (Netscape format). Default: $COOKIES
  -o OFFSET        Which puzzle to fetch by index:
                     0  = most recent (default)
                     1  = second most recent
                     2  = third most recent
                     -1 = same as 1 (accepts negative for convenience)
  -d DATE          Fetch puzzle for specific date (YYYY-MM-DD format)
  -r               Fetch a random puzzle from across different eras (1942-present)
  -p PRINTER       lpr printer name. Required for printing (unless -s or -n)
  -s               Save PDF to local file instead of printing (prints filename)
  -n               Dry-run: show URL and curl command only, do not download/print
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

# defaults
cookie_file="$COOKIES"
offset=0
target_date=""
random_puzzle=false
save_only=false
dry_run=false

# parse options
while getopts ":c:o:d:rp:snh" opt; do
  case "$opt" in
    c) cookie_file="$OPTARG" ;;
    o) offset="$OPTARG" ;;
    d) target_date="$OPTARG" ;;
    r) random_puzzle=true ;;
    p) PRINTER="$OPTARG" ;;
    s) save_only=true ;;
    n) dry_run=true ;;
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
  echo "ERROR: Cannot use multiple selection options (-o, -d, -r) together." >&2
  exit 12
fi

# Validate date format if provided
if [[ -n "$target_date" ]]; then
  if ! [[ "$target_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "ERROR: Date must be in YYYY-MM-DD format. Got: '$target_date'" >&2
    exit 13
  fi
  # Validate it's a real date using date command (cross-platform)
  # Try GNU date first (Linux), then BSD date (macOS)
  if command -v date >/dev/null 2>&1; then
    if ! (date -d "$target_date" >/dev/null 2>&1 || date -j -f "%Y-%m-%d" "$target_date" >/dev/null 2>&1); then
      echo "ERROR: Invalid date: '$target_date'" >&2
      exit 14
    fi
  fi
fi

# Expand ~ in cookie path if present
if [[ "${cookie_file}" == ~* ]]; then
  cookie_file="${cookie_file/#\~/$HOME}"
fi

# Validate printer is set if we need to print
if ! $save_only && ! $dry_run; then
  if [[ -z "${PRINTER:-}" ]]; then
    echo "ERROR: No printer specified. Use -p PRINTER, set PRINTER in config.sh, or use -s to save to file or -n for dry-run." >&2
    exit 11
  fi
fi

# validate dependencies
for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command '$cmd' not found. Install it and try again." >&2
    if [[ "$cmd" == "jq" ]]; then
      echo "  On Ubuntu/Debian: sudo apt-get install jq" >&2
      echo "  On macOS with Homebrew: brew install jq" >&2
    fi
    exit 2
  fi
done

# lpr is required for printing; if save_only or dry_run we can skip it
if ! $save_only && ! $dry_run; then
  if ! command -v lpr >/dev/null 2>&1; then
    echo "ERROR: 'lpr' not found. Install/CUPS or use -s to save to file instead." >&2
    exit 2
  fi
fi

# normalize offset: allow negative for convenience
# Our mapping: 0 => results[0] (most recent), 1 => results[1] (second most recent), etc.
if [[ -z "$target_date" && "$random_puzzle" == false ]]; then
  if ! [[ "$offset" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: offset must be an integer. Got: '$offset'" >&2
    exit 3
  fi
  if (( offset < 0 )); then
    index=$(( -offset ))
  else
    index=$offset
  fi
fi

# Ensure cookie file exists
if [[ ! -f "$cookie_file" ]]; then
  echo "ERROR: cookie file not found: $cookie_file" >&2
  echo "Make sure you've exported cookies for https://www.nytimes.com (Netscape cookies.txt format)." >&2
  exit 4
fi

# build URL to list puzzles based on selection mode
if [[ "$random_puzzle" == true ]]; then
  # For random puzzle, we'll randomly select from different eras and then pick a random date within that era
  # This ensures true randomness across the entire era, not just the most recent 100 puzzles
  
  # Randomly choose an era to pull from
  era_choice=$((RANDOM % 4))
  case $era_choice in
    0)
      # Recent era (past 2 years)
      # Cross-platform date calculation for 2 years ago
      current_year=$(date +%Y)
      two_years_ago=$((current_year - 2))
      era_start="${two_years_ago}-$(date +%m-%d)"
      era_end=$(date +%Y-%m-%d)
      era_desc="recent (past 2 years)"
      ;;
    1)
      # Modern era (2000-2022)
      era_start="2000-01-01"
      era_end="2022-12-31"
      era_desc="modern (2000-2022)"
      ;;
    2)
      # Classic era (1970-1999)
      era_start="1970-01-01"
      era_end="1999-12-31"
      era_desc="classic (1970-1999)"
      ;;
    3)
      # Historical era (1942-1969) - includes Sunday-only period
      era_start="1942-02-15"
      era_end="1969-12-31"
      era_desc="historical (1942-1969)"
      ;;
  esac
  
  # Generate a random date within the selected era
  if [[ $era_choice -eq 3 ]]; then
    # Historical era has very few puzzles, so use the full date range
    buffer_start="$era_start"
    buffer_end="$era_end"
    random_date="$era_start"  # Just for display
  else
    # For all other eras: pick a random year, then a random date within that year
    era_start_year=$(echo "$era_start" | cut -d- -f1)
    era_end_year=$(echo "$era_end" | cut -d- -f1)
    year_range=$((era_end_year - era_start_year + 1))
    random_year=$((era_start_year + RANDOM % year_range))
    
    # Pick a random month and day
    random_month=$((1 + RANDOM % 12))
    
    # Calculate the correct number of days for the selected month and year
    case $random_month in
      1|3|5|7|8|10|12) days_in_month=31 ;;  # Jan, Mar, May, Jul, Aug, Oct, Dec
      4|6|9|11) days_in_month=30 ;;         # Apr, Jun, Sep, Nov
      2)
        # February - check for leap year
        if (( (random_year % 4 == 0 && random_year % 100 != 0) || random_year % 400 == 0 )); then
          days_in_month=29  # Leap year
        else
          days_in_month=28  # Regular year
        fi
        ;;
    esac
    
    random_day=$((1 + RANDOM % days_in_month))
    
    random_date=$(printf "%04d-%02d-%02d" "$random_year" "$random_month" "$random_day")
    
    # Create a window around this date (use full year range to increase chances)
    buffer_start=$(printf "%04d-01-01" "$random_year")
    buffer_end=$(printf "%04d-12-31" "$random_year")
  fi
  
  LIST_URL="https://www.nytimes.com/svc/crosswords/v3/289669378/puzzles.json?sort_order=desc&sort_by=print_date&date_start=${buffer_start}&date_end=${buffer_end}&limit=100"
  echo "Fetching puzzle list for random selection from $era_desc era (around $random_date)..."
else
  # For offset or date-based selection
  if [[ -n "$target_date" ]]; then
    # For specific date requests, use date range API to access historical puzzles
    # Create a small window around the target date to find the puzzle
    start_date="$target_date"
    end_date="$target_date"
    LIST_URL="https://www.nytimes.com/svc/crosswords/v3/289669378/puzzles.json?sort_order=desc&sort_by=print_date&date_start=${start_date}&date_end=${end_date}&limit=10"
    echo "Fetching puzzle list to find puzzle for date: $target_date..."
  else
    # For offset-based selection, use the standard URL (recent puzzles only)
    LIST_URL="https://www.nytimes.com/svc/crosswords/v3/289669378/puzzles.json?publish_type=daily&sort_order=desc&sort_by=print_date"
    echo "Fetching puzzle list (index: $index) from NYT..."
  fi
fi

# fetch list, fail on HTTP errors (--fail), be quiet but show errors (-sS), follow redirects (-L)
# we pass cookies via -b cookie_file (curl will read Netscape format)
list_json="$(curl --fail -sS -b "$cookie_file" -L "$LIST_URL")" || {
  echo "ERROR: Failed to fetch puzzle list. Check network, cookie freshness, and that you are authenticated." >&2
  exit 5
}

# extract puzzle id based on selection mode
if [[ "$random_puzzle" == true ]]; then
  # First check if results is null (no puzzles for the selected era)
  results_check="$(printf '%s' "$list_json" | jq -r '.results // "null"')"
  if [[ "$results_check" == "null" ]]; then
    echo "No puzzles found around $random_date, falling back to full era range..." >&2
    # Fall back to full era range
    LIST_URL="https://www.nytimes.com/svc/crosswords/v3/289669378/puzzles.json?sort_order=desc&sort_by=print_date&date_start=${era_start}&date_end=${era_end}&limit=100"
    list_json="$(curl --fail -sS -b "$cookie_file" -L "$LIST_URL")" || {
      echo "ERROR: Failed to fetch puzzle list for fallback. Check network, cookie freshness, and that you are authenticated." >&2
      exit 5
    }
    results_check="$(printf '%s' "$list_json" | jq -r '.results // "null"')"
    if [[ "$results_check" == "null" ]]; then
      echo "ERROR: No puzzles found in the $era_desc era at all. This is unexpected - please try again." >&2
      exit 6
    fi
  fi
  
  # Get total number of puzzles available
  puzzle_count="$(printf '%s' "$list_json" | jq -r '.results | length')"
  
  if [[ "$puzzle_count" == "0" ]]; then
    echo "ERROR: No puzzles found for random selection in the $era_desc era." >&2
    exit 6
  fi
  
  # Generate random index (0-based)
  random_index=$((RANDOM % puzzle_count))
  puzzid="$(printf '%s' "$list_json" | jq -r --argjson idx "$random_index" '.results[$idx].puzzle_id // empty')"
  puzzle_date="$(printf '%s' "$list_json" | jq -r --argjson idx "$random_index" '.results[$idx].print_date // empty')"
  
  echo "Selected random puzzle from $puzzle_date (puzzle $((random_index + 1)) of $puzzle_count available)"
  
elif [[ -n "$target_date" ]]; then
  # Find puzzle by date
  # First check if results is null (no puzzles for that date)
  results_check="$(printf '%s' "$list_json" | jq -r '.results // "null"')"
  if [[ "$results_check" == "null" ]]; then
    echo "ERROR: No puzzle found for date $target_date. This date may not have had a published puzzle." >&2
    exit 6
  fi
  
  puzzid="$(printf '%s' "$list_json" | jq -r --arg date "$target_date" '.results[] | select(.print_date == $date) | .puzzle_id // empty' | head -1)"
  
  if [[ -z "$puzzid" || "$puzzid" == "null" ]]; then
    echo "ERROR: Could not find puzzle for date $target_date. Available dates (first 10):" >&2
    printf '%s\n' "$list_json" | jq -r '.results[0:10] | .[] | .print_date' 2>/dev/null || true
    exit 6
  fi
else
  # Find puzzle by index
  puzzid="$(printf '%s' "$list_json" | jq -r --argjson idx "$index" '.results[$idx].puzzle_id // empty')"
  
  if [[ -z "$puzzid" || "$puzzid" == "null" ]]; then
    echo "ERROR: Could not find puzzle id at index $index. The puzzle list may be shorter than requested or your cookies may not grant access." >&2
    # optionally print some debugging info (first few results)
    echo "First few puzzle ids (for debugging):"
    printf '%s\n' "$list_json" | jq -r '.results[0:5] | .[]?.puzzle_id' 2>/dev/null || true
    exit 6
  fi
fi

# build PDF url
pdf_url="https://www.nytimes.com/svc/crosswords/v2/puzzle/${puzzid}.pdf"

# prepare temporary filename
timestamp=$(date +%Y%m%dT%H%M%S)
tmp_pdf="${TMPDIR%/}/nyt-puzzle-${puzzid}-${timestamp}.pdf"

echo "Puzzle id: $puzzid"
echo "PDF URL: $pdf_url"

if $dry_run; then
  echo "Dry-run: would run:"
  echo "  curl -L -b \"$cookie_file\" \"$pdf_url\" -o \"$tmp_pdf\""
  exit 0
fi

echo "Downloading PDF..."
# download with curl, fail on HTTP error, follow redirects
if ! curl --fail -sS -b "$cookie_file" -L "$pdf_url" -o "$tmp_pdf"; then
  echo "ERROR: Failed to download PDF. Possible causes: expired cookies, access denied, or URL changed." >&2
  rm -f "$tmp_pdf" || true
  exit 7
fi

# validate PDF (simple check: file exists and not empty and starts with %PDF)
if [[ ! -s "$tmp_pdf" ]]; then
  echo "ERROR: Downloaded PDF is empty." >&2
  rm -f "$tmp_pdf"
  exit 8
fi
if ! head -c 4 "$tmp_pdf" | grep -q '%PDF'; then
  echo "ERROR: Downloaded file does not appear to be a PDF (first bytes do not start with %PDF)." >&2
  echo "File saved at: $tmp_pdf for inspection."
  exit 9
fi

if $save_only; then
  out_name="nyt-crossword-${puzzid}.pdf"
  mv "$tmp_pdf" "$out_name"
  echo "Saved PDF to: $out_name"
  exit 0
fi

# Print via lpr. Use array expansion for LPR_OPTS.
echo "Sending PDF to printer '$PRINTER'..."
if ! lpr -P "$PRINTER" "${LPR_OPTS_ARRAY[@]}" "$tmp_pdf"; then
  echo "ERROR: Printing failed. File is saved at: $tmp_pdf" >&2
  exit 10
fi

echo "Printed successfully. Cleaning up temporary file..."
rm -f "$tmp_pdf"

echo "Done."
exit 0