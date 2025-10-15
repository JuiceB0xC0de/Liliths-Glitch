from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/scan")
def scan():
    return jsonify([
        {"ssid": "TestNetwork1", "rssi": -42},
        {"ssid": "TestNetwork2", "rssi": -70}
    ])

app.run(host="0.0.0.0", port=62183)
