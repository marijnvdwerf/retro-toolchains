#!/bin/bash
# Wrapper script for MSVC 6.0 compiler in Docker
# Resolves paths and invokes the Docker container

set -e

# Default values
INPUT_FILE=""
OUTPUT_FILE=""
COMPILER_FLAGS=""
VERBOSE=""
IMAGE_NAME="msvc6-compiler"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="1"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 -i INPUT [-o OUTPUT] [COMPILER_FLAGS...]"
            echo ""
            echo "Options:"
            echo "  -i, --input FILE     Source file to compile (use '-' for stdin)"
            echo "  -o, --output FILE    Output object file (optional, stays in container if not specified)"
            echo "  -v, --verbose        Show full CL.EXE command"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Any additional arguments are passed as compiler flags to CL.EXE"
            echo ""
            echo "Examples:"
            echo "  $0 -i src/main.c -o build/main.obj /O2 /W3"
            echo "  $0 -i src/main.c /O2  # Check compilation only"
            echo "  cat src/main.c | $0 -i - -o build/main.obj /O2"
            exit 0
            ;;
        *)
            # Assume it's a compiler flag
            COMPILER_FLAGS="$COMPILER_FLAGS $1"
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Input file not specified. Use -i or --input (use '-' for stdin)" >&2
    echo "Run '$0 --help' for usage information" >&2
    exit 1
fi

# Handle output path (optional)
if [ -n "$OUTPUT_FILE" ]; then
    # Get absolute path (handle non-existent files on macOS)
    OUTPUT_DIR=$(cd "$(dirname "$OUTPUT_FILE")" 2>/dev/null && pwd || (mkdir -p "$(dirname "$OUTPUT_FILE")" && cd "$(dirname "$OUTPUT_FILE")" && pwd))
    OUTPUT_FILENAME=$(basename "$OUTPUT_FILE")
    OUTPUT_ABS="$OUTPUT_DIR/$OUTPUT_FILENAME"
fi

# Build Docker command
DOCKER_CMD=(
    docker run
    --rm
    --platform linux/amd64
)

# Handle input: stdin or file
if [ "$INPUT_FILE" = "-" ]; then
    # Reading from stdin
    DOCKER_CMD+=(-i)  # Interactive mode for stdin
    DOCKER_CMD+=(-e "INPUT=-")
else
    # Reading from file
    INPUT_ABS=$(realpath "$INPUT_FILE")

    # Check if input file exists
    if [ ! -f "$INPUT_ABS" ]; then
        echo "Error: Input file does not exist: $INPUT_FILE" >&2
        exit 1
    fi

    INPUT_DIR=$(dirname "$INPUT_ABS")
    INPUT_FILENAME=$(basename "$INPUT_ABS")

    # Mount input directory
    DOCKER_CMD+=(-v "$INPUT_DIR:/input:ro")
    DOCKER_CMD+=(-e "INPUT=/input/$INPUT_FILENAME")
fi

# Mount output directory if specified (writable)
if [ -n "$OUTPUT_FILE" ]; then
    DOCKER_CMD+=(-v "$OUTPUT_DIR:/output")
    DOCKER_CMD+=(-e "OUTPUT=/output/$OUTPUT_FILENAME")
else
    # No output to host - compile to temp location in container
    DOCKER_CMD+=(-e "OUTPUT=/tmp/build/output.obj")
fi

# Add compiler flags if provided
if [ -n "$COMPILER_FLAGS" ]; then
    DOCKER_CMD+=(-e "COMPILER_FLAGS=$COMPILER_FLAGS")
fi

# Add verbose flag if set
if [ -n "$VERBOSE" ]; then
    DOCKER_CMD+=(-e "VERBOSE=1")
fi

# Add image name
DOCKER_CMD+=("$IMAGE_NAME")

# Execute Docker
if [ -n "$VERBOSE" ]; then
    if [ "$INPUT_FILE" = "-" ]; then
        echo "Input: <stdin>"
    else
        echo "Input directory: $INPUT_DIR (mounted at /input)"
        echo "Input file: $INPUT_FILENAME"
    fi
    if [ -n "$OUTPUT_FILE" ]; then
        echo "Output directory: $OUTPUT_DIR (mounted at /output)"
        echo "Output file: $OUTPUT_FILENAME"
    else
        echo "Output: (not saved to host)"
    fi
    echo "Running Docker command..."
fi

"${DOCKER_CMD[@]}"
