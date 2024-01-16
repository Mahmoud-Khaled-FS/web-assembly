# WebServer in Assembly (FASM) for Linux x86-64

## Overview

This project is a simple web server written in Assembly language using FASM (Flat Assembler) for the Linux x86-64 architecture. The web server serves static files and handles basic HTTP requests. This project is intended for educational purposes and serves as a minimalistic example of a web server implemented in assembly language.

## Prerequisites

Before you can build and run the web server, make sure you have the following tools installed:

- **Flat Assembler (FASM)**: The assembler used for this project. You can download it from the [official website](https://flatassembler.net/).

- **Linux Operating System**: This project is specifically designed for Linux x86-64 architecture.

## Building the Web Server

1. Clone the repository to your local machine:

```bash
  git clone https://github.com/your-username/webserver-assembly.git
  cd webserver-assembly
```

1. Assemble the source code using FASM:

```bash
  fasm server.asm
```

This will generate an executable file named server.

## Running the Web Server

After successfully building the web server, you can run it from the command line. By default, the server listens on port 3000. You can specify a different port as a command-line argument.

```bash
  chmod +x ./server
  ./server
```

## Acknowledgments

Special thanks to [Tsoding](https://www.youtube.com/@TsodingDaily) for inspiring and educating with insightful content on low-level programming, assembly language, and systems development.
