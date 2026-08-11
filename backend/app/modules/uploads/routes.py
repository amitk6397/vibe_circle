from fastapi import APIRouter

from app.modules.uploads import controller
from app.modules.uploads.dtos import UploadResult


router = APIRouter(prefix="/uploads", tags=["uploads"])
router.add_api_route("", controller.upload, methods=["POST"], response_model=UploadResult, status_code=201)

