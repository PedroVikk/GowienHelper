"""Integração: responder quiz (correção), detalhar quiz e montar simulado."""


def _quiz_with_questions(client, headers, count=3):
    sid = client.post(
        "/api/v1/subjects", headers=headers, json={"name": "Psicologia"}
    ).json()["id"]
    client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=headers,
        files={"file": ("a.txt", b"Conteudo de estudo sobre o tema.", "text/plain")},
    )
    quiz = client.post(
        f"/api/v1/subjects/{sid}/generate/quiz",
        headers=headers,
        json={"count": count},
    ).json()
    return sid, quiz


def test_answer_correct_and_incorrect(client, auth_headers):
    _, quiz = _quiz_with_questions(client, auth_headers)
    qid = quiz["questions"][0]["id"]

    r = client.post(
        f"/api/v1/questions/{qid}/answer",
        headers=auth_headers,
        json={"answer": "a", "time_spent_seconds": 12},
    )
    assert r.status_code == 200, r.text
    assert r.json()["is_correct"] is True and r.json()["score"] == 1.0
    assert r.json()["feedback"]  # explicação

    r = client.post(
        f"/api/v1/questions/{qid}/answer",
        headers=auth_headers,
        json={"answer": "resposta errada"},
    )
    assert r.json()["is_correct"] is False and r.json()["score"] == 0.0


def test_get_quiz(client, auth_headers):
    _, quiz = _quiz_with_questions(client, auth_headers)
    r = client.get(f"/api/v1/quizzes/{quiz['id']}", headers=auth_headers)
    assert r.status_code == 200
    assert len(r.json()["questions"]) == 3


def test_answer_unknown_question_404(client, auth_headers):
    r = client.post(
        "/api/v1/questions/99999/answer",
        headers=auth_headers,
        json={"answer": "a"},
    )
    assert r.status_code == 404


def test_simulado_invalid_count(client, auth_headers):
    _quiz_with_questions(client, auth_headers)
    r = client.post(
        "/api/v1/simulados", headers=auth_headers, json={"count": 7}
    )
    assert r.status_code == 422


def test_simulado_without_questions(client, auth_headers):
    r = client.post(
        "/api/v1/simulados", headers=auth_headers, json={"count": 10}
    )
    assert r.status_code == 422


def test_simulado_mixes_questions(client, auth_headers):
    _quiz_with_questions(client, auth_headers, count=3)
    r = client.post(
        "/api/v1/simulados", headers=auth_headers, json={"count": 10}
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["total"] == 3  # só há 3 questões disponíveis
    q = body["questions"][0]
    assert "id" in q and "prompt" in q
    assert "correct_answer" not in q  # não vaza o gabarito


def test_answer_other_user_blocked(client, auth_headers):
    _, quiz = _quiz_with_questions(client, auth_headers)
    qid = quiz["questions"][0]["id"]
    client.post(
        "/api/v1/auth/register",
        json={"name": "Bob", "email": "bob@test.com", "password": "secret123"},
    )
    token = client.post(
        "/api/v1/auth/login",
        json={"email": "bob@test.com", "password": "secret123"},
    ).json()["access_token"]
    r = client.post(
        f"/api/v1/questions/{qid}/answer",
        headers={"Authorization": f"Bearer {token}"},
        json={"answer": "a"},
    )
    assert r.status_code == 404
