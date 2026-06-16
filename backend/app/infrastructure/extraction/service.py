"""Serviço de extração que despacha para a estratégia correta."""
from app.core.exceptions import ValidationError
from app.domain.services.text_extraction import ITextExtractionService
from app.infrastructure.extraction.extractors import (
    DocxExtractor,
    ImageOcrExtractor,
    PdfExtractor,
    PlainTextExtractor,
    TextExtractor,
)


class ExtractionService(ITextExtractionService):
    def __init__(self, extractors: list[TextExtractor] | None = None) -> None:
        self._extractors = extractors or [
            PlainTextExtractor(),
            PdfExtractor(),
            DocxExtractor(),
            ImageOcrExtractor(),
        ]

    def extract(self, file_path: str, file_type: str) -> str:
        for extractor in self._extractors:
            if extractor.can_handle(file_type):
                return extractor.extract(file_path)
        raise ValidationError(f"Tipo de arquivo não suportado: {file_type}")
