import os
from pathlib import Path

UPLOAD_MAX_SIZE = int(os.environ.get("UPLOAD_MAX_SIZE", 512 * 1024 * 1024))
DOWNLOAD_CHUNK_SIZE = int(os.environ.get("DOWNLOAD_CHUNK_SIZE", 8 * 1024))
MOUNT_FOLDER = str(Path(os.environ.get("MOUNT_FOLDER", "mount")).resolve())
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
