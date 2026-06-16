"""Testes da divisão de texto em chunks."""
import pytest

from app.infrastructure.rag.chunking import chunk_text


def test_empty_returns_no_chunks():
    assert chunk_text("") == []
    assert chunk_text("   ") == []


def test_short_text_single_chunk():
    text = "Texto curto sobre psicologia."
    assert chunk_text(text, chunk_size=1000) == [text]


def test_long_text_multiple_chunks_with_overlap():
    text = ". ".join(f"Frase número {i} sobre o tema" for i in range(200))
    chunks = chunk_text(text, chunk_size=300, overlap=50)
    assert len(chunks) > 1
    # cobertura: todo o conteúdo aparece em algum chunk
    joined = " ".join(chunks)
    assert "Frase número 0" in joined
    assert "Frase número 199" in joined


def test_overlap_must_be_smaller_than_size():
    with pytest.raises(ValueError):
        chunk_text("abc", chunk_size=100, overlap=100)


def test_progress_terminates():
    # texto sem separadores não pode entrar em loop infinito
    chunks = chunk_text("x" * 2500, chunk_size=1000, overlap=200)
    assert len(chunks) >= 3
