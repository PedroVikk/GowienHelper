"""Painel web da IA (control panel). Servido em GET /ai, sem autenticação
(uso local). Mostra status do modelo, métricas de uso e histórico de chamadas
a partir da tabela ai_logs. Auto-atualiza a cada 5s."""
import httpx
from fastapi import APIRouter
from fastapi.responses import HTMLResponse
from sqlalchemy import case, func, select

from app.core.config import settings
from app.core.database import SessionLocal
from app.infrastructure.db.models.ai_log import AiLog

router = APIRouter(tags=["Painel IA"])

_OP_LABEL = {
    "summary": "Resumo",
    "flashcards": "Flashcards",
    "quiz": "Quiz",
    "themed_quiz": "Quiz por tema",
    "mindmap": "Mapa mental",
    "answer": "Resposta (RAG)",
    "correct": "Correção",
    "embed": "Embeddings",
}


async def _ollama_status() -> dict:
    info = {"online": False, "loaded": [], "models": []}
    try:
        async with httpx.AsyncClient(timeout=4.0) as c:
            tags = (await c.get(f"{settings.ollama_base_url}/api/tags")).json()
            info["models"] = [m["name"] for m in tags.get("models", [])]
            info["online"] = True
            ps = (await c.get(f"{settings.ollama_base_url}/api/ps")).json()
            info["loaded"] = [m["name"] for m in ps.get("models", [])]
    except Exception:  # noqa: BLE001
        pass
    return info


def _usage() -> dict:
    with SessionLocal() as db:
        total = db.scalar(select(func.count()).select_from(AiLog)) or 0
        ok = db.scalar(
            select(func.count()).select_from(AiLog).where(AiLog.ok.is_(True))
        ) or 0
        avg = db.scalar(select(func.avg(AiLog.duration_ms))) or 0
        by_op = db.execute(
            select(
                AiLog.operation,
                func.count().label("n"),
                func.avg(AiLog.duration_ms).label("avg"),
                func.sum(case((AiLog.ok.is_(False), 1), else_=0)).label("fail"),
            ).group_by(AiLog.operation).order_by(func.count().desc())
        ).all()
        recent = db.execute(
            select(AiLog).order_by(AiLog.id.desc()).limit(25)
        ).scalars().all()
        return {
            "total": total,
            "ok": ok,
            "avg_ms": int(avg),
            "by_op": [
                {"op": r.operation, "n": r.n, "avg": int(r.avg or 0),
                 "fail": int(r.fail or 0)}
                for r in by_op
            ],
            "recent": [
                {"op": r.operation, "ms": r.duration_ms, "ok": r.ok,
                 "chars": r.chars_out,
                 "at": r.created_at.strftime("%H:%M:%S") if r.created_at else ""}
                for r in recent
            ],
        }


@router.get("/ai/usage", summary="Métricas de uso da IA (JSON)")
async def ai_usage() -> dict:
    return {
        "provider": settings.ai_provider,
        "model": settings.ollama_model,
        "embed_model": settings.ollama_embed_model,
        "ollama": await _ollama_status(),
        "usage": _usage(),
    }


