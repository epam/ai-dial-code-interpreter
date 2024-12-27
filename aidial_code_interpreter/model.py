from pydantic import BaseModel

from aidial_code_interpreter.env import LOG_LEVEL


class ExecuteCodeRequest(BaseModel):
    code: str


class ExecuteCodeResponse(BaseModel):
    status: str
    stdout: str
    stderr: str
    result: object
    display: list[object]


class ListFilesRequest(BaseModel):
    comment: str | None = None  # to expect empty JSON in request body


class DownloadFileRequest(BaseModel):
    path: str


class LogConfig(BaseModel):
    version: int = 1
    disable_existing_loggers: bool = False
    formatters: dict[str, object] = {
        "default": {
            "()": "uvicorn.logging.DefaultFormatter",
            "fmt": "%(levelprefix)s | %(asctime)s.%(msecs)03d | %(name)s | %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
            "use_colors": False,
        },
    }
    handlers: dict[str, object] = {
        "default": {
            "formatter": "default",
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stdout",
        },
    }
    loggers: dict[str, object] = {
        "interpreter": {"handlers": ["default"], "level": LOG_LEVEL},
        "uvicorn": {
            "handlers": ["default"],
            "propagate": False,
        },
    }
