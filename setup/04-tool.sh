#!/bin/bash
set -e

# Get base directory
BASE_DIR="$(dirname "$0")"

# Load functions
source "${BASE_DIR}/scripts/functions/print_message.sh"

# Install development tools
print_section "Installing Development Tools"

# Install osoba
print_subsection "Installing osoba"
curl -L https://github.com/douhashi/soba/releases/latest/download/soba_$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m | sed 's/x86_64/x86_64/; s/aarch64/arm64/').tar.gz | tar xz -C /tmp && mkdir -p ~/.local/bin &&mv /tmp/soba ~/.local/bin/

print_success "Development tools installation completed"
