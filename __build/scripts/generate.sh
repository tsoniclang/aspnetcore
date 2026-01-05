#!/bin/bash
# Generate TypeScript declarations for Microsoft.AspNetCore.* from the ASP.NET Core shared framework.
#
# Prerequisites:
#   - .NET 10 SDK installed
#   - tsbindgen repository cloned at ../tsbindgen (sibling directory)
#   - @tsonic/dotnet cloned at ../dotnet (sibling directory)
#   - @tsonic/microsoft-extensions cloned at ../microsoft-extensions (sibling directory)
#
# Usage:
#   ./__build/scripts/generate.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TSBINDGEN_DIR="$PROJECT_DIR/../tsbindgen"
DOTNET_LIB="$PROJECT_DIR/../dotnet"
EXT_LIB="$PROJECT_DIR/../microsoft-extensions"

DOTNET_VERSION="${DOTNET_VERSION:-10.0.1}"
DOTNET_HOME="${DOTNET_HOME:-$HOME/.dotnet}"
NETCORE_RUNTIME_PATH="$DOTNET_HOME/shared/Microsoft.NETCore.App/$DOTNET_VERSION"
ASPNET_RUNTIME_PATH="$DOTNET_HOME/shared/Microsoft.AspNetCore.App/$DOTNET_VERSION"

echo "================================================================"
echo "Generating Microsoft.AspNetCore.* TypeScript Declarations"
echo "================================================================"
echo ""
echo "Configuration:"
echo "  .NET Runtime:      $NETCORE_RUNTIME_PATH"
echo "  ASP.NET Runtime:   $ASPNET_RUNTIME_PATH"
echo "  BCL Library:       $DOTNET_LIB (external reference)"
echo "  Extensions Library:$EXT_LIB (external reference)"
echo "  tsbindgen:         $TSBINDGEN_DIR"
echo "  Output:            $PROJECT_DIR"
echo "  Naming:            JS (camelCase)"
echo ""

# Verify prerequisites
if [ ! -d "$NETCORE_RUNTIME_PATH" ]; then
    echo "ERROR: .NET runtime not found at $NETCORE_RUNTIME_PATH"
    echo "Set DOTNET_HOME or DOTNET_VERSION environment variables"
    exit 1
fi

if [ ! -d "$ASPNET_RUNTIME_PATH" ]; then
    echo "ERROR: ASP.NET runtime not found at $ASPNET_RUNTIME_PATH"
    echo "Set DOTNET_HOME or DOTNET_VERSION environment variables"
    exit 1
fi

if [ ! -d "$TSBINDGEN_DIR" ]; then
    echo "ERROR: tsbindgen not found at $TSBINDGEN_DIR"
    echo "Clone it: git clone https://github.com/tsoniclang/tsbindgen ../tsbindgen"
    exit 1
fi

if [ ! -d "$DOTNET_LIB" ]; then
    echo "ERROR: @tsonic/dotnet not found at $DOTNET_LIB"
    echo "Clone it: git clone https://github.com/tsoniclang/dotnet ../dotnet"
    exit 1
fi

if [ ! -d "$EXT_LIB" ]; then
    echo "ERROR: @tsonic/microsoft-extensions not found at $EXT_LIB"
    echo "Clone it: git clone https://github.com/tsoniclang/microsoft-extensions ../microsoft-extensions"
    exit 1
fi

# Clean output directory (keep config files)
echo "[1/3] Cleaning output directory..."
cd "$PROJECT_DIR"

# Remove all namespace directories (but keep config files, __build, node_modules, .git)
find . -maxdepth 1 -type d \
    ! -name '.' \
    ! -name '.git' \
    ! -name '.tests' \
    ! -name 'node_modules' \
    ! -name '__build' \
    -exec rm -rf {} \; 2>/dev/null || true

# Remove generated files at root
rm -f *.d.ts *.js families.json 2>/dev/null || true
rm -rf __internal Internal internal 2>/dev/null || true

echo "  Done"

# Build tsbindgen
echo "[2/3] Building tsbindgen..."
cd "$TSBINDGEN_DIR"
dotnet build src/tsbindgen/tsbindgen.csproj -c Release --verbosity quiet
echo "  Done"

echo "[3/3] Generating TypeScript declarations..."

ASPNET_DLLS=( "$ASPNET_RUNTIME_PATH"/Microsoft.AspNetCore*.dll )
if [ ! -f "${ASPNET_DLLS[0]}" ]; then
    echo "ERROR: No Microsoft.AspNetCore*.dll assemblies found at $ASPNET_RUNTIME_PATH"
    exit 1
fi

GEN_ARGS=()
for dll in "${ASPNET_DLLS[@]}"; do
    GEN_ARGS+=( -a "$dll" )
done

# Additional shared-framework assemblies that are part of Microsoft.AspNetCore.App but not under Microsoft.AspNetCore.*
EXTRA_DLLS=( \
    "$ASPNET_RUNTIME_PATH"/Microsoft.JSInterop.dll \
    "$ASPNET_RUNTIME_PATH"/Microsoft.Net.Http.Headers.dll \
    "$ASPNET_RUNTIME_PATH"/Microsoft.Extensions.Features.dll \
    "$ASPNET_RUNTIME_PATH"/Microsoft.Extensions.Identity.Core.dll \
    "$ASPNET_RUNTIME_PATH"/Microsoft.Extensions.Identity.Stores.dll \
)

for dll in "${EXTRA_DLLS[@]}"; do
    if [ -f "$dll" ]; then
        GEN_ARGS+=( -a "$dll" )
    fi
done

dotnet run --project src/tsbindgen/tsbindgen.csproj --no-build -c Release -- \
    generate "${GEN_ARGS[@]}" -d "$NETCORE_RUNTIME_PATH" -o "$PROJECT_DIR" \
    --lib "$DOTNET_LIB" \
    --lib "$EXT_LIB" \
    --naming js

echo ""
echo "================================================================"
echo "Generation Complete"
echo "================================================================"
