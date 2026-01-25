; ========================================
; Funções de Entrada e Saída (I/O)
; ========================================

%include "include/syscalls.inc"

; Declarar funções globais
global print, read_input

; ========================================
; Seção de código
; ========================================
section .text

; ========================================
; Função: print
; Escreve dados na saída padrão (stdout)
; Parâmetros:
;   rsi = endereço do buffer a imprimir
;   rdx = tamanho dos dados em bytes
; ========================================
print:
    mov rax, SYS_WRITE       ; Syscall para escrever
    mov rdi, STDOUT          ; File descriptor para stdout (1)
    syscall
    ret

; ========================================
; Função: read_input
; Lê dados da entrada padrão (stdin)
; Parâmetros:
;   rsi = endereço do buffer para armazenar entrada
;   rdx = tamanho máximo a ler
; Retorna:
;   rax = número de bytes lidos
; ========================================
read_input:
    mov rax, SYS_READ        ; Syscall para ler
    mov rdi, STDIN           ; File descriptor para stdin (0)
    syscall
    ret 