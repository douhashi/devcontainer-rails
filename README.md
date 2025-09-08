# Rails 8 Template

A modern Rails 8 application template with best practices and essential configurations.

## Features

- Rails 8 with Propshaft
- ViewComponent for UI components
- Lookbook for component development
- Solid Queue for background jobs
- Foreman for process management
- Structured documentation system
- MusicGeneration model for efficient API management (NEW)

## Getting Started

```bash
# Install dependencies
bundle install
npm install

# Setup database
bin/rails db:setup

# Start development server (runs on port 5100)
bin/server
```

## Development with Dev Container

This project includes Dev Container configuration for consistent development environments.

### Using VS Code

1. Install the "Dev Containers" extension in VS Code
2. Open the project folder in VS Code
3. Press `F1` and select "Dev Containers: Reopen in Container"
4. VS Code will build and start the container automatically

### Using Dev Container CLI

For command-line usage, use the provided scripts:

```bash
# Rebuild the container (useful after configuration changes)
.devcontainer/bin/rebuild

# Start the dev container
.devcontainer/bin/up

# Stop the dev container
.devcontainer/bin/down
```

These scripts wrap the devcontainer CLI commands for easier management of the development environment.

## Architecture Improvements

### MusicGeneration Model

The MusicGeneration model optimizes KIE API usage by fully utilizing the API response:

- **Before**: 1 API call → 1 Track (wasting the 2nd track in response)
- **After**: 1 API call → 1 MusicGeneration → 2 Tracks

Benefits:
- 50% reduction in API calls
- Better error handling and retry logic
- Clear separation between API management and track creation
- Foundation for future batch processing optimizations

For migration details, see [Migration Strategy](docs/migration_strategy.md).

## Documentation

Project documentation is organized under `docs/`:
- `business/` - Business documents
- `development/` - Development guides
- `operations/` - Operational documents
- `migration_strategy.md` - MusicGeneration migration plan# Force CI re-run
