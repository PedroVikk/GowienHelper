"""Integração: upload de material, listagem, e impacto no quiz por tema."""


def _subject(client, headers):
    return client.post(
        "/api/v1/subjects",
        headers=headers,
        json={"name": "Psicologia", "color": "#8B7CF6"},
    ).json()["id"]


def test_upload_extracts_text(client, auth_headers):
    sid = _subject(client, auth_headers)
    r = client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=auth_headers,
        files={"file": ("aula.txt", b"O behaviorismo estuda o comportamento.", "text/plain")},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    # 'extracted' sem RAG; 'processed' quando Ollama+Chroma indexam
    assert body["status"] in ("extracted", "processed")
    assert body["file_type"] == "txt"
    assert body["text_length"] > 0

    # aparece na listagem
    r = client.get(f"/api/v1/subjects/{sid}/materials", headers=auth_headers)
    assert r.json()["total"] == 1


def test_unsupported_format_rejected(client, auth_headers):
    sid = _subject(client, auth_headers)
    r = client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=auth_headers,
        files={"file": ("video.mp4", b"xxxx", "video/mp4")},
    )
    assert r.status_code == 422


def test_material_changes_quiz_source_to_material(client, auth_headers):
    sid = _subject(client, auth_headers)
    # sem material -> general
    r = client.post(
        f"/api/v1/subjects/{sid}/quiz/themed",
        headers=auth_headers,
        json={"theme": "Behaviorismo", "count": 1},
    )
    assert r.json()["source"] == "general"

    # envia material -> agora deve usar o material
    client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=auth_headers,
        files={"file": ("aula.txt", b"Conteudo sobre behaviorismo e Skinner.", "text/plain")},
    )
    r = client.post(
        f"/api/v1/subjects/{sid}/quiz/themed",
        headers=auth_headers,
        json={"theme": "Behaviorismo", "count": 1},
    )
    assert r.json()["source"] == "material"


def test_delete_material(client, auth_headers):
    sid = _subject(client, auth_headers)
    mid = client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=auth_headers,
        files={"file": ("a.txt", b"texto", "text/plain")},
    ).json()["id"]
    assert client.delete(
        f"/api/v1/subjects/{sid}/materials/{mid}", headers=auth_headers
    ).status_code == 204
    assert client.get(
        f"/api/v1/subjects/{sid}/materials", headers=auth_headers
    ).json()["total"] == 0
