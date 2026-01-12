# Bash Shell Script Development Skill

This skill provides comprehensive guidelines for creating high-quality, maintainable bash shell scripts.

## Critical Requirements

- **ALWAYS** include shebang `#!/usr/bin/env bash` at the top of every script
- **ALWAYS** use `set -euo pipefail` for error handling (unless specific behavior requires otherwise)
- **ALWAYS** quote variables to prevent word splitting: `"$variable"` not `$variable`
- **ALWAYS** check if a command exists before using it with `command -v`
- **NEVER** use `eval` unless absolutely necessary and after careful security review
- **NEVER** parse `ls` output - use globs or `find` instead
- **NO EMOJIS** in scripts or comments

## Script Structure

### Standard Template

```bash
#!/usr/bin/env bash

# Script: script_name.sh
# Description: Brief description of what the script does
# Usage: script_name.sh [options] [arguments]

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Color codes for output (optional)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Functions
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [ARGUMENTS]

Description of what this script does.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -d, --debug     Enable debug mode

ARGUMENTS:
    arg1            Description of argument 1
    arg2            Description of argument 2

EXAMPLES:
    ${SCRIPT_NAME} --verbose file.txt
    ${SCRIPT_NAME} -d input.txt output.txt
EOF
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

cleanup() {
    # Cleanup code here (temp files, etc.)
    :
}

main() {
    # Main script logic here
    :
}

# Trap errors and cleanup
trap cleanup EXIT
trap 'log_error "Script failed at line $LINENO"' ERR

# Parse arguments and run main
main "$@"
```

## Best Practices

### Error Handling

1. **Use `set -euo pipefail`**:
   - `set -e`: Exit on error
   - `set -u`: Exit on undefined variable
   - `set -o pipefail`: Exit on pipe failure

2. **Check command exit codes explicitly when needed**:
   ```bash
   if ! command_that_might_fail; then
       log_error "Command failed"
       exit 1
   fi
   ```

3. **Use trap for cleanup**:
   ```bash
   trap cleanup EXIT
   trap 'log_error "Error at line $LINENO"' ERR
   ```

### Variable Quoting

1. **Always quote variables**:
   ```bash
   # Good
   cp "$source" "$destination"

   # Bad
   cp $source $destination
   ```

2. **Quote command substitutions**:
   ```bash
   # Good
   result="$(some_command)"

   # Bad
   result=$(some_command)
   ```

3. **Use arrays for lists**:
   ```bash
   # Good
   files=("file1.txt" "file 2.txt" "file3.txt")
   for file in "${files[@]}"; do
       process "$file"
   done

   # Bad
   files="file1.txt file 2.txt file3.txt"
   for file in $files; do
       process $file
   done
   ```

### Conditionals and Comparisons

1. **Use `[[ ]]` instead of `[ ]`**:
   ```bash
   # Good - modern bash
   if [[ "$var" == "value" ]]; then
       echo "Match"
   fi

   # Acceptable but older
   if [ "$var" = "value" ]; then
       echo "Match"
   fi
   ```

2. **Check if variable is set**:
   ```bash
   # Check if set and non-empty
   if [[ -n "${var:-}" ]]; then
       echo "Variable is set"
   fi

   # Check if unset or empty
   if [[ -z "${var:-}" ]]; then
       echo "Variable is not set"
   fi
   ```

3. **File tests**:
   ```bash
   if [[ -f "$file" ]]; then echo "Regular file exists"; fi
   if [[ -d "$dir" ]]; then echo "Directory exists"; fi
   if [[ -x "$script" ]]; then echo "File is executable"; fi
   if [[ -r "$file" ]]; then echo "File is readable"; fi
   ```

### Command Substitution

1. **Use `$()` instead of backticks**:
   ```bash
   # Good
   result="$(command)"

   # Bad
   result=`command`
   ```

2. **Check if command exists before using**:
   ```bash
   if ! command -v jq &> /dev/null; then
       log_error "jq is not installed"
       exit 1
   fi
   ```

