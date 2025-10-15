# 🔥 WiFi Packet Capture: Mac → Kali via ngrok 🔥

## The Problem Nobody Could Solve (Until Now)

Since 2011, people have been trying to get WiFi packet capture working in VMs. The issue? **Virtual machines can't directly access the host's WiFi adapter**. 

Everyone said "just buy a USB WiFi adapter" or "use a dongle". Fuck that.

## The Solution

We bypass the whole problem by:
1. **Capturing on macOS** (which HAS the WiFi adapter)
2. **Streaming through ngrok** (secure tunnel)
3. **Analyzing on Kali Linux VM** (all the pentesting tools)

**This is the first documented solution to stream live WiFi captures into a VM without hardware adapters.**

## Architecture

```
┌─────────────────┐
│   macOS Host    │
│                 │
│  ┌──────────┐   │      ┌──────────┐      ┌─────────────────┐
│  │ Wireshark│───┼─────▶│  ngrok   │─────▶│   Kali Linux    │
│  │ (tshark) │   │      │  Tunnel  │      │   (UTM VM)      │
│  └──────────┘   │      └──────────┘      │                 │
│                 │                         │  ┌──────────┐   │
│   WiFi: en0     │                         │  │ Analysis │   │
└─────────────────┘                         │  │  Server  │   │
                                            │  └──────────┘   │
                                            └─────────────────┘
```

## Setup

### Prerequisites

- macOS with Wireshark installed
- Kali Linux VM (UTM or any hypervisor)
- ngrok account and configured tunnels
- Python 3.x on Kali

### Step 1: Configure ngrok

Your `ngrok.yml` should have:
```yaml
version: 2
tunnels:
  demon1:
    proto: http
    addr: 5000
    domain: demon1.soulsyphonacademy.art
```

Start ngrok:
```bash
ngrok start demon1
```

### Step 2: Start Kali Server

On your Kali VM:
```bash
cd ~/MCP-Kali-Server
python3 kali_server.py --port 5000
```

The server will:
- Listen on port 5000
- Accept PCAP streams at `/api/pcap/stream`
- Store captures in `/tmp/pcap_captures`
- Provide analysis endpoints

### Step 3: Start Capturing on Mac

On your Mac:
```bash
# Make script executable (first time only)
chmod +x ~/scripts/wireshark_stream_to_kali.sh

# Start capture with streaming
sudo KALI_NGROK_URL="http://demon1.soulsyphonacademy.art" ~/scripts/wireshark_stream_to_kali.sh
```

## What Gets Captured

- **All WiFi traffic** on your Mac's interface
- **Saved locally** to `~/wireshark_captures/`
- **Streamed live** to Kali for real-time analysis
- **PCAP format** compatible with all analysis tools

## Kali API Endpoints

### PCAP Operations

**Stream PCAP Data**
```bash
POST /api/pcap/stream
Content-Type: application/octet-stream
Body: <binary PCAP data>
```

**Analyze PCAP**
```bash
POST /api/pcap/analyze
{
  "pcap_file": "/tmp/pcap_captures/capture_20241014_123456.pcap",
  "analysis_type": "summary|conversations|protocols|detailed|custom",
  "filter": "tcp.port == 443"  # Optional for custom analysis
}
```

**List Captures**
```bash
GET /api/pcap/list
```

### Example: Analyze Captured Traffic

```bash
# List available captures
curl http://demon1.soulsyphonacademy.art/api/pcap/list

# Analyze for HTTP traffic
curl -X POST http://demon1.soulsyphonacademy.art/api/pcap/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "pcap_file": "/tmp/pcap_captures/mac_capture_20241014_123456.pcap",
    "analysis_type": "custom",
    "filter": "http"
  }'

# Get protocol statistics
curl -X POST http://demon1.soulsyphonacademy.art/api/pcap/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "pcap_file": "/tmp/pcap_captures/mac_capture_20241014_123456.pcap",
    "analysis_type": "protocols"
  }'
```

## Permissions Setup

### macOS Permissions

Wireshark needs special permissions to capture packets:

```bash
# Option 1: Run with sudo (temporary)
sudo tshark -i en0 -w capture.pcap

# Option 2: Add ChmodBPF (permanent, survives reboots)
# This is installed with Wireshark and gives capture permissions
```

### Kali Permissions

Kali needs write access to capture directory:
```bash
mkdir -p /tmp/pcap_captures
chmod 755 /tmp/pcap_captures
```

## Advanced Usage

### Monitor Mode (Advanced)

If you want to capture ALL WiFi traffic (not just your own):

```bash
# Enable monitor mode on Mac (requires disabling WiFi)
sudo airport en0 sniff 1

# This creates a capture file at /tmp/airportSniff*.cap
```

### Filter Specific Traffic

Edit the capture script to add display filters:
```bash
sudo tshark -i en0 -f "tcp port 443" -w capture.pcap
```

### Real-Time Analysis

On Kali, you can analyze the stream as it arrives:
```bash
# Watch for new PCAP files and auto-analyze
watch -n 5 'ls -lth /tmp/pcap_captures/ | head -5'

# Auto-analyze newest capture
LATEST=$(ls -t /tmp/pcap_captures/*.pcap | head -1)
tshark -r "$LATEST" -q -z io,phs
```

## Troubleshooting

### "Permission denied" when capturing
- Run with `sudo`
- Check ChmodBPF is installed: `ls -la /Library/LaunchDaemons | grep ChmodBPF`

### "Interface not found"
- List interfaces: `tshark -D`
- Update script with correct interface name

### ngrok tunnel not working
- Check ngrok status: `curl http://localhost:4040/api/tunnels`
- Verify domain is correct in ngrok config

### Kali server not receiving data
- Check server is running: `curl http://demon1.soulsyphonacademy.art/health`
- Verify ngrok tunnel is forwarding to correct port

## Why This Is Revolutionary

1. **No Hardware Required** - No USB adapters, no dongles, no external devices
2. **Works with Any VM** - UTM, VirtualBox, VMware, anything
3. **Real-Time Analysis** - Stream and analyze simultaneously
4. **Full WiFi Access** - All the power of macOS WiFi stack
5. **Kali Tools** - Use every pentesting tool on live traffic

## Files

- `~/scripts/wireshark_stream_to_kali.sh` - Mac capture script
- `~/MCP-Kali-Server/kali_server.py` - Kali API server
- `~/wireshark_captures/` - Local PCAP storage on Mac
- `/tmp/pcap_captures/` - PCAP storage on Kali

## Credits

Built by someone who got tired of being told "just buy a dongle" 🖕

Inspired by 13+ years of "this is impossible" forum posts.

## License

MIT - Do whatever the fuck you want with it.

## Contributing

If you improve this, submit a PR. If you can't figure it out, RTFM.

---

**Made with rage and determination** 🔥
