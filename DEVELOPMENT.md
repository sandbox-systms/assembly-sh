# Guia de Desenvolvimento - Mini Shell

Documentação para desenvolvedores que desejam entender, modificar e estender o Mini Shell.

## 📑 Índice

1. [Setup de Desenvolvimento](#setup-de-desenvolvimento)
2. [Estrutura do Código](#estrutura-do-código)
3. [Adicionando Novos Built-ins](#adicionando-novos-built-ins)
4. [Debugging](#debugging)
5. [Testes](#testes)
6. [Boas Práticas](#boas-práticas)
7. [Resolução de Problemas](#resolução-de-problemas)

## 🛠️ Setup de Desenvolvimento

### Instalação de Ferramentas

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install \
    nasm \
    binutils \
    build-essential \
    gdb \
    gdb-doc
```

#### Fedora/RHEL:
```bash
sudo dnf install \
    nasm \
    binutils \
    gcc \
    gdb
```

#### macOS (não suportado para assembly x86-64 Linux):
Use Docker ou máquina virtual Linux

### Clone e Configuração

```bash
git clone https://github.com/usuario/bash-assembly.git
cd bash-assembly
make clean
make
```

### Verificar Instalação

```bash
# Verificar nasm
nasm -version

# Verificar ld
ld --version

# Testar compilação
make
./bin/minishell < test_input.txt
```

## 📁 Estrutura do Código

### Nomeação de Funções

Convenção: `modulo_funcao`

```
string_strlen()    ← função do módulo string
io_print()         ← função do módulo io
process_fork()     ← função do módulo process
builtin_cd()       ← comando built-in
```

### Estrutura de um Módulo

Cada módulo tem arquivo `.asm` e `.inc`:

```
lib/
├── meumodulo.asm     ← Implementação
└── meumodulo.inc     ← Interface (declare como global)
```

**meumodulo.asm:**
```asm
; Comentário do módulo
%include "include/syscalls.inc"
%include "lib/outro.inc"

global minha_funcao

section .data
    mensagem db "Algo", 0
    
section .text

minha_funcao:
    ; implementação
    ret
```

**meumodulo.inc:**
```asm
%ifndef MEUMODULO_INC
%define MEUMODULO_INC

; Declarações de funções exportadas
extern minha_funcao

%endif
```

### Padrão de Documentação

Toda função deve ter comentário explicando:
- O que faz
- Parâmetros (quais registradores)
- Retorno (quais registradores)
- Registradores que modifica

```asm
; ========================================
; Função: minha_funcao
; Descrição do que faz
; Parâmetros:
;   rdi = primeiro parâmetro
;   rsi = segundo parâmetro
; Retorna:
;   rax = resultado
; Modifica: rcx, rdx
; ========================================
minha_funcao:
    ; corpo da função
    ret
```

## ➕ Adicionando Novos Built-ins

### Exemplo: Adicionar comando `clear`

#### 1. Editar `lib/builtins.asm`

Adicionar função no final:

```asm
; ========================================
; Função: builtin_clear
; Limpa a tela usando ANSI escape codes
; Parâmetros: nenhum
; Retorna: rax = 0
; ========================================
builtin_clear:
    ; ANSI escape code: ESC[2J (limpar tela)
    mov rsi, ansi_clear
    mov rdx, ansi_clear_len
    call print
    ret
```

Adicionar na seção `.data`:

```asm
section .data
    ansi_clear db 0x1B, "[2J", 0x1B, "[H"
    ansi_clear_len equ $ - ansi_clear
```

#### 2. Editar `lib/builtins.inc`

Adicionar export:

```asm
extern builtin_clear
```

#### 3. Editar `src/minishell.asm`

No loop principal, após verificar outros comandos:

```asm
; Verificar "clear"
mov rdi, buffer
mov rsi, clear_cmd
call string_strcmp
cmp rax, 0
je .is_clear

; ...

.is_clear:
    call builtin_clear
    jmp .next_command

; Adicionar constante na seção .data:
clear_cmd db "clear", 0
```

#### 4. Compilar e Testar

```bash
make clean
make

./bin/minishell
mini-shell> clear
[tela limpa]
```

### Exemplo: Adicionar comando `ls` modificado

```asm
global builtin_ls

builtin_ls:
    ; rdi contém argumentos (Ex: "-la")
    
    ; Preparar para fork+exec
    mov rsi, ls_program   ; "/bin/ls"
    
    ; Pode fazer algo especial com argumentos
    ; ou simplesmente passar para fork+exec
    
    ; Por simplicidade, deixar fork_and_exec lidar
    call fork_and_exec
    ret

section .data
    ls_program db "/bin/ls", 0
```

## 🐛 Debugging

### Compilar com Símbolos de Debug

Editar `makefile`:

```makefile
ASMFLAGS = -f elf64 -g -F dwarf
```

Recompilar:

```bash
make clean
make
```

### Usar GDB

```bash
gdb ./bin/minishell

(gdb) break _start
(gdb) run < test_input.txt
(gdb) disass              # Ver instruções atuais
(gdb) info registers      # Ver registradores
(gdb) x/16bx $rsp         # Ver stack (16 bytes a partir de RSP)
(gdb) step                # Próxima instrução
(gdb) continue            # Continuar
(gdb) quit                # Sair
```

### Técnicas Úteis de Debug

#### Ver conteúdo de registrador

```bash
(gdb) p $rax
(gdb) p/x $rax            # Hexadecimal
(gdb) p/s *(char*)$rsi    # String apontada por RSI
```

#### Ver memória

```bash
(gdb) x/10s 0x404000      # 10 strings a partir de 0x404000
(gdb) x/16bx 0x404010     # 16 bytes em hexadecimal
(gdb) info address buffer # Endereço de 'buffer'
```

#### Breakpoints condicionais

```bash
(gdb) break *0x401234 if $rax == 5  # Break se RAX = 5
(gdb) watch buffer[0]               # Break se buffer[0] mudar
```

### OBJDUMP para Análise

Ver o executável compilado:

```bash
objdump -d bin/minishell | head -50
objdump -t bin/minishell  # Símbolos
objdump -s -j .data bin/minishell  # Seção .data
```

### STRACE para Rastrear Syscalls

Ver quais syscalls estão sendo feitas:

```bash
strace -e trace=write,read,fork,execve ./bin/minishell < test_input.txt
```

Output esperado:
```
read(0, "pwd\nexit\n", 1024)         = 9
write(1, "mini-shell> ", 12)         = 12
write(1, "/home/user\n", 11)         = 11
read(0, "", 1024)                    = 0
exit_group(0)                        = ?
```

## ✅ Testes

### Teste Manual Básico

```bash
./bin/minishell
mini-shell> pwd
/home/user/bash-assembly
mini-shell> echo teste
teste
mini-shell> cd /tmp
mini-shell> pwd
/tmp
mini-shell> cd -
-bash: cd: -: No such file or directory  (esperado, - não implementado)
mini-shell> exit
```

### Teste com Arquivo de Entrada

Criar `test_custom.txt`:
```
pwd
echo "Teste 1"
cd /tmp
pwd
echo "Teste 2"
exit
```

Executar:
```bash
./bin/minishell < test_custom.txt
```

### Teste com Pipe

```bash
echo -e "pwd\nexit" | ./bin/minishell
```

### Teste de Limite de Buffer

```bash
# Gerar linha com 900 caracteres
python3 -c "print('echo ' + 'A' * 900)"  | ./bin/minishell
```

### Teste de Performance

```bash
# Gerar 1000 comandos
python3 -c "for i in range(1000): print('echo teste %d' % i)" > large_input.txt
python3 -c "print('exit')" >> large_input.txt

time ./bin/minishell < large_input.txt > /dev/null
```

### Suite de Testes (Bash Script)

Criar `test_suite.sh`:

```bash
#!/bin/bash

FAILED=0
PASSED=0

run_test() {
    local name="$1"
    local input="$2"
    local expected="$3"
    
    local result=$(echo -e "$input" | ./bin/minishell 2>&1)
    
    if [[ "$result" == *"$expected"* ]]; then
        echo "✓ $name"
        ((PASSED++))
    else
        echo "✗ $name"
        echo "  Esperado: $expected"
        echo "  Obtido: $result"
        ((FAILED++))
    fi
}

# Testes
run_test "pwd simples" "pwd\nexit" "/home"
run_test "echo simples" "echo teste\nexit" "teste"
run_test "help disponível" "help\nexit" "Mini Shell"

echo ""
echo "Resultados: $PASSED passaram, $FAILED falharam"

exit $FAILED
```

Executar:
```bash
chmod +x test_suite.sh
./test_suite.sh
```

## 📝 Boas Práticas

### 1. Sempre Inicializar Registradores

```asm
; ✗ Ruim: Assume valor anterior
mov rax, qword [buffer_size]
add rax, rbx

; ✓ Bom: Limpar antes
xor rax, rax
mov rax, qword [buffer_size]
add rax, rbx
```

### 2. Preservar Registradores Necessários

```asm
; ✗ Ruim: Perde o valor de RBX
minha_funcao:
    mov rbx, rax
    call outra_funcao  ; Pode modificar RBX!
    mov rcx, rbx       ; RBX pode ter mudado

; ✓ Bom: Salvar e restaurar
minha_funcao:
    push rbx
    mov rbx, rax
    call outra_funcao
    mov rcx, rbx
    pop rbx
    ret
```

### 3. Comentar Seções Complexas

```asm
; ✗ Ruim: Sem contexto
mov rax, [buffer_consumed]
mov rbx, [buffer_size]
cmp rax, rbx
jl .process_existing_buffer

; ✓ Bom: Claro o que faz
; Verificar se ainda há dados não processados no buffer
mov rax, [buffer_consumed]       ; Bytes já consumidos
mov rbx, [buffer_size]           ; Total de bytes
cmp rax, rbx                      ; Comparar
jl .process_existing_buffer       ; Se menor, há mais dados
```

### 4. Alinhar Stack (em 16 bytes)

```asm
; Antes de chamar função externa
mov rsp, rax
and rsp, ~0xF  ; Alinhar em 16 bytes
call syscall   ; Ou função C
```

### 5. Usar Estruturas Lógicas Claras

```asm
; Convenção: .comando_xxx para labels
.is_exit:
    call builtin_exit
    jmp .loop_end

.is_pwd:
    call builtin_pwd
    jmp .loop_end

.is_unknown:
    call fork_and_exec
    ; Fallthrough para .loop_end

.loop_end:
    jmp .loop
```

### 6. Documentar Interfaces Públicas

Toda função em `.inc` deve ter documentação:

```asm
; ========================================
; Função: string_strlen
; Calcula o comprimento de uma string
; Parâmetros:
;   rdi = ponteiro para string (null-terminated)
; Retorna:
;   rax = comprimento (sem contar null terminator)
; Registradores modificados: rcx
; ========================================
extern string_strlen
```

## 🔧 Resolução de Problemas

### Problema: "Falha ao chamar syscall"

```
Erro: Negative return value from syscall
```

**Causa provável:** Parâmetro errado para syscall

**Verificação:**
```bash
strace ./bin/minishell

# Ver qual syscall falhou
# Verificar parâmetros na documentação Linux
man 2 <syscall>
```

### Problema: "Segmentation Fault"

```
Segmentation fault (core dumped)
```

**Causa provável:** Acesso a memória inválida

**Debugar:**
```bash
gdb ./bin/minishell
(gdb) run < test_input.txt
(gdb) bt  # Backtrace
```

**Verificações:**
- Verificar se ponteiros estão inicializados
- Verificar limites de buffer
- Verificar alignement de stack

### Problema: "Comando não encontrado"

O shell tenta executar o programa com execve, mas falha.

**Verificações:**
```bash
# Verificar se programa existe
which ls
/bin/ls

# Usar caminho absoluto
./bin/minishell
mini-shell> /bin/ls  # Deve funcionar
```

### Problema: "Buffer overflow"

Entrada maior que 1024 bytes causa problemas.

**Verificação:**
```bash
# Testar com entrada grande
python3 -c "print('echo ' + 'A' * 1500)" | ./bin/minishell
```

**Solução:** Aumentar tamanho de buffer em minishell.asm:
```asm
buffer resb 4096  ; Aumentar de 1024 para 4096
```

### Problema: "Prompt não aparece"

```bash
./bin/minishell
[sem prompt visível, mas aceita entrada]
```

**Verificação:**
```bash
strace -e write ./bin/minishell
# Ver se write() está sendo chamado
```

**Possível causa:** stderr/stdout buffering

**Solução:** Adicionar flush (não implementado atualmente)

## 📚 Recursos para Aprender

### Assuntos de Assembly

1. **Registradores x86-64**
   - RIP: Instruction Pointer
   - RSP: Stack Pointer
   - RBP: Base Pointer
   - RAX-RDX, RSI, RDI: Propósito geral

2. **Instruções Comuns**
   - mov: Mover dados
   - add, sub, imul, div: Aritmética
   - cmp, jmp, je, jne: Controle de fluxo
   - syscall: Chamar kernel

3. **Calling Conventions**
   - System V ABI (Linux)
   - Microsoft x64 (Windows - não usado aqui)

### Referências Online

- [x86-64 Assembly](https://www.felixcloutier.com/x86/)
- [Linux Syscall Reference](https://filippo.io/linux-syscall-table/)
- [NASM Manual](https://www.nasm.us/doc/)
- [GNU Assembler Manual](https://sourceware.org/binutils/docs/as/)

### Livros Recomendados

- "Programming from the Ground Up" - Jonathan Bartlett
- "Assembly Language Step-by-Step" - Jeff Duntemann
- "Intel 64 and IA-32 Architectures Software Developer's Manual"

## 🎯 Próximos Passos para Contribuição

1. **Fork o repositório**
2. **Criar branch:** `git checkout -b feature/minhafeature`
3. **Fazer mudanças** seguindo guia
4. **Testar bem:** `make clean && make && ./test_suite.sh`
5. **Commit:** `git commit -am "Adicionar minhafeature"`
6. **Push:** `git push origin feature/minhafeature`
7. **Pull Request** no GitHub

---

**Última atualização:** 24 de janeiro de 2026
