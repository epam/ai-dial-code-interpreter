import logging.config
import os
import threading

import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile
from starlette.responses import StreamingResponse

from aidial_code_interpreter.env import (
    DOWNLOAD_CHUNK_SIZE,
    MOUNT_FOLDER,
    UPLOAD_MAX_SIZE,
)
from aidial_code_interpreter.interpreter import Interpreter
from aidial_code_interpreter.model import (
    DownloadFileRequest,
    ExecuteCodeRequest,
    ListFilesRequest,
    LogConfig,
)

logging.config.dictConfig(LogConfig().model_dump())
app = FastAPI()
interpreter = Interpreter()
lock = threading.Lock()
logging.getLogger("interpreter").info("Mount folder: " + MOUNT_FOLDER)


@app.get("/health")
def health_check():
    return {"status": "HEALTHY"}


@app.post("/execute_code")
def execute_code(request: ExecuteCodeRequest):
    with lock:
        return interpreter.execute(request)


@app.post("/upload_file")
def upload_file(file: UploadFile):
    path = resolve_path(file.filename)
    size = 0

    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as stream:
            while chunk := file.file.read():
                size += len(chunk)
                if size > UPLOAD_MAX_SIZE:
                    raise HTTPException(
                        status_code=413, detail="File too large"
                    )
                stream.write(chunk)
    except Exception:
        if os.path.exists(path):
            os.remove(path)
        raise

    return {"path": os.path.relpath(path, MOUNT_FOLDER), "size": size}


@app.post("/download_file")
def download_file(request: DownloadFileRequest):
    path = resolve_path(request.path)
    if not os.path.isfile(path):
        raise HTTPException(
            404, f"File not found: {os.path.relpath(path, MOUNT_FOLDER)}"
        )

    def read_file():
        with open(path, "rb") as stream:
            while chunk := stream.read(DOWNLOAD_CHUNK_SIZE):
                yield chunk

    return StreamingResponse(
        read_file(),
        headers={"Content-Length": f"{os.path.getsize(path)}"},
        media_type="application/octet-stream",
    )


@app.post("/list_files")
def list_files(request: ListFilesRequest):
    list = []
    for root, _, files in os.walk(MOUNT_FOLDER):
        for file in files:
            path = os.path.join(root, file)
            size = os.path.getsize(path)
            list.append(
                {"path": os.path.relpath(path, MOUNT_FOLDER), "size": size}
            )
    return {"files": list}


def resolve_path(path: str | None) -> str:
    if path is None:
        raise HTTPException(status_code=400, detail="Missing path")
    if not os.path.isabs(path):
        path = os.path.join(MOUNT_FOLDER, path)
    path = os.path.normpath(path)
    if not path.startswith(MOUNT_FOLDER):
        raise HTTPException(status_code=400, detail=f"Bad path: {path}")
    return path


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
