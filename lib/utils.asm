; ========================================
; Utilidades de Parsing e Manipulação de Strings
; Funções para extrair comando e argumentos
; ========================================

%include "include/syscalls.inc"
%include "lib/string.inc"

; Declarar funções globais
global parse_command, find_first_space, is_builtin

; Declarar funções externas
extern strcmp

; ========================================
; Seção de dados
; ========================================
section .data
    ; Comandos built-in
    cmd_cd db "cd", 0
    cmd_pwd db "pwd", 0
    cmd_echo db "echo", 0
    cmd_help db "help", 0
    cmd_exit db "exit", 0

; ========================================
; Seção de dados não inicializados
; ========================================
section .bss
    ; Buffer para armazenar o comando extraído
    command_buffer resb 256
    ; Buffer para armazenar os argumentos
    args_buffer resb 1024

; ========================================
; Seção de código
; ========================================
section .text

; ========================================
; Função: parse_command
; Extrai o comando e seus argumentos de uma string
; Parâmetros:
;   rdi = ponteiro para string de entrada
; Retorno:
;   rsi = ponteiro para comando extraído
;   rdi = ponteiro para argumentos (ou 0 se nenhum)
; ========================================
parse_command:
    push rbx
    push r12
    push r13
    
    ; Salvar ponteiro inicial
    mov r12, rdi
    
    ; Primeiro, encontrar o final da linha (newline ou null)
    xor r13, r13            ; r13 = índice para encontrar final da linha
.find_eol:
    cmp byte [r12 + r13], NEWLINE
    je .found_newline
    cmp byte [r12 + r13], 0
    je .found_null
    inc r13
    cmp r13, 256
    jl .find_eol
    ; Se não encontrar, assumir que é o final do buffer
    jmp .found_null

.found_newline:
    ; Substituir newline por null para processar só esta linha
    mov byte [r12 + r13], 0
    jmp .process_line

.found_null:
    ; Já tem null, continuar normalmente
    
.process_line:
    ; Agora encontrar primeiro espaço
    xor rcx, rcx
.find_space:
    cmp byte [r12 + rcx], SPACE
    je .space_found
    cmp byte [r12 + rcx], 0
    je .no_space
    inc rcx
    cmp rcx, 256
    jl .find_space
    jmp .no_space

.space_found:
    ; Copiar comando até o espaço
    mov rsi, command_buffer
    mov rbx, 0
.copy_cmd:
    cmp rbx, rcx
    jge .skip_spaces
    mov al, byte [r12 + rbx]
    mov byte [rsi + rbx], al
    inc rbx
    jmp .copy_cmd

.skip_spaces:
    ; Adicionar terminador null ao comando
    mov byte [rsi + rcx], 0
    
    ; Pular espaços
    add r12, rcx
.skip_space_loop:
    cmp byte [r12], SPACE
    jne .get_args
    inc r12
    jmp .skip_space_loop

.get_args:
    ; Retornar ponteiro para argumentos
    mov rdi, r12
    mov rsi, command_buffer
    pop r13
    pop r12
    pop rbx
    ret

.no_space:
    ; Sem argumentos - copiar tudo como comando
    mov rsi, command_buffer
    mov rbx, 0
.copy_all:
    cmp rbx, rcx
    jge .finish
    mov al, byte [r12 + rbx]
    mov byte [rsi + rbx], al
    inc rbx
    jmp .copy_all

.finish:
    mov byte [rsi + rcx], 0
    xor rdi, rdi
    mov rsi, command_buffer
    pop r13
    pop r12
    pop rbx
    ret

; ========================================
; Função: find_first_space
; Encontra a posição do primeiro espaço em uma string
; Parâmetros:
;   rdi = ponteiro para string
; Retorno:
;   rax = posição do espaço (ou tamanho da string se não houver)
; ========================================
find_first_space:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], SPACE
    je .found
    cmp byte [rdi + rax], 0
    je .found
    inc rax
    cmp rax, 1024
    jl .loop
.found:
    ret

; ========================================
; Função: is_builtin
; Verifica se um comando é built-in
; Parâmetros:
;   rdi = ponteiro para nome do comando
; Retorno:
;   rax = 1 se é built-in, 0 se não
;   rcx = código do comando (1=cd, 2=pwd, 3=echo, 4=help, 5=exit, 0=nenhum)
; ========================================
is_builtin:
    push rsi
    push r12
    
    ; Salvar comando em r12
    mov r12, rdi
    
    ; Comparar com "cd"
    mov rsi, cmd_cd
    mov rdi, r12
    call strcmp
    test rax, rax
    jz .is_cd
    
    ; Comparar com "pwd"
    mov rsi, cmd_pwd
    mov rdi, r12
    call strcmp
    test rax, rax
    jz .is_pwd
    
    ; Comparar com "echo"
    mov rsi, cmd_echo
    mov rdi, r12
    call strcmp
    test rax, rax
    jz .is_echo
    
    ; Comparar com "help"
    mov rsi, cmd_help
    mov rdi, r12
    call strcmp
    test rax, rax
    jz .is_help
    
    ; Comparar com "exit"
    mov rsi, cmd_exit
    mov rdi, r12
    call strcmp
    test rax, rax
    jz .is_exit
    
    ; Não é built-in
    xor rax, rax
    xor rcx, rcx
    pop r12
    pop rsi
    ret

.is_cd:
    mov rax, 1
    mov rcx, 1
    pop r12
    pop rsi
    ret

.is_pwd:
    mov rax, 1
    mov rcx, 2
    pop r12
    pop rsi
    ret

.is_echo:
    mov rax, 1
    mov rcx, 3
    pop r12
    pop rsi
    ret

.is_help:
    mov rax, 1
    mov rcx, 4
    pop r12
    pop rsi
    ret

.is_exit:
    mov rax, 1
    mov rcx, 5
    pop r12
    pop rsi
    ret
