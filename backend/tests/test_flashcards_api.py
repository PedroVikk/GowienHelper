"""Integração: flashcards (CRUD manual, favoritar, filtros, revisão SM-2)."""


def _subject(client, headers):
    return client.post(
        "/api/v1/subjects", headers=headers, json={"name": "Bio"}
    ).json()["id"]


def _create_card(client, headers, sid, front="F", back="B"):
    return client.post(
        f"/api/v1/subjects/{sid}/flashcards",
        headers=headers,
        json={"front": front, "back": back},
    )


def test_create_manual_flashcard(client, auth_headers):
    sid = _subject(client, auth_headers)
    r = _create_card(client, auth_headers, sid)
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["is_manual"] is True and body["repetitions"] == 0


def test_edit_and_favorite(client, auth_headers):
    sid = _subject(client, auth_headers)
    cid = _create_card(client, auth_headers, sid).json()["id"]
    r = client.patch(
        f"/api/v1/flashcards/{cid}",
        headers=auth_headers,
        json={"back": "novo verso", "is_favorite": True},
    )
    assert r.status_code == 200
    assert r.json()["back"] == "novo verso" and r.json()["is_favorite"] is True


def test_filter_favorites(client, auth_headers):
    sid = _subject(client, auth_headers)
    c1 = _create_card(client, auth_headers, sid, "a").json()["id"]
    _create_card(client, auth_headers, sid, "b")
    client.patch(
        f"/api/v1/flashcards/{c1}", headers=auth_headers, json={"is_favorite": True}
    )
    r = client.get(
        f"/api/v1/subjects/{sid}/flashcards?favorites_only=true", headers=auth_headers
    )
    assert len(r.json()) == 1


def test_review_advances_schedule(client, auth_headers):
    sid = _subject(client, auth_headers)
    cid = _create_card(client, auth_headers, sid).json()["id"]
    r1 = client.post(
        f"/api/v1/flashcards/{cid}/review", headers=auth_headers, json={"quality": 5}
    )
    assert r1.status_code == 200
    assert r1.json()["repetitions"] == 1 and r1.json()["due_date"] is not None
    r2 = client.post(
        f"/api/v1/flashcards/{cid}/review", headers=auth_headers, json={"quality": 5}
    )
    assert r2.json()["interval_days"] == 6


def test_delete_flashcard(client, auth_headers):
    sid = _subject(client, auth_headers)
    cid = _create_card(client, auth_headers, sid).json()["id"]
    assert client.delete(
        f"/api/v1/flashcards/{cid}", headers=auth_headers
    ).status_code == 204


def test_other_user_cannot_edit(client, auth_headers):
    sid = _subject(client, auth_headers)
    cid = _create_card(client, auth_headers, sid).json()["id"]
    client.post(
        "/api/v1/auth/register",
        json={"name": "Bob", "email": "bob@test.com", "password": "secret123"},
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "bob@test.com", "password": "secret123"},
    ).json()["access_token"]
    r = client.patch(
        f"/api/v1/flashcards/{cid}",
        headers={"Authorization": f"Bearer {token}"},
        json={"front": "hack"},
    )
    assert r.status_code == 404
