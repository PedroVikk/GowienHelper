"""Estratégias de extração de texto, uma por tipo de arquivo (SOLID/OCP).

Adicionar um novo formato = criar um TextExtractor e registrá-lo no serviço,
sem alterar os demais.
"""
from abc import ABC, abstractmethod
from pathlib import Path

from loguru import logger


class TextExtractor(ABC):
    """Estratégia de extração para uma ou mais categorias de arquivo."""

    file_types: tuple[str, ...] = ()

    def can_handle(self, file_type: str) -> bool:
        return file_type in self.file_types

    @abstractmethod
    def extract(self, file_path: str) -> str: ...


class PlainTextExtractor(TextExtractor):
    file_types = ("txt", "md")

    def extract(self, file_path: str) -> str:
        return Path(file_path).read_text(encoding="utf-8", errors="ignore")


class PdfExtractor(TextExtractor):
    file_types = ("pdf",)

    def extract(self, file_path: str) -> str:
        from pypdf import PdfReader

        reader = PdfReader(file_path)
        parts = [(page.extract_text() or "") for page in reader.pages]
        return "\n".join(parts).strip()


class DocxExtractor(TextExtractor):
    file_types = ("docx",)

    def extract(self, file_path: str) -> str:
        from docx import Document

        doc = Document(file_path)
        return "\n".join(p.text for p in doc.paragraphs).strip()


class ImageOcrExtractor(TextExtractor):
    file_types = ("image",)

    def extract(self, file_path: str) -> str:
        try:
            import pytesseract
            from PIL import Image
        except ImportError:  # pragma: no cover
            logger.warning("OCR indisponível: pillow/pytesseract não instalados")
            return ""
        try:
            with Image.open(file_path) as img:
                # 'por+eng' cobre material de faculdade em português e inglês
                return pytesseract.image_to_string(img, lang="por+eng").strip()
        except pytesseract.TesseractNotFoundError:  # pragma: no cover
            logger.warning(
                "Binário do Tesseract não encontrado; OCR retornará vazio. "
                "Instale o Tesseract OCR no sistema."
            )
            return ""
