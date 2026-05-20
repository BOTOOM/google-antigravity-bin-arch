# Use a minimal Ubuntu image as a base
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies for the check script
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy the version check script into the container
COPY scripts/check-antigravity-version.sh .

# Make the script executable
RUN chmod +x check-antigravity-version.sh

# The command to run when the container starts
CMD ["./check-antigravity-version.sh"]
