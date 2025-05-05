import os
import aiofiles
from fastapi import UploadFile, HTTPException
from typing import Optional
from datetime import datetime

UPLOAD_DIR = "uploads"
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/gif"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

async def save_upload_file(upload_file: UploadFile, team_id: int, file_type: str) -> str:
    if not os.path.exists(UPLOAD_DIR):
        os.makedirs(UPLOAD_DIR)
    
    if upload_file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Invalid file type")
    
    # Check file size
    file_size = 0
    chunk_size = 1024
    while chunk := await upload_file.read(chunk_size):
        file_size += len(chunk)
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(status_code=400, detail="File too large")
    
    # Reset file pointer
    await upload_file.seek(0)
    
    # Generate unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_extension = os.path.splitext(upload_file.filename)[1]
    filename = f"{team_id}_{file_type}_{timestamp}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Save file
    async with aiofiles.open(file_path, 'wb') as out_file:
        content = await upload_file.read()
        await out_file.write(content)
    
    return f"/{UPLOAD_DIR}/{filename}"

async def delete_file(file_path: str) -> None:
    if os.path.exists(file_path):
        os.remove(file_path) 