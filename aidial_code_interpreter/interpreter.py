import logging
import re
import time

import _queue
from jupyter_client.manager import KernelManager

from aidial_code_interpreter.model import (
    ExecuteCodeRequest,
    ExecuteCodeResponse,
)

ANSI_ESCAPE_PATTERN = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
LOG = logging.getLogger("interpreter")


def sanitize(text):
    return ANSI_ESCAPE_PATTERN.sub("", text)


class Interpreter:
    def __init__(self, timeout=60):
        self.timeout = timeout
        self.manager = None
        self.client = None
        self.start()

    def __del__(self):
        self.stop()

    def restart(self):
        LOG.warning("Restarting kernel")
        self.stop()
        self.start()

    def start(self):
        self.manager = KernelManager(kernel_name="python3")
        self.manager.start_kernel(
            extra_arguments=["--no-stdout", "--no-stderr"]
        )
        self.client = self.manager.client()
        self.client.start_channels()

    def stop(self):
        if self.manager is not None:
            self.manager.shutdown_kernel(now=True)
            self.manager = None
            self.client = None

    def execute(self, request: ExecuteCodeRequest) -> ExecuteCodeResponse:
        status = "SUCCESS"
        stdout = ""
        stderr = ""
        display = []
        result = ""

        LOG.info("Starting to executing code")

        try:
            deadline = time.time() + self.timeout
            timeout = self.timeout

            assert self.client is not None
            self.client.execute(request.code)
            message = self.client.get_shell_msg(timeout)
            LOG.info(f"Received shell message: {message}")

            while True:
                timeout = max(deadline - time.time(), 0.001)
                message = self.client.get_iopub_msg(timeout)
                message_type = message["msg_type"]
                message_content = message["content"]
                LOG.info(f"Received iopub message: {message}")

                if (
                    message_type == "status"
                    and message_content["execution_state"] == "idle"
                ):
                    break
                elif (
                    message_type == "stream"
                    and message_content["name"] == "stdout"
                ):
                    stdout += message_content["text"]
                elif (
                    message_type == "stream"
                    and message_content["name"] == "stderr"
                ):
                    stderr += message_content["text"]
                elif message_type == "execute_result":
                    result = message_content["data"]
                elif message_type == "display_data":
                    display.append(message_content["data"])
                elif message_type == "error":
                    status = "FAILURE"
                    stderr += "\n".join(message_content["traceback"])

            LOG.info("Succeeded to execute code")

        except Exception as e:
            if isinstance(e, _queue.Empty):
                LOG.warning("Failed to execute code: timeout")
            else:
                LOG.exception("Failed to execute code")
            status = "FAILURE"
            self.restart()

        return ExecuteCodeResponse(
            status=status,
            stdout=sanitize(stdout),
            stderr=sanitize(stderr),
            result=result,
            display=display,
        )
