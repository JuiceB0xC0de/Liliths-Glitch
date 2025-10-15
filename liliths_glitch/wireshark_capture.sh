#!/bin/bash

# Wireshark Live Capture Script for Mac -> Kali via ngrok
# This bad boy captures WiFi traffic and streams it to Kali

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔥 Wireshark Live Capture -> Kali via ngrok 🔥${NC}"
echo ""

# Find WiFi interface
echo -e "${YELLOW}Finding WiFi interface...${NC}"
WIFI_INTERFACE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

if [ -z "$WIFI_INTERFACE" ]; then
    echo -e "${RED}❌ Could not find WiFi interface!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found WiFi interface: $WIFI_INTERFACE${NC}"

# Check if tshark is installed
if ! command -v tshark &> /dev/null; then
    echo -e "${RED}❌ tshark not found! Is Wireshark installed?${NC}"
    echo "Install with: brew install wireshark"
    exit 1
fi

# Create capture directory
CAPTURE_DIR="$HOME/wireshark_captures"
mkdir -p "$CAPTURE_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PCAP_FILE="$CAPTURE_DIR/capture_${TIMESTAMP}.pcap"

echo -e "${GREEN}✓ Will save capture to: $PCAP_FILE${NC}"

# Check if we have permissions
echo -e "${YELLOW}Checking permissions...${NC}"
if ! tshark -D &> /dev/null; then
    echo -e "${RED}❌ Need sudo permissions for packet capture${NC}"
    echo "Run with: sudo $0"
    exit 1
fi

echo -e "${GREEN}✓ Permissions OK${NC}"

# Get Kali server endpoint from ngrok or use default
KALI_ENDPOINT="${KALI_ENDPOINT:-http://localhost:5000}"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}🎯 Starting capture on: $WIFI_INTERFACE${NC}"
echo -e "${GREEN}💾 Saving to: $PCAP_FILE${NC}"
echo -e "${GREEN}🚀 Kali endpoint: $KALI_ENDPOINT${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop capture${NC}"
echo ""

# Start tshark capture
# -i: interface
# -w: write to file
# -P: print packets while capturing
# -l: flush output after each packet (for live streaming)
sudo tshark -i "$WIFI_INTERFACE" -w "$PCAP_FILE" -P

echo ""
echo -e "${GREEN}✓ Capture saved to: $PCAP_FILE${NC}"
echo -e "${YELLOW}To view: wireshark $PCAP_FILE${NC}"
