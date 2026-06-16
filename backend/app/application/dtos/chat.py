"""DTOs da feature de chat."""
from datetime import datetime

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    question: str = Field(min_length=1, max_length=2000)


class ChatAnswerResponse(BaseModel):
    answer: str
    grounded: bool  # False = informação não estava no material


class MessageResponse(BaseModel):
    id: int
    role: str
    content: str
    created_at: datetime | None


class ChatHistoryResponse(BaseModel):
    items: list[MessageResponse]
    total: int
