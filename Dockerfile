# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# Install vips library for image processing
RUN sudo apt-get update && sudo apt-get install -y \
    libvips-dev \
    && sudo rm -rf /var/lib/apt/lists/*

