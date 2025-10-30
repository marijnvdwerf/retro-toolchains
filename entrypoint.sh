#!/bin/sh
# Entrypoint script for MSVC 6.0 compiler container
# This script runs inside the container and invokes CL.EXE via Wibo

set -e

# Check if OUTPUT is set (always required)
if [ -z "$OUTPUT" ]; then
    echo "Error: OUTPUT environment variable not set" >&2
    exit 1
fi

# COMPILER_FLAGS is optional, default to empty
COMPILER_FLAGS="${COMPILER_FLAGS:-}"

# Handle INPUT: if set to "-", read from stdin and create temp file
if [ "$INPUT" = "-" ]; then
    TEMP_INPUT="/tmp/build/stdin_input.c"
    echo "Reading source from stdin..." >&2
    cat > "$TEMP_INPUT"
    INPUT_PATH="Z:$TEMP_INPUT"
    DISPLAY_INPUT="<stdin>"
elif [ -z "$INPUT" ]; then
    echo "Error: INPUT environment variable not set (use '-' for stdin)" >&2
    exit 1
else
    INPUT_PATH="Z:$INPUT"
    DISPLAY_INPUT="$INPUT"
fi

# Build the CL.EXE command
# Using Z: drive prefix for paths as required by Wibo
CL_COMMAND="${WIBO} ${COMPILER_DIR}/Bin/CL.EXE /c /nologo /I\"Z:${COMPILER_DIR}/Include/\" ${COMPILER_FLAGS} /Fd\"Z:/tmp/build/\" /Fo\"Z:${OUTPUT}\" \"${INPUT_PATH}\""

# Execute the command
echo "Compiling: $DISPLAY_INPUT -> $OUTPUT"
if [ -n "$VERBOSE" ]; then
    echo "Command: $CL_COMMAND"
fi

eval "$CL_COMMAND"
