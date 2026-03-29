from flask import Flask, request, jsonify

app = Flask(__name__)

# =========================
# RESET API (REQUIRED)
# =========================
@app.route("/reset", methods=["POST"])
def reset():
    return jsonify({
        "state": {"message": "reset successful"},
        "reward": 0,
        "done": False
    })

# =========================
# STEP API (REQUIRED)
# =========================
@app.route("/step", methods=["POST"])
def step():
    data = request.json

    return jsonify({
        "state": {"message": "step executed"},
        "reward": 1,
        "done": False
    })

# =========================
# HEALTH CHECK
# =========================
@app.route("/", methods=["GET"])
def home():
    return "API is running"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=7860)
