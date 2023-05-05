# Arkhive

This script retrieves a list of URLs from the Wayback CDX API for specified domains. Domains can be provided as arguments, via standard input (STDIN), or using the -d/--domain or -dL/--domain-list options. The script also supports filtering URLs based on file extensions and specified strings.

## Installation
```
git clone 
```

## Usage

```
Usage: arkhive.sh [OPTIONS] [DOMAINS...]

Retrieve a list of URLs from the Wayback CDX API for specified domains.
Domains can be provided as arguments, via standard input (STDIN),
or using the -d/--domain or -dL/--domain-list options.

Options:
  -d, --domain DOMAIN       Specify a single domain.
  -dL, --domain-list FILE   Specify a file containing a list of domains.
  -o, --output FILE         Write URLs to the specified output FILE.
                            If not specified, write to STDOUT.
  -b, --blacklist EXT       Comma-separated list of file extensions to blacklist.
  -g, --grep STRING         Grep for STRING in the URLs.
  -q, --quiet               Suppress non-essential output.
  -v, --verbose             Display additional information about script operation.
  -h, --help                Display this help message and exit.

Examples:
  # Retrieve URLs for example.com and output to the terminal
  arkhive.sh -d example.com

  # Retrieve URLs for domains listed in domains.txt and output to urls.txt
  arkhive.sh -dL domains.txt -o urls.txt

  # Retrieve URLs for domains provided via STDIN and output to the terminal
  cat domains.txt | arkhive.sh

  # Retrieve URLs for example.com, blacklist URLs with jpg, tif, and gif extensions,
  # and grep for 'login' in the URLs
  arkhive.sh -d example.com -b jpg,tif,gif -g login
```

## Notes

- The script includes a sleep interval between API requests to avoid rate limiting.
- The blacklist option allows you to exclude URLs with specific file extensions.
- The grep option allows you to filter URLs based on the presence of a specified string.
