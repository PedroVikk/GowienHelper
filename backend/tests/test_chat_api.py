"""Integração: chat por disciplina (RAG, regra de grounding, histórico)."""


def _subject(client, headers, with_material=False):
    sid = client.post(
        "/api/v1/subjects", headers=headers, json={"name": "Psicologia"}
    ).json()["id"]
    if with_material:
        client.post(
            f"/api/v1/subjects/{sid}/materials",
            headers=headers,
            files={"file": ("aula.txt", b"O condicionamento classico foi estudado por Pavlov.", "text/plain")},
        )
    return sid


def test_chat_grounded_with_material(client, auth_headers):
    sid = _subject(client, auth_headers, with_material=True)
    r = client.post(
        f"/api/v1/subjects/{sid}/chat",
        headers=auth_headers,
        json={"question": "Quem estudou o condicionamento clássico?"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["grounded"] is True
    assert "não está presente" not in body["answer"]


def test_chat_refuses_without_material(client, auth_headers):
    sid = _subject(client, auth_headers, with_material=False)
    r = client.post(
        f"/api/v1/subjects/{sid}/chat",
        headers=auth_headers,
        json={"question": "O que é a teoria de Freud?"},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["grounded"] is False
    assert body["answer"] == "Essa informação não está presente no material enviado."


def test_chat_persists_history(client, auth_headers):
    sid = _subject(client, auth_headers, with_material=True)
    client.post(
        f"/api/v1/subjects/{sid}/chat",
        headers=auth_headers,
        json={"question": "Pergunta 1?"},
    )
    r = client.get(f"/api/v1/subjects/{sid}/chat", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["total"] == 2  # user + assistant
    assert body["items"][0]["role"] == "user"
    assert body["items"][1]["role"] == "assistant"


def test_chat_clear_history(client, auth_headers):
    sid = _subject(client, auth_headers, with_material=True)
    client.post(
        f"/api/v1/subjects/{sid}/chat",
        headers=auth_headers,
        json={"question": "P?"},
    )
    assert client.delete(
        f"/api/v1/subjects/{sid}/chat", headers=auth_headers
    ).status_code == 204
    assert client.get(
        f"/api/v1/subjects/{sid}/chat", headers=auth_headers
    ).json()["total"] == 0


def test_chat_other_user_blocked(client, auth_headers):
    sid = _subject(client, auth_headers, with_material=True)
    client.post(
        "/api/v1/auth/register",
        json={"name": "Bob", "email": "bob@test.com", "password": "secret123"},
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "bob@test.com", "password": "secret123"},
    ).json()["access_token"]
    r = client.post(
        f"/api/v1/subjects/{sid}/chat",
        headers={"Authorization": f"Bearer {token}"},
        json={"question": "oi"},
    )
    assert r.status_code == 404