### Functions

1. **Use local variables**:
   ```bash
   process_file() {
       local file="$1"
       local output="${2:-output.txt}"

       # Process the file
       cat "$file" > "$output"
   }
   ```

2. **Return values properly**:
   ```bash
   # For numeric return codes (0-255)
   check_status() {
       if [[ -f "$1" ]]; then
           return 0  # Success
       else
           return 1  # Failure
       fi
   }

   # For string output, use echo
   get_filename() {
       local path="$1"
       echo "$(basename "$path")"
   }

   # Usage
   if check_status "/path/to/file"; then
       filename="$(get_filename "/path/to/file")"
   fi
   ```

### Argument Parsing

1. **Use getopts for simple cases**:
   ```bash
   while getopts "hvd:" opt; do
       case $opt in
           h) usage; exit 0 ;;
           v) verbose=1 ;;
           d) directory="$OPTARG" ;;
           \?) log_error "Invalid option: -$OPTARG"; exit 1 ;;
       esac
   done
   shift $((OPTIND - 1))
   ```

2. **Manual parsing for long options**:
   ```bash
   while [[ $# -gt 0 ]]; do
       case $1 in
           -h|--help)
               usage
               exit 0
               ;;
           -v|--verbose)
               verbose=1
               shift
               ;;
           -o|--output)
               output="$2"
               shift 2
               ;;
           *)
               log_error "Unknown option: $1"
               exit 1
               ;;
       esac
   done
   ```

## Common Patterns

### Working with Files

1. **Read file line by line**:
   ```bash
   while IFS= read -r line; do
       echo "Line: $line"
   done < "$file"
   ```

2. **Process files matching pattern**:
   ```bash
   # Using glob
   for file in *.txt; do
       [[ -f "$file" ]] || continue
       process "$file"
   done

   # Using find for complex patterns
   while IFS= read -r -d '' file; do
       process "$file"
   done < <(find . -name "*.txt" -type f -print0)
   ```

3. **Create temporary files/directories**:
   ```bash
   temp_file="$(mktemp)"
   temp_dir="$(mktemp -d)"

   cleanup() {
       rm -f "$temp_file"
       rm -rf "$temp_dir"
   }
   trap cleanup EXIT
   ```

### String Manipulation

1. **Parameter expansion**:
   ```bash
   # Remove prefix/suffix
   filename="${path##*/}"        # basename
   directory="${path%/*}"        # dirname
   extension="${filename##*.}"   # file extension
   basename="${filename%.*}"     # filename without extension

   # Default values
   value="${var:-default}"       # Use default if var is unset/empty
   value="${var:=default}"       # Assign default if var is unset/empty

   # String replacement
   new="${old/pattern/replacement}"     # Replace first occurrence
   new="${old//pattern/replacement}"    # Replace all occurrences
   ```

2. **String length and substrings**:
   ```bash
   length="${#string}"
   substring="${string:0:5}"     # First 5 characters
   substring="${string: -5}"     # Last 5 characters
   ```

### Arrays

1. **Array operations**:
   ```bash
   # Declaration
   array=("item1" "item2" "item3")

   # Access elements
   echo "${array[0]}"           # First element
   echo "${array[@]}"           # All elements
   echo "${#array[@]}"          # Array length

   # Iteration
   for item in "${array[@]}"; do
       echo "$item"
   done

   # Add elements
   array+=("item4")
   ```

2. **Associative arrays (bash 4+)**:
   ```bash
   declare -A map
   map["key1"]="value1"
   map["key2"]="value2"

   # Iterate
   for key in "${!map[@]}"; do
       echo "$key: ${map[$key]}"
   done
   ```

## Security Considerations

1. **Never use user input directly in commands**:
   ```bash
   # Bad - command injection vulnerability
   eval "rm $user_input"

   # Good - validate and sanitize
   if [[ "$user_input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
       rm -f "$user_input"
   fi
   ```

