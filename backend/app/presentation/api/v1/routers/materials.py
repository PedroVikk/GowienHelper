"""Rotas de materiais (upload, listagem, remoção)."""
from app.application.dtos.material import MaterialList, MaterialResponse
from app.application.use_cases.material import (
    DeleteMaterialUseCase,
    ListMaterialsUseCase,
    UploadMaterialUseCase,
)
from app.domain.entities.material import MaterialEntity
from app.presentation.api.deps import (
    CurrentUser,
    ExtractionDep,
    FileStorageDep,
    IndexerDep,
    MaterialRepo,
    SubjectRepo,
)
from fastapi import APIRouter, File, UploadFile, status

router = APIRouter(prefix="/subjects/{subject_id}/materials", tags=["Materiais"])


def _to_response(m: MaterialEntity) -> MaterialResponse:
    return MaterialResponse(
        id=m.id,
        filename=m.filename,
        file_type=m.file_type,
        status=m.status,
        text_length=len(m.extracted_text or ""),
    )


@router.post(
    "",
    response_model=MaterialResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Envia um material e extrai o texto automaticamente",
)
async def upload_material(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
    storage: FileStorageDep,
    extraction: ExtractionDep,
    indexer: IndexerDep,
    file: UploadFile = File(...),
) -> MaterialResponse:
    data = await file.read()
    material = await UploadMaterialUseCase(
        subjects, materials, storage, extraction, indexer
    ).execute(user.id, subject_id, file.filename or "arquivo", data)
    return _to_response(material)


@router.get("", response_model=MaterialList, summary="Lista materiais da disciplina")
def list_materials(
    subject_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
) -> MaterialList:
    items = ListMaterialsUseCase(subjects, materials).execute(user.id, subject_id)
    return MaterialList(
        items=[_to_response(m) for m in items], total=len(items)
    )


@router.delete(
    "/{material_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove um material",
)
async def delete_material(
    subject_id: int,
    material_id: int,
    user: CurrentUser,
    subjects: SubjectRepo,
    materials: MaterialRepo,
    storage: FileStorageDep,
    indexer: IndexerDep,
) -> None:
    await DeleteMaterialUseCase(subjects, materials, storage, indexer).execute(
        user.id, subject_id, material_id
    )
