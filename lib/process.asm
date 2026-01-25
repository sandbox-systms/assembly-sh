; ========================================
; Funções de Gerenciamento de Processos
; ========================================

%include "include/syscalls.inc"

; Declarar função global
global fork_exec_wait

; ========================================
; Seção de código
; ========================================
section .text

; ========================================
; Função: fork_exec_wait
; Cria um novo processo filho, executa um comando e aguarda sua conclusão
; Parâmetros:
;   rdi = caminho do programa/comando a executar
;   rsi = ponteiro para array de argumentos
;   rdx = ponteiro para array de variáveis de ambiente
; Fluxo:
;   1. Fork: cria processo filho
;   2. Filho: executa o comando
;   3. Pai: aguarda a conclusão do filho
; ========================================
fork_exec_wait:
    ; Realizar chamada fork para criar processo filho
    mov rax, SYS_FORK
    syscall
    
    ; Testar rax: se for 0, estamos no processo filho
    test rax, rax
    jz .child

; ========================================
; Processo pai: aguardar conclusão do filho
; ========================================
.parent:
    ; rax contém o PID do processo filho
    mov rdi, rax             ; Primeiro parâmetro: PID do filho
    xor rsi, rsi             ; Segundo parâmetro: NULL (flags)
    xor rdx, rdx             ; Terceiro parâmetro: NULL (status)
    xor r10, r10             ; Quarto parâmetro: NULL (opções)
    
    ; Chamar wait4 para aguardar o filho
    mov rax, SYS_WAIT4
    syscall
    ret

; ========================================
; Processo filho: executar comando
; ========================================
.child:
    ; rdi já contém o caminho do programa
    ; rsi já contém os argumentos
    ; rdx já contém o ambiente (NULL)
    mov rax, SYS_EXECVE      ; Syscall para executar
    syscall
    
    ; Se execve falhar, sair com código de erro
    mov rax, SYS_EXIT
    mov rdi, 127             ; Código de erro
    syscall 

