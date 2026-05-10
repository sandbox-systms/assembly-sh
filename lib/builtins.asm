; ========================================
; Comandos Built-in do Shell
; Implementa: cd, pwd, echo, help
; ========================================

%include "include/syscalls.inc"
%include "lib/io.inc"
%include "lib/string.inc"

; Declarar funções globais
global builtin_cd, builtin_pwd, builtin_echo, builtin_help, builtin_clear, builtin_ls

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
             db "ls             - Listar arquivos com cores", NEWLINE
             db "clear          - Limpar a tela", NEWLINE
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
    
    ; Buffer para getdents
    dents_buffer resb 1024
    
    ; Buffer para stat
    stat_buf resb 144

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
; Função: builtin_clear
; Limpa a tela do terminal
; Parâmetros: nenhum
; Retorno: nada
; ========================================
builtin_clear:
    mov rsi, clear_seq
    mov rdx, clear_seq_len
    call print
    ret

; ========================================
; Função: builtin_ls
; Lista arquivos do diretório atual com cores
; Parâmetros: nenhum
; Retorno: nada
; ========================================
builtin_ls:
    push rbx
    push r12
    push r13
    
    ; Abrir diretório atual
    mov rax, SYS_OPEN
    mov rdi, dot
    mov rsi, O_RDONLY
    syscall
    cmp rax, 0
    jl .ls_error
    mov r12, rax  ; fd
    
    ; Ler entradas do diretório
    mov rdi, r12
    mov rsi, dents_buffer
    mov rdx, 1024
    mov rax, SYS_GETDENTS64
    syscall
    cmp rax, 0
    jl .ls_error
    mov r13, rax  ; total bytes
    
    ; Fechar fd
    mov rax, SYS_CLOSE
    mov rdi, r12
    syscall
    
    ; Processar entradas
    lea rdx, [dents_buffer + r13]  ; end pointer
    mov rbx, dents_buffer
.loop_entries:
    cmp rbx, rdx
    jge .ls_done
    
    ; Obter tamanho do registro
    movzx rcx, word [rbx + 16]  ; d_reclen
    
    ; Obter nome
    lea rsi, [rbx + 19]  ; d_name
    
    ; Verificar se é . ou ..
    cmp byte [rsi], '.'
    jne .process_entry
    cmp byte [rsi + 1], 0
    je .next_entry
    cmp byte [rsi + 1], '.'
    jne .process_entry
    cmp byte [rsi + 2], 0
    je .next_entry

.process_entry:
    ; Obter tipo do arquivo
    push rbx
    push rcx
    push r13
    mov rdx, rsi          ; salvar ponteiro para o nome
    mov rdi, rsi
    call get_file_type
    ; rax = tipo (1=dir, 2=reg, 0=unknown)
    mov rsi, rdx          ; restaurar ponteiro para o nome
    
    ; Imprimir com cor
    call print_colored_name
    pop r13
    pop rcx
    pop rbx
    
.next_entry:
    add rbx, rcx
    jmp .loop_entries
    
.ls_done:
    ; Imprimir quebra de linha
    mov rsi, newline
    mov rdx, 1
    call print
    pop r13
    pop r12
    pop rbx
    ret
    
.ls_error:
    ; Imprimir mensagem de erro
    mov rsi, ls_error_msg
    mov rdx, ls_error_len
    call print
    pop r13
    pop r12
    pop rbx
    ret

; ========================================
; Função auxiliar: get_file_type
; Obtém o tipo do arquivo
; Parâmetros: rdi = nome do arquivo
; Retorno: rax = 1 (dir), 2 (reg), 0 (unknown)
; ========================================
get_file_type:
    push rbx
    mov rax, SYS_STAT
    mov rsi, stat_buf
    syscall
    cmp rax, 0
    jl .unknown_type
    
    ; Obter st_mode
    mov rax, [stat_buf + 24]  ; st_mode
    and rax, S_IFMT
    cmp rax, S_IFDIR
    je .is_dir
    cmp rax, S_IFREG
    je .is_reg
    
.unknown_type:
    xor rax, rax
    pop rbx
    ret
    
.is_dir:
    mov rax, 1
    pop rbx
    ret
    
.is_reg:
    mov rax, 2
    pop rbx
    ret

; ========================================
; Função auxiliar: print_colored_name
; Imprime nome com cor baseada no tipo
; Parâmetros: rsi = nome, rax = tipo
; ========================================
print_colored_name:
    push rsi
    push rax
    
    cmp rax, 1
    je .dir
    cmp rax, 2
    je .reg
    ; default
    mov rsi, unknown_symbol
    mov rdx, unknown_symbol_len
    call print
    jmp .color
    
.dir:
    mov rsi, dir_symbol
    mov rdx, dir_symbol_len
    call print
    mov rsi, blue_prefix
    jmp .color
    
.reg:
    mov rsi, file_symbol
    mov rdx, file_symbol_len
    call print
    mov rsi, green_prefix
    
.color:
    mov rdx, 5
    call print
    
    ; Imprimir nome
    pop rax
    pop rsi
    push rsi
    mov rdi, rsi
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
.len_done:
    call print
    
    ; Reset color
    mov rsi, reset_color
    mov rdx, 4
    call print
    
    ; Espaço
    mov rsi, space
    mov rdx, 1
    call print
    
    pop rsi
    ret

; ========================================
; Seção de dados (continuação)
; ========================================
section .data
    home_dir db ".", 0
    newline db NEWLINE
    clear_seq db 0x1b, '[', '2', 'J', 0x1b, '[', 'H'
    clear_seq_len equ $ - clear_seq
    
    ; Para ls
    dot db ".", 0
    ls_error_msg db "Erro ao listar diretório", NEWLINE, 0
    ls_error_len equ $ - ls_error_msg
    
    ; Cores ANSI
    blue_prefix db 0x1b, '[', '3', '4', 'm'
    green_prefix db 0x1b, '[', '3', '2', 'm'
    white_prefix db 0x1b, '[', '3', '7', 'm'
    reset_color db 0x1b, '[', '0', 'm'
    space db " " 
    
    ; Símbolos para tipos de arquivo
    dir_symbol db "[DIR] "
    dir_symbol_len equ $ - dir_symbol
    file_symbol db "[FILE] "
    file_symbol_len equ $ - file_symbol
    unknown_symbol db "[UNK] "
    unknown_symbol_len equ $ - unknown_symbol
