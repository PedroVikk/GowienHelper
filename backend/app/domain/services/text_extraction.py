"""Porta de extração de texto a partir de arquivos."""
from abc import ABC, abstractmethod

# Categorias de arquivo suportadas e o mapeamento de extensão -> categoria.
FILE_TYPE_BY_EXT: dict[str, str] = {
    ".pdf": "pdf",
    ".docx": "docx",
    ".txt": "txt",
    ".md": "md",
    ".markdown": "md",
    ".png": "image",
    ".jpg": "image",
    ".jpeg": "image",
    ".webp": "image",
    ".bmp": "image",
}


class ITextExtractionService(ABC):
    @abstractmethod
    def extract(self, file_path: str, file_type: str) -> str:
        """Extrai o texto do arquivo conforme a categoria (pdf/docx/txt/md/image)."""
