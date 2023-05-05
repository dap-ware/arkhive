#!/usr/bin/env bash

# Function to display usage information
usage() {
  echo "Usage: $0 [OPTIONS] [DOMAINS...]"
  echo
  echo "Retrieve a list of URLs from the Wayback CDX API for specified domains."
  echo "Domains can be provided as arguments, via standard input (STDIN),"
  echo "or using the -d/--domain or -dL/--domain-list options."
  echo
  echo "Options:"
  echo "  -d, --domain DOMAIN       Specify a single domain."
  echo "  -dL, --domain-list FILE   Specify a file containing a list of domains."
  echo "  -o, --output FILE         Write URLs to the specified output FILE."
  echo "                            If not specified, write to STDOUT."
  echo "  -b, --blacklist EXT       Comma-separated list of file extensions to blacklist."
  echo "  -g, --grep STRING         Grep for STRING in the URLs."
  echo "  -q, --quiet               Suppress non-essential output."
  echo "  -v, --verbose             Display additional information about script operation."
  echo "  -h, --help                Display this help message and exit."
  echo
  echo "Examples:"
  echo "  # Retrieve URLs for example.com and output to the terminal"
  echo "  $0 -d example.com"
  echo
  echo "  # Retrieve URLs for domains listed in domains.txt and output to urls.txt"
  echo "  $0 -dL domains.txt -o urls.txt"
  echo
  echo "  # Retrieve URLs for domains provided via STDIN and output to the terminal"
  echo "  cat domains.txt | $0"
  echo
  echo "  # Retrieve URLs for example.com, blacklist URLs with jpg, tif, and gif extensions,"
  echo "  # and grep for 'login' in the URLs"
  echo "  $0 -d example.com -b jpg,tif,gif -g login"
  echo
  exit 1
}

# Function to retrieve URLs from the Wayback CDX API for a specified domain
retrieve_urls() {
  local domain="$1"
  curl -sS --max-time 240 "https://web.archive.org/cdx/search/cdx?url=*.$domain&output=xml&fl=original&collapse=urlkey"
}

# Initialize variables
quiet=false
verbose=false
domains=()
blacklist=()
grep_string=""

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -d|--domain)
      if [[ "$#" -gt 1 ]]; then
        domains+=("$2")
        shift
      else
        echo "Error: Missing argument for $1"
        usage
      fi
      ;;
    -dL|--domain-list)
      if [[ "$#" -gt 1 ]]; then
        mapfile -t file_domains < "$2"
        domains+=("${file_domains[@]}")
        shift
      else
        echo "Error: Missing argument for $1"
        usage
      fi
      ;;
    -o|--output)
      if [[ "$#" -gt 1 ]]; then
        output_file="$2"
        shift
      else
        echo "Error: Missing argument for $1"
        usage
      fi
      ;;
    -b|--blacklist)
      if [[ "$#" -gt 1 ]]; then
        IFS=',' read -ra blacklist <<< "$2"
        shift
      else
        echo "Error: Missing argument for $1"
        usage
      fi
      ;;
    -g|--grep)
      if [[ "$#" -gt 1 ]]; then
        grep_string="$2"
        shift
      else
        echo "Error: Missing argument for $1"
        usage
      fi
      ;;
    -q|--quiet)
      quiet=true
      ;;
    -v|--verbose)
      verbose=true
      ;;
    -h|--help)
      usage
      ;;
    *)
      # Assume any other arguments are domains
      domains+=("$1")
      ;;
  esac
  shift
done

# If no domains are specified, use STDIN
if [[ ${#domains[@]} -eq 0 ]]; then
  mapfile -t stdin_domains
  domains+=("${stdin_domains[@]}")
fi

# Check if output file exists and prompt for confirmation
if [[ -n "$output_file" && -e "$output_file" && "$quiet" = false ]]; then
  read -p "Output file '$output_file' already exists. Overwrite? [y/N] " confirm
  if [[ "${confirm,,}" != "y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Initialize variable for storing results
results=()

# Process each domain
for domain in "${domains[@]}"; do
  # Display verbose information if the verbose mode is enabled
  if [[ "$verbose" = true ]]; then
    echo "Retrieving URLs for domain: $domain"
  fi

  # Retrieve URLs for the current domain
  urls=$(retrieve_urls "$domain")

  # Check for errors
  if [[ -z "$urls" ]]; then
    if [[ "$quiet" = false ]]; then
      echo "Error: Failed to retrieve URLs for domain: $domain"
    fi
    continue
  fi

  # Filter out blacklisted extensions
  if [[ ${#blacklist[@]} -gt 0 ]]; then
    urls=$(grep -vE "\.($(IFS=\|; echo "${blacklist[*]}"))$" <<< "$urls")
  fi

  # Filter by grep string if specified
  if [[ -n "$grep_string" ]]; then
    urls=$(grep -i -E "$grep_string" <<< "$urls")
  fi

  # Add retrieved URLs to the results
  results+=("$urls")

  # Sleep to avoid rate limiting
  sleep 1
done

# Output the results to the specified file or to STDOUT
if [[ -z "$output_file" ]]; then
  printf '%s\n' "${results[@]}"
else
  # Empty or create the output file
  : > "$output_file"
  printf '%s\n' "${results[@]}" >> "$output_file"
fi

# Display verbose information if the verbose mode is enabled
if [[ "$verbose" = true ]]; then
  echo "Processed ${#domains[@]} domain(s)"
  echo "Retrieved ${#results[@]} URL(s)"
fi
