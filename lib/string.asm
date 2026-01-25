; ========================================
; Funções de Manipulação de Strings
; ========================================

; Declarar função global
global strcmp

; ========================================
; Seção de código
; ========================================
section .text

; ========================================
; Função: strcmp
; Compara duas strings e retorna o resultado
; Parâmetros:
;   rsi = primeira string
;   rdi = segunda string
; Retorna:
;   rax = 0 se strings são iguais
;   rax = 1 se strings são diferentes
; ========================================
strcmp:
    ; Loop principal de comparação
.loop:
    ; Carregar caracteres de ambas as strings
    mov al, [rsi]            ; Caractere da primeira string em al
    mov bl, [rdi]            ; Caractere da segunda string em bl
    
    ; Comparar caracteres
    cmp al, bl
    jne .diff                ; Se diferentes, pular para .diff
    
    ; Verificar se chegou ao final das strings (caractere nulo)
    test al, al
    je .equal                ; Se nulo, strings são iguais
    
    ; Avançar para próximo caractere em ambas as strings
    inc rsi
    inc rdi
    jmp .loop

; ========================================
; Strings diferentes
; ========================================
.diff:
    mov rax, 1               ; Retornar 1 (diferentes)
    ret

; ========================================
; Strings iguais
; ========================================
.equal:
    xor rax, rax             ; Retornar 0 (iguais)
    ret 