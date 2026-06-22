# Imagem de produção do backend GowienHelper (IA na nuvem via Gemini).
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    APP_ENV=production

WORKDIR /app

# Instala dependências primeiro (melhor cache de camadas)
COPY requirements-cloud.txt .
RUN pip install --upgrade pip && pip install -r requirements-cloud.txt

# Copia o código da aplicação
COPY . .

# A plataforma (Render/Fly/HF) injeta a porta em $PORT; cai pra 8000 local.
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
