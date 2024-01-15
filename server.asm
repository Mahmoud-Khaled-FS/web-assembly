format ELF64 executable

;; syscalls
SYS_READ equ 0
SYS_WRITE equ 1
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_EXIT equ 60
SYS_SOCKET equ 41
SYS_ACCEPT equ 43
SYS_BIND equ 49
SYS_LISTEN equ 50
;; constant
STDIN equ 1
STDERR equ 2
AF_INIT equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0
MAX_CONN equ 6
; PORT equ 53764
PORT equ 47115
REQUEST_CAP equ 128*1024
FILE_CAP equ 1024*1024

;; macros
macro print msg, length
{
  mov rax, SYS_WRITE
  mov rdi, STDIN
  mov rsi, msg
  mov rdx, length
  syscall
}

macro write fileid, msg, length
{
  mov rax, SYS_WRITE
  mov rdi, fileid
  mov rsi, msg
  mov rdx, length
  syscall
}

macro read fd, buf, size
{
  mov rax, SYS_READ
  mov rdi, fd
  mov rsi, buf
  mov rdx, size
  syscall
}

macro open filename, flag
{
  mov rax, SYS_OPEN
  mov rdi, filename
  mov rsi, flag
  syscall
}

macro exit code
{
  mov rax, SYS_EXIT
  mov rdi, code
  syscall
}

macro socket domian, type, protocol
{
  mov rax, SYS_SOCKET
  mov rdi, domian
  mov rsi, type
  mov rdx, protocol
  syscall
}

macro bind socket_id, addr, addrlen
{
  mov rax, SYS_BIND
  mov rdi, socket_id
  mov rsi, addr
  mov rdx, addrlen
  syscall
}

macro listen socket_id, max
{
  mov rax, SYS_LISTEN
  mov rdi, socket_id
  mov rsi, max
  syscall
}

macro accept socket_id, addr, addr_len
{
  mov rax, SYS_ACCEPT
  mov rdi, socket_id
  mov rsi, addr
  mov rdx, addr_len
  syscall
}

macro close file_id
{
  mov rax, SYS_CLOSE
  mov rdi, file_id
  syscall
}

macro route request_cur, request_len, index_route, index_route_len, handler
{
  mov rdi, [request_cur]
  mov rsi, [request_len]
  mov rdx, index_route
  mov r10, index_route_len
  call starts_with
  cmp rax, 0
  jg handler
}

macro serve_file file_path
{
  open file_path, 0
  cmp rax, 0
  jl error
  mov [html_fd], rax
  
  mov rdi, file_content
  mov rcx, FILE_CAP
  xor al, al
  rep stosb

  read [html_fd], file_content, FILE_CAP
  mov [file_len], rax
  close [html_fd]
  write [conn_id], response, response_length
  write [conn_id], file_content, file_len
  close [conn_id]
  jmp handler
}
;; struct macro
struc servaddr_in
{
  .sin_family dw 0
  .sin_port dw 0
  .sin_addr dd 0
  .sin_zero dq 0
}

;; entry point
segment readable executable
entry main
main:
  print start_msg, start_msg_length

  print create_socket_msg, create_socket_msg_length
  socket AF_INIT, SOCK_STREAM, 0
  cmp rax, 0
  jl error
  mov qword [socket_id], rax

  print start_binding_msg, start_binding_msg_length
  mov word [servaddr.sin_family], AF_INIT
  mov dword [servaddr.sin_addr], INADDR_ANY
  mov word [servaddr.sin_port], PORT
  bind [socket_id], servaddr.sin_family, sizeof_servaddr
  cmp rax, 0
  jl error

  print start_listen_msg, start_listen_msg_length
  listen [socket_id], MAX_CONN
  cmp rax, 0
  jne error

handler:
  print accept_msg, accept_msg_length
  accept [socket_id], clientaddr.sin_family, clientaddr_length
  cmp rax, 0
  jl error
  mov [conn_id], rax

  ;; read request
  print read_request_msg, read_request_msg_length
  read [conn_id], request, REQUEST_CAP
  cmp rax, 0
  jl error
  mov [request_len], rax

  mov [request_cur], request
  route request_cur, request_len, index_route, index_route_len, .serve_index_page
  route request_cur, request_len, about_route, about_route_len, .serve_about_page
  
  jmp .serve_not_found_page

  close [socket_id]
  print done_msg, done_msg_length
  exit 0

.serve_index_page:
  serve_file index_path

.serve_about_page:
  serve_file about_path

.serve_not_found_page:
  serve_file not_found_path

starts_with:
  xor rax, rax
  xor rbx, rbx
.next_char:
  cmp rsi, 0
  jle .done
  cmp r10,0
  jle .done
  mov al, byte [rdi]
  mov bl, byte [rdx]
  cmp rax, rbx
  jne .done

  dec rsi
  inc rdi
  dec r10
  inc rdx
  jmp .next_char

.done:
  cmp r10, 0
  je .yes
.no:
  mov rax, 0
  ret
.yes:
  mov rax, 1
  ret
error: 
  write STDERR, error_msg, error_msg_length
  close [socket_id]
  close [conn_id]
  close [html_fd]
  exit 1

;; data
segment readable writable
start_msg db "INFO: Starting Web Server...", 10
start_msg_length = $ - start_msg
error_msg db "ERROR! ", 10
error_msg_length = $ - error_msg
done_msg db "INFO: DONE", 10
done_msg_length = $ - done_msg
create_socket_msg db "INFO: Creating a socket...", 10
create_socket_msg_length = $ - create_socket_msg
start_binding_msg db "INFO: binding the socket...", 10
start_binding_msg_length = $ - start_binding_msg
start_listen_msg db "INFO: listen the socket on port:1234", 10
start_listen_msg_length = $ - start_listen_msg
accept_msg db "INFO: wating for client connection!", 10
accept_msg_length = $ - accept_msg
read_request_msg db "INFO: Read the request", 10
read_request_msg_length = $ - read_request_msg

;; Socket data
socket_id dq -1
servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family

;; connection data
conn_id dq -1
clientaddr servaddr_in
clientaddr_length dd sizeof_servaddr

;; request data
request rd REQUEST_CAP
request_len rq 1
request_cur rq 1

;; response data
response db "HTTP/1.1 200 OK", 13, 10 
  db "Content-Type: text/html", 13, 10
  db "Connection: Keep-Alive", 13, 10
response_length = $ - response

;; html file
file_content rd FILE_CAP
file_len rq 1
index_path db "index.html", 0
about_path db "about.html", 0
not_found_path db "not_found.html", 0
html_fd dq -1
index_route db "GET / "
index_route_len = $ - index_route
about_route db "GET /about "
about_route_len = $ - about_route