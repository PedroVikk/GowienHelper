"""Armazenamento de arquivos em disco local (implementa IFileStorage)."""
import re
import time
import uuid
from pathlib import Path

from app.core.config import settings
from app.domain.services.file_storage import IFileStorage

_SAFE = re.compile(r"[^A-Za-z0-9._-]+")


def _safe_name(filename: str) -> str:
    name = _SAFE.sub("_", filename.strip()) or "arquivo"
    return name[-120:]  # evita nomes absurdamente longos


class LocalFileStorage(IFileStorage):
    """Salva os materiais em ``{storage_dir}/{subject_id}/`` no disco."""

    def __init__(self, base_dir: str | None = None) -> None:
        self._base = Path(base_dir or settings.storage_dir)

    def save(self, subject_id: int, filename: str, data: bytes) -> str:
        folder = self._base / str(subject_id)
        folder.mkdir(parents=True, exist_ok=True)
        unique = f"{int(time.time())}_{uuid.uuid4().hex[:8]}_{_safe_name(filename)}"
        path = folder / unique
        path.write_bytes(data)
        return str(path)

    def delete(self, path: str) -> None:
        try:
            Path(path).unlink(missing_ok=True)
        except OSError:
            pass
