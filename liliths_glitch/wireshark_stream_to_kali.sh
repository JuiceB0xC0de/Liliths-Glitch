#!/bin/bash

# Wireshark Live Capture + Stream to Kali
# Captures WiFi traffic on Mac and streams it to Kali Linux VM via ngrok

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🔥 WiFi Packet Capture -> Kali Streamer 🔥  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
CAPTURE_DIR="$HOME/wireshark_captures"
KALI_NGROK_URL="${KALI_NGROK_URL:-}"  # Set this to your ngrok URL

# Find WiFi interface
echo -e "${BLUE}[1/5]${NC} ${YELLOW}Detecting WiFi interface...${NC}"
WIFI_INTERFACE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

if [ -z "$WIFI_INTERFACE" ]; then
    echo -e "${RED}❌ Could not find WiFi interface!${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Found: $WIFI_INTERFACE"

# Check tshark
echo -e "${BLUE}[2/5]${NC} ${YELLOW}Checking for tshark...${NC}"
if ! command -v tshark &> /dev/null; then
    echo -e "${RED}❌ tshark not found!${NC}"
    echo "Install Wireshark: brew install wireshark"
    exit 1
fi
echo -e "${GREEN}✓${NC} tshark found"

# Check permissions
echo -e "${BLUE}[3/5]${NC} ${YELLOW}Checking capture permissions...${NC}"
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script needs sudo privileges${NC}"
    echo "Run with: sudo $0"
    exit 1
fi
echo -e "${GREEN}✓${NC} Running as root"

# Create capture directory
echo -e "${BLUE}[4/5]${NC} ${YELLOW}Setting up capture directory...${NC}"
mkdir -p "$CAPTURE_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PCAP_FILE="$CAPTURE_DIR/capture_${TIMESTAMP}.pcap"
echo -e "${GREEN}✓${NC} Ready: $PCAP_FILE"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    echo -e "${GREEN}✓ Capture completed and saved${NC}"
    echo -e "${BLUE}View with:${NC} wireshark $PCAP_FILE"
    
    # If streaming was enabled, show stats
    if [ -n "$KALI_NGROK_URL" ]; then
        if [ -f "$PCAP_FILE" ]; then
            SIZE=$(du -h "$PCAP_FILE" | cut -f1)
            echo -e "${GREEN}✓ File size:${NC} $SIZE"
            echo -e "${BLUE}Check Kali:${NC} curl $KALI_NGROK_URL/api/pcap/list"
        fi
    fi
}
trap cleanup EXIT

# Show configuration
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              CAPTURE CONFIGURATION             ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC} Interface:  ${YELLOW}$WIFI_INTERFACE${NC}"
echo -e "${GREEN}║${NC} PCAP File:  ${YELLOW}$PCAP_FILE${NC}"
echo -e "${GREEN}║${NC} Streaming:  ${YELLOW}$([[ -n "$KALI_NGROK_URL" ]] && echo "ENABLED -> $KALI_NGROK_URL" || echo "LOCAL ONLY")${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}[5/5]${NC} ${GREEN}Starting capture...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# If Kali ngrok URL is set, stream the capture
if [ -n "$KALI_NGROK_URL" ]; then
    echo -e "${BLUE}Mode:${NC} ${GREEN}Capture + Stream to Kali${NC}"
    echo ""
    
    # Capture to file and simultaneously stream to Kali
    # Using tee to write to both file and curl
    tshark -i "$WIFI_INTERFACE" -w - 2>/dev/null | tee "$PCAP_FILE" | \
    curl -X POST \
         -H "Content-Type: application/octet-stream" \
         --data-binary @- \
         --no-buffer \
         "$KALI_NGROK_URL/api/pcap/stream" &
    
    # Wait for tshark (runs in background due to pipe)
    wait
else
    # Just capture locally without streaming
    echo -e "${BLUE}Mode:${NC} ${YELLOW}Local capture only (no streaming)${NC}"
    echo ""
    tshark -i "$WIFI_INTERFACE" -w "$PCAP_FILE"
fi
