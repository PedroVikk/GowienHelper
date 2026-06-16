"""Integração: estatísticas, XP e conquistas."""


def _subject_quiz(client, headers, name):
    sid = client.post(
        "/api/v1/subjects", headers=headers, json={"name": name}
    ).json()["id"]
    client.post(
        f"/api/v1/subjects/{sid}/materials",
        headers=headers,
        files={"file": ("a.txt", b"Conteudo de estudo.", "text/plain")},
    )
    quiz = client.post(
        f"/api/v1/subjects/{sid}/generate/quiz",
        headers=headers,
        json={"count": 3},
    ).json()
    return sid, [q["id"] for q in quiz["questions"]]


def _answer(client, headers, qid, value):
    return client.post(
        f"/api/v1/questions/{qid}/answer",
        headers=headers,
        json={"answer": value, "time_spent_seconds": 10},
    )


def test_overview_and_xp(client, auth_headers):
    _, qids = _subject_quiz(client, auth_headers, "Psicologia")
    _answer(client, auth_headers, qids[0], "a")  # correta
    _answer(client, auth_headers, qids[1], "z")  # errada

    r = client.get("/api/v1/stats/overview", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["questions_answered"] == 2
    assert body["correct_answers"] == 1
    assert body["accuracy"] == 0.5
    assert body["time_studied_seconds"] == 20
    assert body["xp"] == 12  # 10 (acerto) + 2 (erro)
    assert body["level"] == 1
    assert body["streak"] == 1


def test_by_subject_hardest_first(client, auth_headers):
    _, easy = _subject_quiz(client, auth_headers, "Fácil")
    _, hard = _subject_quiz(client, auth_headers, "Difícil")
    _answer(client, auth_headers, easy[0], "a")   # acerto -> accuracy 1.0
    _answer(client, auth_headers, hard[0], "x")   # erro   -> accuracy 0.0

    r = client.get("/api/v1/stats/by-subject", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert len(body) == 2
    assert body[0]["name"] == "Difícil"  # menor acurácia primeiro
    assert body[0]["accuracy"] == 0.0
    assert body[1]["accuracy"] == 1.0


def test_evolution(client, auth_headers):
    _, qids = _subject_quiz(client, auth_headers, "Bio")
    _answer(client, auth_headers, qids[0], "a")
    r = client.get("/api/v1/stats/evolution?days=7", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert len(body) == 1 and body[0]["answered"] == 1


def test_achievements_unlock(client, auth_headers):
    _, qids = _subject_quiz(client, auth_headers, "Quimica")
    _answer(client, auth_headers, qids[0], "a")
    r = client.get("/api/v1/stats/achievements", headers=auth_headers)
    assert r.status_code == 200
    by_code = {a["code"]: a for a in r.json()}
    assert by_code["first_answer"]["unlocked"] is True
    assert by_code["centurion"]["unlocked"] is False


def test_overview_empty_user(client, auth_headers):
    r = client.get("/api/v1/stats/overview", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["questions_answered"] == 0 and body["accuracy"] == 0.0
    assert body["streak"] == 0