2. **Use full paths for commands in scripts run as root**:
   ```bash
   # Good
   /usr/bin/rm -f "$file"

   # Risky if PATH is modified
   rm -f "$file"
   ```

3. **Set secure permissions on sensitive scripts**:
   ```bash
   chmod 700 sensitive_script.sh  # Owner only
   chmod 755 public_script.sh     # All can read/execute
   ```

4. **Avoid exposing secrets in process list**:
   ```bash
   # Bad - password visible in ps
   mysql -p"$password" -e "SELECT * FROM users"

   # Good - use config file
   mysql --defaults-file="$config_file" -e "SELECT * FROM users"
   ```

## Testing and Validation

### ShellCheck

Always run shellcheck on scripts:

```bash
shellcheck script.sh
```

Common shellcheck directives:
```bash
# Disable specific warning
# shellcheck disable=SC2034
unused_var="value"

# Disable for whole file
# shellcheck disable=SC1091
source /path/to/file
```

### BATS (Bash Automated Testing System)

Example test file (test.bats):
```bash
#!/usr/bin/env bats

@test "script exists and is executable" {
    [ -x "./script.sh" ]
}

@test "script prints usage with --help" {
    run ./script.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "script fails without required arguments" {
    run ./script.sh
    [ "$status" -ne 0 ]
}
```

### Manual Testing Checklist

- [ ] Script runs without errors
- [ ] All edge cases handled (empty input, missing files, etc.)
- [ ] Error messages are clear and helpful
- [ ] Exit codes are appropriate (0 for success, non-zero for errors)
- [ ] No shellcheck warnings
- [ ] Variables are properly quoted
- [ ] Cleanup happens on exit (no temp files left behind)
- [ ] Script is idempotent when possible

## Code Review Checklist

- [ ] Shebang present and correct
- [ ] `set -euo pipefail` used (or justified exception)
- [ ] All variables quoted properly
- [ ] No parsing of `ls` output
- [ ] Functions use `local` variables
- [ ] Error messages go to stderr
- [ ] Proper cleanup with trap
- [ ] No use of `eval` without justification
- [ ] Command existence checked before use
- [ ] Usage/help message provided
- [ ] No hardcoded paths (use configuration or detection)
- [ ] Array usage for lists of items
- [ ] `[[ ]]` used instead of `[ ]`
- [ ] No security vulnerabilities (command injection, etc.)
- [ ] Shellcheck passes with no warnings

## Common Anti-Patterns to Avoid

1. **Parsing ls output**:
   ```bash
   # Bad
   for file in $(ls *.txt); do
       process "$file"
   done

   # Good
   for file in *.txt; do
       [[ -f "$file" ]] || continue
       process "$file"
   done
   ```

2. **Unquoted variables**:
   ```bash
   # Bad
   if [ $var == $other ]; then

   # Good
   if [[ "$var" == "$other" ]]; then
   ```

3. **Using `echo` for output that might contain flags**:
   ```bash
   # Bad - can interpret flags
   echo "$user_input"

   # Good
   printf '%s\n' "$user_input"
   ```

4. **Cat abuse (UUOC - Useless Use of Cat)**:
   ```bash
   # Bad
   cat file.txt | grep pattern

   # Good
   grep pattern file.txt
   ```

5. **Not checking if commands exist**:
   ```bash
   # Bad
   jq '.field' file.json

   # Good
   if ! command -v jq &> /dev/null; then
       log_error "jq is required but not installed"
       exit 1
   fi
   jq '.field' file.json
   ```

## Useful Resources

- ShellCheck: https://www.shellcheck.net/
- Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
- BATS Testing: https://github.com/bats-core/bats-core
- Bash Reference Manual: https://www.gnu.org/software/bash/manual/

## Integration with Existing Skills

When creating bash scripts for:
- **Go projects**: Reference the golang.md skill for project structure
- **Minecraft mods**: Reference minecraft-mods.md for API interaction patterns
- **New projects**: Reference start-project.md for initial setup checklist
