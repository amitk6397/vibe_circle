from fastapi import File, UploadFile

from app.common.dependencies import CurrentUser
from app.modules.uploads import service


async def upload(_: CurrentUser, file: UploadFile = File(...)):
    return await service.save_upload(file)

