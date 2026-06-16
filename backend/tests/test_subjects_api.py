"""Testes de integração: CRUD de disciplinas e quiz por tema."""


def _create(client, headers, name="Psicologia"):
    return client.post(
        "/api/v1/subjects",
        headers=headers,
        json={"name": name, "color": "#8B7CF6", "icon": "psychology"},
    )


def test_subject_crud_flow(client, auth_headers):
    # create
    r = _create(client, auth_headers)
    assert r.status_code == 201, r.text
    sid = r.json()["id"]

    # list paginado
    r = client.get("/api/v1/subjects", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["total"] == 1 and len(body["items"]) == 1

    # get
    r = client.get(f"/api/v1/subjects/{sid}", headers=auth_headers)
    assert r.status_code == 200 and r.json()["name"] == "Psicologia"

    # patch
    r = client.patch(
        f"/api/v1/subjects/{sid}",
        headers=auth_headers,
        json={"professor": "Dr. Freud"},
    )
    assert r.status_code == 200 and r.json()["professor"] == "Dr. Freud"

    # delete
    assert client.delete(f"/api/v1/subjects/{sid}", headers=auth_headers).status_code == 204
    assert client.get(f"/api/v1/subjects/{sid}", headers=auth_headers).status_code == 404


def test_requires_auth(client):
    assert client.get("/api/v1/subjects").status_code == 401


def test_invalid_color_rejected(client, auth_headers):
    r = client.post(
        "/api/v1/subjects",
        headers=auth_headers,
        json={"name": "X", "color": "vermelho"},
    )
    assert r.status_code == 422


def test_themed_quiz_general_source(client, auth_headers):
    sid = _create(client, auth_headers).json()["id"]
    r = client.post(
        f"/api/v1/subjects/{sid}/quiz/themed",
        headers=auth_headers,
        json={"theme": "Behaviorismo", "count": 1, "difficulty": "hard"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["source"] == "general"  # sem material enviado
    assert body["theme"] == "Behaviorismo"
    assert len(body["questions"]) == 1
    assert body["questions"][0]["explanation"]


def test_themed_quiz_other_user_blocked(client, auth_headers):
    sid = _create(client, auth_headers).json()["id"]
    # outro usuário
    client.post(
        "/api/v1/auth/register",
        json={"name": "Bob", "email": "bob@test.com", "password": "secret123"},
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "bob@test.com", "password": "secret123"},
    ).json()["access_token"]
    r = client.post(
        f"/api/v1/subjects/{sid}/quiz/themed",
        headers={"Authorization": f"Bearer {token}"},
        json={"theme": "Freud"},
    )
    assert r.status_code == 404
