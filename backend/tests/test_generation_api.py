"""Integração: geração de resumo, mapa mental, flashcards e quiz do material."""


def _subject_with_material(client, headers):
    sid = client.post(
        "/api/v1/subjects", headers=headers, json={"name": "Psicologia"}
    ).json()["id"]
    client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=headers,
        files={"file": ("aula.txt", b"Conteudo sobre behaviorismo e cognicao.", "text/plain")},
    )
    return sid


def test_generate_summary(client, auth_headers):
    sid = _subject_with_material(client, auth_headers)
    r = client.post(f"/api/v1/subjects/{sid}/generate/summary", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["short"] and body["full"]
    assert body["topics"] and "termo" in body["glossary"]


def test_generate_mindmap(client, auth_headers):
    sid = _subject_with_material(client, auth_headers)
    r = client.post(f"/api/v1/subjects/{sid}/generate/mindmap", headers=auth_headers)
    assert r.status_code == 200
    assert r.json()["markdown"].startswith("#")


def test_generate_flashcards_persists(client, auth_headers):
    sid = _subject_with_material(client, auth_headers)
    r = client.post(
        f"/api/v1/subjects/{sid}/generate/flashcards",
        headers=auth_headers,
        json={"count": 5},
    )
    assert r.status_code == 200, r.text
    cards = r.json()
    assert len(cards) == 5
    assert all(c["id"] and c["front"] and c["back"] for c in cards)
    assert all(c["is_manual"] is False for c in cards)


def test_generate_quiz_persists(client, auth_headers):
    sid = _subject_with_material(client, auth_headers)
    r = client.post(
        f"/api/v1/subjects/{sid}/generate/quiz",
        headers=auth_headers,
        json={"count": 3},
    )
    assert r.status_code == 200, r.text
    quiz = r.json()
    assert quiz["id"] and len(quiz["questions"]) == 3
    q = quiz["questions"][0]
    assert q["explanation"] and q["options"]


def test_generate_without_material_returns_422(client, auth_headers):
    sid = client.post(
        "/api/v1/subjects", headers=auth_headers, json={"name": "Vazia"}
    ).json()["id"]
    r = client.post(f"/api/v1/subjects/{sid}/generate/summary", headers=auth_headers)
    assert r.status_code == 422


def test_generate_other_user_blocked(client, auth_headers):
    sid = _subject_with_material(client, auth_headers)
    client.post(
        "/api/v1/auth/register",
        json={"name": "Bob", "email": "bob@test.com", "password": "secret123"},
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "bob@test.com", "password": "secret123"},
    ).json()["access_token"]
    r = client.post(
        f"/api/v1/subjects/{sid}/generate/flashcards",
        headers={"Authorization": f"Bearer {token}"},
        json={"count": 3},
    )
    assert r.status_code == 404
