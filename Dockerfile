# Multi-stage Dockerfile for MSVC 6.0 with Wibo
# Always builds for x86_64/amd64 architecture

# Stage 1: Extract MSVC compiler from scratch image
FROM --platform=linux/amd64 ghcr.io/decompme/compilers/win32/msvc6.0:latest AS msvc

# Stage 2: Get Wibo and build final image
FROM --platform=linux/amd64 ghcr.io/decompals/wibo:latest

# Copy MSVC compiler files from scratch image
COPY --from=msvc /compilers/win32/msvc6.0 /compiler

# Create tmp directory for intermediate compilation files
RUN mkdir -p /tmp/build

# Set up environment variables
ENV WIBO=/usr/local/sbin/wibo
ENV COMPILER_DIR=/compiler
ENV PATH="/usr/local/sbin:${PATH}"

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
