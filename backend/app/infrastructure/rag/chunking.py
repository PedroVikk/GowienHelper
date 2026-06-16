"""Divisão de texto em chunks para indexação (RAG). Puro, sem I/O."""

DEFAULT_CHUNK_SIZE = 1000
DEFAULT_OVERLAP = 150


def chunk_text(
    text: str,
    chunk_size: int = DEFAULT_CHUNK_SIZE,
    overlap: int = DEFAULT_OVERLAP,
) -> list[str]:
    """Quebra o texto em pedaços de ~chunk_size com sobreposição.

    Tenta cortar em fronteira de parágrafo/sentença próxima ao limite para não
    partir frases ao meio. A sobreposição preserva contexto entre chunks.
    """
    text = (text or "").strip()
    if not text:
        return []
    if overlap >= chunk_size:
        raise ValueError("overlap deve ser menor que chunk_size")

    chunks: list[str] = []
    start = 0
    n = len(text)

    while start < n:
        end = min(start + chunk_size, n)
        if end < n:
            window = text[start:end]
            # procura uma boa fronteira (parágrafo > linha > sentença) no fim
            for sep in ("\n\n", "\n", ". ", "? ", "! "):
                cut = window.rfind(sep)
                if cut != -1 and cut > chunk_size * 0.5:
                    end = start + cut + len(sep)
                    break

        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)

        if end >= n:
            break
        start = max(end - overlap, start + 1)

    return chunks
