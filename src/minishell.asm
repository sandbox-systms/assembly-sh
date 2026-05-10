; ========================================
; Mini Shell em Assembly x86-64
; Programa principal que implementa um shell minimalista
; ========================================

BITS 64                    ; Define a arquitetura como 64 bits

global _start              ; Define o ponto de entrada do programa

; Incluir os arquivos de cabeçalho com definições de syscalls e funções
%include "include/syscalls.inc"
%include "lib/string.inc"
%include "lib/io.inc"
%include "lib/process.inc"
%include "lib/builtins.inc"
%include "lib/utils.inc"

; ========================================
; Seção de dados inicializados
; ========================================
section .data
    ; Prompt exibido para o usuário
    prompt db "\033[32m", 0xF0, 0x9F, 0x92, 0xBB, " user@machine mini-shell> \033[0m"
    prompt_len equ $ - prompt
    prompt_zero db 0              ; Adiciona null terminator separadamente
    
    ; Comando para sair do shell
    exit_cmd db "exit", 0
    
    ; Mensagem de boas-vindas
    welcome db "Bem-vindo ao Mini Shell Assembly!", 10, "Digite 'help' para ver os comandos disponíveis.", 10, 0
    welcome_len equ $ - welcome

; ========================================
; Seção de dados não inicializados (BSS)
; ========================================
section .bss
    ; Buffer para armazenar entrada do usuário (1024 bytes)
    buffer resb 1024
    
    ; Posição atual dentro do buffer (quantos bytes já foram consumidos)
    buffer_consumed resq 1
    
    ; Tamanho total de dados válidos no buffer
    buffer_size resq 1
    
    ; Argumentos para a execução de comandos
    argv resb 16
    
    ; Ponteiro para argumentos do comando current
    cmd_args resq 1
    
    ; Ponteiro para comando extraído
    cmd_parsed resq 1

; ========================================
; Seção de código
; ========================================
section .text

_start:
    ; Inicializar buffer tracking
    mov qword [buffer_consumed], 0
    mov qword [buffer_size], 0
    
    ; Exibir mensagem de boas-vindas
    mov rsi, welcome
    mov rdx, welcome_len
    call print
    
.loop:
    ; Exibir o prompt na tela
    mov rsi, prompt
    mov rdx, prompt_len
    call print

    ; Verificar se ainda há dados não processados no buffer
    mov rax, [buffer_consumed]
    mov rbx, [buffer_size]
    cmp rax, rbx
    jl .process_existing_buffer

    ; Buffer vazio, ler nova entrada
    mov rsi, buffer
    mov rdx, 1023
    call read_input

    ; Verificar se EOF foi atingido (rax = 0)
    cmp rax, 0
    je .exit
    
    ; Armazenar tamanho lido e resetar posição
    mov [buffer_size], rax
    mov qword [buffer_consumed], 0

.process_existing_buffer:
    ; Encontrar o final da primeira linha (newline)
    mov r8, [buffer_consumed]     ; r8 = posição atual
    mov r9, [buffer_size]         ; r9 = tamanho total
    xor rcx, rcx                  ; rcx = deslocamento desde a posição atual
    
.find_newline:
    mov rax, r8
    add rax, rcx
    cmp rax, r9
    jge .no_newline_found         ; Se passou do fim, não há newline
    
    cmp byte [buffer + rax], 10   ; newline
    je .newline_found
    
    inc rcx
    jmp .find_newline

.newline_found:
    ; Substituir newline por null para usar como string
    mov byte [buffer + rax], 0
    
    ; Salvar posição da newline original (para depois restaurar)
    mov [cmd_parsed + 8], rax     ; Usar campo livre para armazenar newline pos
    jmp .process_line

.no_newline_found:
    ; Não há newline - é a última linha
    ; rcx = tamanho até o fim do buffer
    mov rax, r8
    add rax, rcx
    mov [cmd_parsed + 8], rax
    
.process_line:
    ; Obter endereço da linha atual
    mov rdi, buffer
    add rdi, [buffer_consumed]
    
    ; Verificar se a linha está vazia
    cmp byte [rdi], 0
    je .empty_line
    
    ; Fazer parsing do comando e argumentos
    call parse_command
    ; rsi = comando, rdi = argumentos (ou 0)
    
    ; Salvar comando e argumentos para uso posterior
    mov [cmd_parsed], rsi
    mov [cmd_args], rdi
    
    ; Verificar se é um comando built-in
    mov rdi, rsi            ; rdi = ponteiro para comando (que está em rsi)
    call is_builtin
    
    ; rax = 1 se built-in, 0 se não
    ; rcx = código do comando
    test rax, rax
    jz .external_cmd
    
    ; É um comando built-in
    cmp rcx, 1              ; cd?
    je .builtin_cd_cmd
    cmp rcx, 2              ; pwd?
    je .builtin_pwd_cmd
    cmp rcx, 3              ; echo?
    je .builtin_echo_cmd
    cmp rcx, 4              ; help?
    je .builtin_help_cmd
    cmp rcx, 5              ; clear?
    je .builtin_clear_cmd
    cmp rcx, 6              ; ls?
    je .builtin_ls_cmd
    
    jmp .advance_to_next_line

.builtin_cd_cmd:
    mov rdi, [cmd_args]     ; rdi = argumentos
    call builtin_cd
    jmp .advance_to_next_line

.builtin_pwd_cmd:
    call builtin_pwd
    jmp .advance_to_next_line

.builtin_echo_cmd:
    mov rdi, [cmd_args]     ; rdi = argumentos
    call builtin_echo
    jmp .advance_to_next_line

.builtin_help_cmd:
    call builtin_help
    jmp .advance_to_next_line

.builtin_clear_cmd:
    call builtin_clear
    jmp .advance_to_next_line

.builtin_ls_cmd:
    call builtin_ls
    jmp .advance_to_next_line

.empty_line:
    jmp .advance_to_next_line

.advance_to_next_line:
    ; Avançar buffer_consumed para a próxima linha
    mov rax, [cmd_parsed + 8]    ; Posição da newline (ou fim do buffer)
    mov [buffer_consumed], rax
    
    ; Pular a newline se não for fim do buffer
    cmp rax, [buffer_size]
    jge .loop
    inc qword [buffer_consumed]  ; Pular o newline character
    
    jmp .loop

.external_cmd:
    ; Configurar argumentos para execução do comando
    ; argv[0] = nome do comando
    ; argv[1] = NULL (termina a lista)
    mov rax, [cmd_parsed]    ; Usar buffer de comando do utils
    mov [argv], rax
    mov qword [argv + 8], 0

    ; Executar o comando usando fork e exec
    mov rdi, [cmd_parsed]    ; Usar buffer de comando do utils
    mov rsi, argv
    xor rdx, rdx
    call fork_exec_wait

    ; Voltar ao loop principal
    jmp .loop

.exit:
    ; Sair do programa com código 0
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
