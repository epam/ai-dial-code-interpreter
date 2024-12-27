# AI-Dial Interpreter

AI-Dial Python Code Interpreter uses Jupiter Kernel to execute arbitrary python code.

## Developer environment

This project uses [Python>=3.11](https://www.python.org/downloads/) and [Poetry>=1.6.1](https://python-poetry.org/) as a
dependency manager.

Check out Poetry's [documentation on how to install it](https://python-poetry.org/docs/#installation) on your system
before proceeding.

To install requirements:

```
make install
```

This will install all requirements for running the package, linting and formatting.

### Make on Windows

As of now, Windows distributions do not include the make tool. To run make commands, the tool can be installed using
the following command (since [Windows 10](https://learn.microsoft.com/en-us/windows/package-manager/winget/)):

```sh
winget install GnuWin32.Make
```

For convenience, the tool folder can be added to the PATH environment variable as `C:\Program Files (x86)\GnuWin32\bin`.
The command definitions inside Makefile should be cross-platform to keep the development environment setup simple.

## Environment Variables

| Setting               | Default     | Description                                         |
|-----------------------|-------------|-----------------------------------------------------|
| `UPLOAD_MAX_SIZE`     | 512 MB      | The max size of a file when uploading a file.       |
| `DOWNLOAD_CHUNK_SIZE` | 8 KB        | The chunk size of a buffer when downloading a file. |
| `MOUNT_FOLDER`        | os.getcwd() | The folder where files are stored using API.        |
| `LOG_LEVEL`           | INFO        | The default log level for Interpreter.              |

## Lint

Run the linting before committing:

```sh
make lint
```

To auto-fix formatting issues run:

```sh
make format
```

## Clean

To remove the virtual environment and build artifacts:

```sh
make clean
```

## API
```sh
# execute code
curl -X POST http://localhost:8080/execute_code -d '{"code":"1+2"}' -H "content-type: application/json"
# upload file
curl -X POST http://0.0.0.0:8080/upload_file -F "file=@README.md"
# download file
curl -X POST http://0.0.0.0:8080/download_file -d '{"path":"README.md"}' -H "content-type: application/json"
# list files
curl -X POST http://localhost:8080/list_files -d '{}' -H "content-type: application/json"
```


## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for more details.