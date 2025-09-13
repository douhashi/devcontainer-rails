#!/bin/bash
set -e

# メッセージ出力関数を読み込む
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${BASE_DIR}/setup/scripts/functions/print_message.sh"

print_section "Playwright Setup"

# Install Playwright browsers
print_subsection "Installing Playwright browsers..."
if npx playwright install chromium; then
    print_success "Playwright Chromium browser installed successfully"
else
    print_error "Failed to install Playwright Chromium browser"
    exit 1
fi

# Install system dependencies for Playwright
print_subsection "Installing Playwright system dependencies..."
if npx playwright install-deps chromium; then
    print_success "Playwright system dependencies installed successfully"
else
    print_error "Failed to install Playwright system dependencies"
    exit 1
fi

print_success "Playwright setup completed"