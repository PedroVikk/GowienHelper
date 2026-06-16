"""Entidade de domínio Material."""
from dataclasses import dataclass


@dataclass(slots=True)
class MaterialEntity:
    id: int | None
    subject_id: int
    filename: str
    file_type: str  # pdf | docx | txt | md | image
    file_path: str
    extracted_text: str | None = None
    status: str = "pending"  # pending | extracted | processed | failed
