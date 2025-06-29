# Use a minimal Alpine-based Ruby image (~50MB base)
FROM ruby:3.2-alpine

# Install necessary system dependencies for common gems (e.g., octokit, tty-prompt)
RUN apk add --no-cache \
  build-base \
  libffi-dev \
  yaml-dev \
  git \
  curl \
  bash

EXPOSE 4567

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Copy the rest of the code
COPY . .

# Set default entrypoint and command
ENTRYPOINT ["ruby", "bin/github-analyzer", "analyze"]