@router.get("/ai", response_class=HTMLResponse, summary="Painel web da IA")
async def ai_panel() -> str:
    oll = await _ollama_status()
    u = _usage()
    online = oll["online"]
    loaded = ", ".join(oll["loaded"]) or "nenhum carregado"
    rate = (u["ok"] / u["total"] * 100) if u["total"] else 0

    badge = (lambda on, t: f'<span class="b {"on" if on else "off"}">{t}</span>')

    op_rows = "".join(
        f"<tr><td>{_OP_LABEL.get(r['op'], r['op'])}</td><td>{r['n']}</td>"
        f"<td>{r['avg']} ms</td>"
        f"<td>{'<span class=fail>'+str(r['fail'])+'</span>' if r['fail'] else '0'}</td></tr>"
        for r in u["by_op"]
    ) or '<tr><td colspan=4 class=dim>Nenhuma chamada ainda</td></tr>'

    recent_rows = "".join(
        f"<tr><td>{r['at']}</td><td>{_OP_LABEL.get(r['op'], r['op'])}</td>"
        f"<td>{r['ms']} ms</td><td>{r['chars']}</td>"
        f"<td>{'✅' if r['ok'] else '❌'}</td></tr>"
        for r in u["recent"]
    ) or '<tr><td colspan=5 class=dim>Sem histórico</td></tr>'

    return f"""<!doctype html><html lang=pt-br><head>
<meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<meta http-equiv=refresh content=5>
<title>Painel da IA · GowienHelper</title>
<style>
  :root{{color-scheme:dark}}
  *{{box-sizing:border-box}}
  body{{margin:0;background:#0F1115;color:#ECEDEE;font:15px/1.5 system-ui,Segoe UI,Roboto,sans-serif}}
  .wrap{{max-width:920px;margin:0 auto;padding:24px}}
  h1{{font-size:22px;margin:0 0 4px}} .sub{{color:#9BA1A6;margin:0 0 20px}}
  .grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin:18px 0}}
  .card{{background:#1E2128;border:1px solid #2A2E37;border-radius:16px;padding:16px}}
  .card .k{{color:#9BA1A6;font-size:12px}} .card .v{{font-size:26px;font-weight:800;margin-top:4px}}
  .b{{display:inline-block;padding:4px 10px;border-radius:999px;font-size:12px;font-weight:700;margin-right:6px}}
  .b.on{{background:rgba(52,211,153,.16);color:#34D399}} .b.off{{background:rgba(248,113,113,.16);color:#F87171}}
  table{{width:100%;border-collapse:collapse;background:#1E2128;border:1px solid #2A2E37;border-radius:16px;overflow:hidden;margin:10px 0 22px}}
  th,td{{text-align:left;padding:10px 14px;border-bottom:1px solid #23262E;font-size:14px}}
  th{{color:#9BA1A6;font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.5px}}
  tr:last-child td{{border-bottom:none}}
  .dim{{color:#6B7280}} .fail{{color:#F87171;font-weight:700}}
  .pill{{font-size:13px;color:#9BA1A6}}
  .accent{{background:linear-gradient(135deg,#8B7CF6,#22D3EE);-webkit-background-clip:text;background-clip:text;color:transparent}}
</style></head><body><div class=wrap>
  <h1>Painel da <span class=accent>IA</span></h1>
  <p class=sub>GowienHelper · atualiza a cada 5s</p>

  <div>
    {badge(online, 'Ollama ONLINE' if online else 'Ollama OFFLINE')}
    <span class=b on style="background:rgba(139,124,246,.16);color:#A78BFA">{settings.ollama_model}</span>
    <span class=pill>embeddings: {settings.ollama_embed_model}</span>
  </div>
  <p class=pill style="margin-top:8px">Carregado na memória agora: <b>{loaded}</b></p>

  <div class=grid>
    <div class=card><div class=k>Chamadas totais</div><div class=v>{u['total']}</div></div>
    <div class=card><div class=k>Taxa de sucesso</div><div class=v>{rate:.0f}%</div></div>
    <div class=card><div class=k>Tempo médio</div><div class=v>{u['avg_ms']}<span style="font-size:14px"> ms</span></div></div>
  </div>

  <h3>Uso por tipo</h3>
  <table><tr><th>Operação</th><th>Chamadas</th><th>Tempo médio</th><th>Falhas</th></tr>{op_rows}</table>

  <h3>Histórico recente</h3>
  <table><tr><th>Hora</th><th>Operação</th><th>Duração</th><th>Chars</th><th>OK</th></tr>{recent_rows}</table>

  <p class=pill>API completa: <a href="/docs" style="color:#8B7CF6">/docs</a> · JSON: <a href="/ai/usage" style="color:#8B7CF6">/ai/usage</a></p>
</div></body></html>"""
