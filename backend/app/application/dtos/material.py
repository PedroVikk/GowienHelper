"""DTOs da feature de materiais."""
from pydantic import BaseModel


class MaterialResponse(BaseModel):
    id: int
    filename: str
    file_type: str
    status: str  # pending | extracted | processed | failed
    text_length: int


class MaterialList(BaseModel):
    items: list[MaterialResponse]
    total: int
