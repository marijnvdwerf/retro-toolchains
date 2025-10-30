# MSVC 6.0 Compiler with Wibo (Docker)

This Docker setup allows you to compile C/C++ code using Microsoft Visual C++ 6.0 compiler through Wibo on any platform.

## Architecture

The Docker image is built for **x86_64/amd64** architecture and combines:
- **MSVC 6.0 Compiler** from `ghcr.io/decompme/compilers/win32/msvc6.0:latest`
- **Wibo** (Windows binary runner) from `ghcr.io/decompals/wibo:latest`

## Quick Start

### 1. Build the Docker Image

```bash
docker build --platform linux/amd64 -t msvc6-compiler .
```

### 2. Compile a File

Using the wrapper script (recommended):

```bash
chmod +x compile.sh
./compile.sh -i path/to/source.c [-o path/to/output.obj] [COMPILER_FLAGS...]
```

### Examples

Basic compilation:
```bash
./compile.sh -i src/main.c -o build/main.obj
```

Syntax check only (no output to host):
```bash
./compile.sh -i src/main.c /O2 /W3
```

With optimization flags:
```bash
./compile.sh -i src/main.c -o build/main.obj /O2 /W3
```

With verbose output:
```bash
./compile.sh -i src/main.c -o build/main.obj /O2 -v
```

Reading from stdin:
```bash
cat src/main.c | ./compile.sh -i - -o build/main.obj /O2
```

Piping preprocessed code:
```bash
echo "#include <stdio.h>\nint main() { return 0; }" | ./compile.sh -i - -o test.obj
```

Check syntax from stdin:
```bash
cat src/main.c | ./compile.sh -i - /W4
```

## Wrapper Script Options

- `-i, --input FILE` - Source file to compile (use `-` for stdin, required)
- `-o, --output FILE` - Output object file (optional, omit for syntax check only)
- `-v, --verbose` - Show full CL.EXE command
- `-h, --help` - Show help message

Any additional arguments are passed directly to CL.EXE as compiler flags.

## Manual Docker Usage

If you prefer to use Docker directly:

From file:
```bash
docker run --rm \
  --platform linux/amd64 \
  -v "/path/to/source:/input:ro" \
  -v "/path/to/output:/output" \
  -e "INPUT=/input/source.c" \
  -e "OUTPUT=/output/output.obj" \
  -e "COMPILER_FLAGS=/O2 /W3" \
  msvc6-compiler
```

From stdin:
```bash
cat source.c | docker run --rm -i \
  --platform linux/amd64 \
  -v "/path/to/output:/output" \
  -e "INPUT=-" \
  -e "OUTPUT=/output/output.obj" \
  -e "COMPILER_FLAGS=/O2 /W3" \
  msvc6-compiler
```

## Common MSVC 6.0 Compiler Flags

- `/O1` - Minimize space
- `/O2` - Maximize speed
- `/Od` - Disable optimization
- `/W0` to `/W4` - Warning level (0=none, 4=all)
- `/WX` - Treat warnings as errors
- `/Zi` - Generate debug information
- `/MT` - Static link CRT
- `/MD` - Dynamic link CRT
- `/D<name>=<value>` - Define preprocessor macro

## How It Works

1. **Path Resolution**: The wrapper script resolves absolute paths for input/output files
2. **Separate Mounts**: Mounts input directory as `/input` (read-only) and output directory as `/output` (writable)
3. **Stdin Support**: When using `-i -`, the container reads from stdin and saves to a temporary file
4. **Path Mapping**: Maps paths to the Z: drive format required by Wibo
5. **Compilation**: Runs the command internally as:
   ```
   wibo /compiler/Bin/CL.EXE /c /nologo \
     /I"Z:/compiler/Include/" \
     [COMPILER_FLAGS] \
     /Fd"Z:/tmp/build/" \
     /Fo"Z:[OUTPUT]" \
     "Z:[INPUT]"
   ```

## Container Structure

- `/compiler/` - MSVC 6.0 installation (Bin/, Include/, etc.)
- `/usr/local/sbin/wibo` - Wibo executable
- `/tmp/build/` - Temporary compilation files
- `/input/` - Mount point for source files (read-only)
- `/output/` - Mount point for output files (writable)

## Troubleshooting

### Platform Warning
If you see a platform mismatch warning on Apple Silicon (arm64), this is expected and can be ignored. The container runs via Rosetta emulation.

### Stdin Not Working
When using `-i -`, ensure you're piping data into the script. The container needs to receive input via stdin.

### Compilation Errors
Use `-v` flag to see the full CL.EXE command being executed for debugging.

## Requirements

- Docker with platform emulation support (e.g., Rosetta 2 on macOS)
- Bash (for the wrapper script)

## License

This setup uses:
- MSVC 6.0: Microsoft proprietary license
- Wibo: MIT License
