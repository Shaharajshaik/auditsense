from app import app


def test_home_page():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert b"AuditSense" in response.data


def test_cases_api():
    client = app.test_client()
    response = client.get("/api/cases")
    assert response.status_code == 200
    payload = response.get_json()
    assert len(payload) >= 1
    assert "case_id" in payload[0]


def test_analysis_api():
    client = app.test_client()
    response = client.post(
        "/api/analyze",
        json={
            "case_id": "CASE-001",
            "document_text": "Invoice total does not match ledger amount by $2,500.",
        },
    )
    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "draft"
    assert "finding" in payload
