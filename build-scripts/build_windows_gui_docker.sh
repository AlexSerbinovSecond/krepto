#!/bin/bash

# Krepto Windows Bitcoin Qt GUI Build using Docker
# Native Windows build in Docker container

set -e

echo "🚀 Krepto Windows Bitcoin Qt GUI Build - Docker Approach"
echo "========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="$(pwd)"
DOCKER_DIR="$BUILD_DIR/docker-windows-build"
OUTPUT_DIR="$BUILD_DIR/docker-output"

echo -e "${BLUE}Configuration:${NC}"
echo "  Build directory: $BUILD_DIR"
echo "  Docker directory: $DOCKER_DIR"
echo "  Output directory: $OUTPUT_DIR"

# Step 1: Check Docker availability
echo -e "\n${YELLOW}Step 1: Checking Docker availability...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker Desktop.${NC}"
    echo "Download from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is available and running${NC}"

# Step 2: Check Windows container support
echo -e "\n${YELLOW}Step 2: Checking Windows container support...${NC}"

# Switch to Windows containers if on Windows
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Switching to Windows containers..."
    docker version --format '{{.Server.Os}}' | grep -q windows || {
        echo -e "${YELLOW}Switching Docker to Windows containers...${NC}"
        # This requires Docker Desktop on Windows
        powershell -Command "& 'C:\Program Files\Docker\Docker\DockerCli.exe' -SwitchDaemon"
    }
else
    echo -e "${YELLOW}Note: Building Windows containers on macOS/Linux${NC}"
    echo "This requires Docker Desktop with experimental features enabled"
fi

# Step 3: Prepare Docker build context
echo -e "\n${YELLOW}Step 3: Preparing Docker build context...${NC}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy source code to Docker context (excluding large directories)
echo "Copying source code to Docker context..."
rsync -av --exclude='.git' --exclude='depends/built' --exclude='depends/work' \
    --exclude='src/.deps' --exclude='*.o' --exclude='*.exe' \
    "$BUILD_DIR/" "$DOCKER_DIR/krepto/"

echo -e "${GREEN}✅ Docker context prepared${NC}"

# Step 4: Build Docker image
echo -e "\n${YELLOW}Step 4: Building Docker image...${NC}"
echo "This may take 30-60 minutes for the first build..."

cd "$DOCKER_DIR"

if ! docker build -t krepto-windows-builder .; then
    echo -e "${RED}❌ Docker image build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image built successfully${NC}"

# Step 5: Run build in container
echo -e "\n${YELLOW}Step 5: Running build in Windows container...${NC}"
echo "This may take 30-60 minutes..."

# Run the container with volume mounts
docker run --rm \
    -v "$OUTPUT_DIR:/host-output" \
    krepto-windows-builder \
    powershell -Command "
        # Run the build
        C:\build\build-windows-gui.ps1
        
        # Copy output to host
        if (Test-Path 'C:\build\Krepto-Windows-GUI-Native.zip') {
            Copy-Item 'C:\build\Krepto-Windows-GUI-Native.zip' '/host-output/'
            Copy-Item 'C:\build\output\*' '/host-output/' -Recurse -Force
            Write-Host 'Build artifacts copied to host' -ForegroundColor Green
        } else {
            Write-Error 'Build failed - no output package found'
            exit 1
        }
    "

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Container build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Container build completed${NC}"

# Step 6: Verify output
echo -e "\n${YELLOW}Step 6: Verifying build output...${NC}"

if [ -f "$OUTPUT_DIR/Krepto-Windows-GUI-Native.zip" ]; then
    echo -e "${GREEN}✅ Windows GUI package created successfully!${NC}"
    
    # Calculate checksums
    cd "$OUTPUT_DIR"
    ZIP_SIZE=$(du -h "Krepto-Windows-GUI-Native.zip" | cut -f1)
    SHA256=$(shasum -a 256 "Krepto-Windows-GUI-Native.zip" | cut -d' ' -f1)
    MD5=$(md5 -q "Krepto-Windows-GUI-Native.zip")
    
    echo -e "\n${GREEN}🎉 Windows Bitcoin Qt GUI Build Complete!${NC}"
    echo "=============================================="
    echo -e "${BLUE}Package:${NC} Krepto-Windows-GUI-Native.zip"
    echo -e "${BLUE}Size:${NC} $ZIP_SIZE"
    echo -e "${BLUE}SHA256:${NC} $SHA256"
    echo -e "${BLUE}MD5:${NC} $MD5"
    
    echo -e "\n${BLUE}Files in package:${NC}"
    if command -v unzip &> /dev/null; then
        unzip -l "Krepto-Windows-GUI-Native.zip" | head -20
    else
        echo "Use 'unzip -l Krepto-Windows-GUI-Native.zip' to see contents"
    fi
    
    echo -e "\n${GREEN}✅ Ready for Windows deployment!${NC}"
    echo -e "${YELLOW}Location: $OUTPUT_DIR/Krepto-Windows-GUI-Native.zip${NC}"
    
else
    echo -e "${RED}❌ Build failed - no output package found${NC}"
    echo "Check Docker logs for errors"
    exit 1
fi

# Step 7: Cleanup (optional)
echo -e "\n${YELLOW}Step 7: Cleanup...${NC}"
read -p "Remove Docker build context? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$DOCKER_DIR/krepto"
    echo -e "${GREEN}✅ Build context cleaned${NC}"
fi

echo -e "\n${BLUE}Docker Windows build process completed.${NC}"
echo -e "${GREEN}🎊 Krepto Windows Bitcoin Qt GUI is ready!${NC}" 