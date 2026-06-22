"""Painel de controle rápido (CLI): status da IA + conteúdo do banco.

Uso (a partir de backend/):
    .venv\\Scripts\\python scripts\\status.py
"""
import sqlite3
import sys
from pathlib import Path

import httpx

# Permite importar app.* rodando de dentro de backend/
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.core.config import settings  # noqa: E402


def _bar(title: str) -> None:
    print("\n" + "=" * 52)
    print(f"  {title}")
    print("=" * 52)


def ai_status() -> None:
    _bar("IA (Ollama)")
    print(f"  Provedor : {settings.ai_provider}")
    print(f"  Modelo   : {settings.ollama_model}")
    print(f"  Embed    : {settings.ollama_embed_model}")
    print(f"  Endpoint : {settings.ollama_base_url}")
    try:
        r = httpx.get(f"{settings.ollama_base_url}/api/tags", timeout=5)
        names = [m["name"] for m in r.json().get("models", [])]
        print(f"  Online   : SIM  | modelos baixados: {', '.join(names) or '-'}")
        ps = httpx.get(f"{settings.ollama_base_url}/api/ps", timeout=5).json()
        loaded = [m["name"] for m in ps.get("models", [])]
        print(f"  Carregado: {', '.join(loaded) if loaded else '(nenhum no momento)'}")
    except Exception as e:  # noqa: BLE001
        print(f"  Online   : NAO ({e})")


def db_status() -> None:
    _bar("BANCO DE DADOS")
    url = settings.database_url
    if not url.startswith("sqlite"):
        print(f"  (banco {url} — use um cliente próprio)")
        return
    db_path = url.split("///")[-1]
    full = (Path(__file__).resolve().parents[1] / db_path).resolve()
    if not full.exists():
        print(f"  Banco ainda não criado em {full}")
        return
    con = sqlite3.connect(str(full))
    con.row_factory = sqlite3.Row
    cur = con.cursor()
    tables = [
        r[0]
        for r in cur.execute(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
    ]
    print(f"  Arquivo: {full}\n")
    for t in tables:
        n = cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        print(f"    {t:18} {n}")

    print("\n  -- Usuários --")
    for r in cur.execute("SELECT id,name,email,xp,level,streak FROM users"):
        print(
            f"    #{r['id']} {r['name']} <{r['email']}> "
            f"XP={r['xp']} Nv={r['level']} streak={r['streak']}"
        )
    print("\n  -- Disciplinas --")
    for r in cur.execute(
        "SELECT s.id, s.name, u.name AS owner, "
        "(SELECT COUNT(*) FROM materials m WHERE m.subject_id=s.id) AS mats, "
        "(SELECT COUNT(*) FROM flashcards f WHERE f.subject_id=s.id) AS cards "
        "FROM subjects s JOIN users u ON u.id=s.user_id"
    ):
        print(
            f"    #{r['id']} {r['name']} (de {r['owner']}) "
            f"— {r['mats']} materiais, {r['cards']} flashcards"
        )
    con.close()


if __name__ == "__main__":
    print("\nGowienHelper — painel de controle")
    ai_status()
    db_status()
    print("\nDica: API completa em http://localhost:8000/docs\n")
