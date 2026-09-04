# lib/utils.sh — utility functions sourced by .zshrc
# Add your own reusable shell functions here.

# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1"  ;;
    *.tar.gz)  tar xzf "$1"  ;;
    *.tar.xz)  tar xJf "$1"  ;;
    *.tar)     tar xf  "$1"  ;;
    *.bz2)     bunzip2 "$1"  ;;
    *.gz)      gunzip  "$1"  ;;
    *.zip)     unzip   "$1"  ;;
    *.7z)      7z x    "$1"  ;;
    *)         echo "Unknown format: $1" ;;
  esac
}

# Quick search in files
fgrep() {
  grep -rn --color=auto "$1" "${2:-.}"
}

# Show PATH entries one per line
showpath() {
  echo "$PATH" | tr ':' '\n'
}
