import os

UPLOAD_MAX_SIZE = int(os.environ.get("UPLOAD_MAX_SIZE", 512 * 1024 * 1024))
DOWNLOAD_CHUNK_SIZE = int(os.environ.get("DOWNLOAD_CHUNK_SIZE", 8 * 1024))
MOUNT_FOLDER = os.path.abspath(os.environ.get("MOUNT_FOLDER", os.getcwd()))
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
SESSION_ID = os.environ.get("SESSION_ID", None)
