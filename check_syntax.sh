#!/bin/bash
###############################################################################
# Bash Syntax Checker for RaspiCommandCenter
# 
# This script validates all bash scripts in the project for syntax errors
# and common issues that could cause runtime failures.
#
# Usage: ./check_syntax.sh
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
checked=0
errors=0
warnings=0

echo "🔍 RaspiCommandCenter Bash Syntax Checker"
echo "=========================================="
echo ""

# Function to check syntax of a single file
check_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo -n "Checking $filename... "
    
    # Basic bash syntax check
    if bash -n "$file" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((checked++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo -e "  ${RED}Syntax errors in $file:${NC}"
        bash -n "$file" 2>&1 | sed 's/^/    /'
        ((errors++))
        ((checked++))
        return 1
    fi
    
    # Additional checks for common issues
    local warnings_found=0
    
    # Check for functions without proper spacing
    if grep -q '}[a-zA-Z#]' "$file"; then
        echo -e "  ${YELLOW}⚠ WARNING: Missing newline after closing brace${NC}"
        grep -n '}[a-zA-Z#]' "$file" | sed 's/^/    Line /'
        warnings_found=1
    fi
    
    # Check for unmatched heredocs
    local heredoc_start=$(grep -c '<<[[:space:]]*[A-Z]' "$file" 2>/dev/null || true)
    local heredoc_end=$(grep -c '^[A-Z]\+$' "$file" 2>/dev/null || true)
    if [[ $heredoc_start -ne $heredoc_end ]]; then
        echo -e "  ${YELLOW}⚠ WARNING: Possible unmatched heredocs (start: $heredoc_start, end: $heredoc_end)${NC}"
        warnings_found=1
    fi
    
    # Check for common variable issues
    if grep -q '\$[A-Za-z_][A-Za-z0-9_]*[^A-Za-z0-9_}]' "$file"; then
        # This is a complex pattern - let's simplify and just check for potential unquoted vars
        local unquoted_vars=$(grep -o '\$[A-Za-z_][A-Za-z0-9_]*' "$file" | grep -v '\${' | wc -l || true)
        if [[ $unquoted_vars -gt 0 ]]; then
            echo -e "  ${YELLOW}⚠ INFO: Found $unquoted_vars potentially unquoted variables${NC}"
        fi
    fi
    
    if [[ $warnings_found -eq 1 ]]; then
        ((warnings++))
    fi
    
    return 0
}

# Check all shell scripts
echo "Checking main scripts:"
for script in start.sh; do
    if [[ -f "$script" ]]; then
        check_file "$script"
    fi
done

echo ""
echo "Checking script directory:"
for script in scripts/*.sh; do
    if [[ -f "$script" ]]; then
        check_file "$script"
    fi
done

echo ""
echo "Checking utility scripts:"
for script in utils/*.sh; do
    if [[ -f "$script" ]]; then
        check_file "$script"
    fi
done

echo ""
echo "=========================================="
echo "Summary:"
echo "  Files checked: $checked"
if [[ $errors -eq 0 ]]; then
    echo -e "  Syntax errors: ${GREEN}$errors${NC}"
else
    echo -e "  Syntax errors: ${RED}$errors${NC}"
fi

if [[ $warnings -eq 0 ]]; then
    echo -e "  Warnings: ${GREEN}$warnings${NC}"
else
    echo -e "  Warnings: ${YELLOW}$warnings${NC}"
fi

echo ""
if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}🎉 All scripts passed syntax validation!${NC}"
    exit 0
else
    echo -e "${RED}❌ $errors script(s) have syntax errors that must be fixed.${NC}"
    exit 1
fi
