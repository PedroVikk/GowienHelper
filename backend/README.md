# GowienHelper — Backend

API do app de estudos com IA local (Ollama / Qwen3 8B), em **Clean Architecture**.

## Arquitetura

```
Flutter → FastAPI → AIProvider (interface) → Ollama | OpenAI | Anthropic | Gemini
```

Toda a aplicação conversa apenas com a interface `AIProvider`
([app/domain/ai/ai_provider.py](app/domain/ai/ai_provider.py)). Trocar de
provedor = adicionar uma implementação e registrá-la na factory
([app/infrastructure/ai/factory.py](app/infrastructure/ai/factory.py)).

### Camadas

| Camada | Pasta | Responsabilidade |
|--------|-------|------------------|
| **Domain** | `app/domain` | Entidades, interfaces (portas), value objects de IA. Sem framework. |
| **Application** | `app/application` | Casos de uso e DTOs. Orquestra o domínio. |
| **Infrastructure** | `app/infrastructure` | ORM, repositórios, providers de IA, vetores. |
| **Presentation** | `app/presentation` | Rotas FastAPI, injeção de dependências. |

Cada feature segue o mesmo molde: Entity → Repository (interface) →
Datasource/Repo (impl) → UseCase → DTO → Router.

## Subir a infraestrutura

```bash
docker compose up -d            # PostgreSQL + ChromaDB + Ollama
docker exec -it gowien-ollama ollama pull qwen3:8b
docker exec -it gowien-ollama ollama pull nomic-embed-text
```

## Rodar a API

```bash
cd backend
python -m venv .venv && source .venv/Scripts/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
```

- Swagger: http://localhost:8000/docs
- Health:  http://localhost:8000/api/v1/health

## Testes

```bash
pytest
```

## Status (etapas)

- [x] **1. Fundação** — Clean Architecture, models, `AIProvider`+`OllamaProvider`, Auth (JWT), Swagger
- [x] **2. Disciplinas** — CRUD com paginação e ownership + **quiz por tema** (híbrido material/IA, 3 dificuldades, anti-drift)
- [x] **3. Upload + extração** — PDF/DOCX/TXT/MD/Imagem(OCR), strategy por tipo, status, alimenta o contexto do quiz
- [x] **4. RAG** — chunking + embeddings (Ollama) + ChromaDB (`IVectorStore`), indexação no upload, contexto do quiz por busca de trechos com **fallback** resiliente
- [x] **5. Geração IA** — resumo (curto/completo/tópicos/glossário/fórmulas), mapa mental (Markdown), flashcards e quiz do material (persistidos)
- [x] **6. Chat RAG** — chat por disciplina, responde só pelo material (regra de ouro), histórico em `messages`
- [x] **7. Flashcards / Quiz / Simulado** — CRUD manual + favoritar, repetição espaçada (SM-2), responder quiz (correção objetiva/IA), simulado (10/20/50/100, mistura, sem vazar gabarito)
- [x] **8. Estatísticas + Gamificação** — overview (acerto/tempo/XP/nível/streak), por disciplina (mais difíceis), evolução diária, conquistas; XP ganho ao responder
- [ ] 9. Frontend Flutter

**Backend: 8/8 etapas concluídas — 32 rotas, 98 testes passando.**
