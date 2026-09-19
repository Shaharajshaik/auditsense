from flask import Flask, render_template, jsonify, request
import json
from pathlib import Path

app = Flask(__name__)

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BASE_DIR / "sample_data" / "sample_cases.json"


def load_cases():
    with DATA_FILE.open("r", encoding="utf-8") as fh:
        return json.load(fh)["cases"]


@app.route("/")
def index():
    cases = load_cases()
    return render_template("index.html", cases=cases)


@app.route("/api/cases")
def get_cases():
    return jsonify(load_cases())


@app.route("/api/analyze", methods=["POST"])
def analyze_case():
    payload = request.get_json(silent=True) or {}
    case_id = payload.get("case_id", "CASE-001")
    document_text = payload.get("document_text", "")

    finding = "No material issue detected."
    if "does not match" in document_text.lower() or "discrepancy" in document_text.lower():
        finding = "Potential mismatch between supporting document and ledger entry. Review for accuracy and approval."

    return jsonify(
        {
            "case_id": case_id,
            "status": "draft",
            "finding": finding,
            "summary": "AI draft prepared for human review before publication.",
        }
    )
