; ========================================
; Comandos Built-in do Shell
; Implementa: cd, pwd, echo, help
; ========================================

%include "include/syscalls.inc"
%include "lib/io.inc"
%include "lib/string.inc"

; Declarar funções globais
global builtin_cd, builtin_pwd, builtin_echo, builtin_help

; ========================================
; Seção de dados
; ========================================
section .data
    ; Mensagens
    msg_pwd_error db "Erro ao obter diretório atual", NEWLINE, 0
    msg_echo_prefix db ""
    msg_help db "=== Mini Shell - Comandos Built-in ===", NEWLINE
             db "cd [caminho]   - Mudar de diretório", NEWLINE
             db "pwd            - Mostrar diretório atual", NEWLINE
             db "echo [texto]   - Imprimir texto", NEWLINE
             db "help           - Mostrar esta ajuda", NEWLINE
             db "exit           - Sair do shell", NEWLINE
             db "", NEWLINE
             db "Digite qualquer outro comando para executá-lo", NEWLINE
    msg_help_len equ $ - msg_help

; ========================================
; Seção de dados não inicializados
; ========================================
section .bss
    ; Buffer para armazenar o diretório atual (getcwd)
    cwd_buffer resb 256

; ========================================
; Seção de código
; ========================================
section .text

; ========================================
; Função: builtin_cd
; Muda o diretório atual (change directory)
; Parâmetros:
;   rdi = ponteiro para o caminho do diretório
; Retorno:
;   rax = 0 se sucesso, -1 se erro
; ========================================
builtin_cd:
    ; Se não houver argumento, mudar para home (usar ".")
    cmp rdi, 0
    je .use_home
    cmp byte [rdi], 0
    je .use_home

    ; Fazer syscall chdir com o caminho fornecido
    mov rax, SYS_CHDIR
    ; rdi já contém o endereço do caminho
    syscall
    
    ; Retornar resultado (0 = sucesso, negativo = erro)
    ret

.use_home:
    ; Mudar para o diretório home (.)
    mov rdi, home_dir
    mov rax, SYS_CHDIR
    syscall
    ret

; ========================================
; Função: builtin_pwd
; Imprime o diretório atual (print working directory)
; Parâmetros: nenhum
; Retorno: nada
; ========================================
builtin_pwd:
    push rbx
    push r12
    
    ; Chamar syscall getcwd
    ; rdi = buffer para armazenar caminho
    ; rsi = tamanho do buffer
    mov rdi, cwd_buffer
    mov rsi, 256
    mov rax, SYS_GETCWD
    syscall
    
    ; Verificar se houve erro
    cmp rax, 0
    jle .pwd_error
    
    ; Armazenar tamanho do caminho em r12
    mov r12, rax
    
    ; SYS_GETCWD retorna o tamanho incluindo o null terminator
    ; Então precisamos subtrair 1
    dec r12
    
    ; Imprimir o caminho
    mov rsi, cwd_buffer
    mov rdx, r12
    call print
    
    ; Imprimir quebra de linha
    mov rsi, newline
    mov rdx, 1
    call print
    
    pop r12
    pop rbx
    ret

.pwd_error:
    ; Imprimir mensagem de erro
    mov rsi, msg_pwd_error
    mov rdx, 34
    call print
    pop r12
    pop rbx
    ret

; ========================================
; Função: builtin_echo
; Imprime texto na saída padrão
; Parâmetros:
;   rdi = ponteiro para o texto
; Retorno: nada
; ========================================
builtin_echo:
    push rbx
    
    ; Se não houver argumento, apenas imprimir newline
    cmp rdi, 0
    je .echo_empty
    cmp byte [rdi], 0
    je .echo_empty
    
    ; Calcular tamanho da string
    mov rsi, rdi
    xor rdx, rdx
.echo_loop:
    cmp byte [rsi + rdx], 0
    je .echo_print
    inc rdx
    cmp rdx, 1024
    jl .echo_loop
    
.echo_print:
    ; Imprimir o texto
    mov rsi, rdi
    ; rdx já contém o tamanho
    call print
    
.echo_newline:
    ; Imprimir quebra de linha
    mov rsi, newline
    mov rdx, 1
    call print
    
    pop rbx
    ret

.echo_empty:
    jmp .echo_newline

; ========================================
; Função: builtin_help
; Exibe mensagem de ajuda
; Parâmetros: nenhum
; Retorno: nada
; ========================================
builtin_help:
    mov rsi, msg_help
    mov rdx, msg_help_len
    call print
    ret

; ========================================
; Seção de dados (continuação)
; ========================================
section .data
    home_dir db ".", 0
    newline db NEWLINE
