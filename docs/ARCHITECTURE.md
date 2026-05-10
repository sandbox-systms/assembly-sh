# Arquitetura Técnica do Mini Shell

Documentação detalhada sobre a implementação interna do Mini Shell em Assembly x86-64.

## 📑 Índice

1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
2. [Estrutura de Memória](#estrutura-de-memória)
3. [Fluxo de Execução](#fluxo-de-execução)
4. [Módulos e Funções](#módulos-e-funções)
5. [Convenções de Chamada](#convenções-de-chamada)
6. [Tratamento de Erros](#tratamento-de-erros)
7. [Otimizações](#otimizações)

## 🏗️ Visão Geral da Arquitetura

O Mini Shell é estruturado em camadas:

```
┌─────────────────────────────────────┐
│    Aplicação (minishell.asm)        │
│   Loop principal, parsing, routing  │
├─────────────────────────────────────┤
│        Camada de Built-ins          │
│  cd, pwd, echo, ls, clear (builtins.asm) │
├─────────────────────────────────────┤
│     Camada de Sistema Operacional   │
│  Processos, I/O (process.asm, io.asm) │
├─────────────────────────────────────┤
│         Camada de Utilitários       │
│ Strings, conversão (string.asm)     │
├─────────────────────────────────────┤
│         Camada de Syscalls          │
│  Interface com Kernel Linux (x86-64)│
└─────────────────────────────────────┘
```

## 💾 Estrutura de Memória

### Layout de Memória (Linux x86-64)

```
┌────────────────────────────────────┐  0xFFFFFFFFFFFFFFFF
│      Kernel Space (não acessível)  │
├────────────────────────────────────┤
│           Stack (cresce ↓)          │
│      (variáveis locais, retorno)    │
│                                     │
│              ...                    │
│                                     │
│           Heap (cresce ↑)           │
│      (alocação dinâmica)            │
├────────────────────────────────────┤
│  Seção .bss (dados não inicializados) 0x404000
│  - buffer (1024 bytes)             │
│  - buffer_consumed (8 bytes)        │
│  - buffer_size (8 bytes)            │
│  - argv (16 bytes)                  │
│  - cwd_buffer (256 bytes)           │
├────────────────────────────────────┤
│  Seção .data (dados inicializados)  │
│  - prompt ("mini-shell> ")          │
│  - exit_cmd ("exit")                │
│  - msg_help, msg_pwd_error          │
├────────────────────────────────────┤
│  Seção .text (código)               │
│  - _start                           │
│  - funções                          │
└────────────────────────────────────┘  0x400000
```

### Segmentos do Programa

| Segmento | Tipo | Conteúdo | Permissões |
|----------|------|----------|-----------|
| `.text` | RW | Código máquina | R, X |
| `.data` | Inicializado | Strings, constantes | R |
| `.bss` | Não inicializado | Buffers, variáveis | R, W |

## 🔄 Fluxo de Execução Detalhado

### 1. Inicialização (_start)

```asm
_start:
    mov qword [buffer_consumed], 0   ; Zera posição consumida
    mov qword [buffer_size], 0       ; Zera tamanho do buffer
    jmp .loop                        ; Entra no loop principal
```

**Estado inicial:**
- RSP aponta para o topo do stack (args do programa)
- Nenhum registrador está inicializado
- Buffer vazio

### 2. Loop Principal

```
┌─────────────────────┐
│  .loop              │
├─────────────────────┤
│  Exibir prompt      │ (print "mini-shell> ")
├─────────────────────┤
│  Verificar buffer   │ (tem dados pendentes?)
│  [buffer_consumed   │
│   < buffer_size]    │
├─────────────────────┤
│  Sim: processar     │ goto .process_existing_buffer
│  Não: ler entrada   │ read_input()
├─────────────────────┤
│  Encontrar newline  │ Busca 0x0A no buffer
│                     │
│  Se encontrado:     │
│  - Extrair linha    │
│  - Atualizar pos    │
│                     │
│  Se não encontrado: │
│  - Ler mais dados   │
│  - Concatenar       │
├─────────────────────┤
│  Parse comando      │ Separar cmd e args
├─────────────────────┤
│  Built-in?          │ strcmp(cmd, "exit")
│  ├─ Sim: executar   │ call builtin_*
│  └─ Não: fork+exec  │ call fork_and_exec
├─────────────────────┤
│  Volta ao .loop     │
└─────────────────────┘
```

### 3. Leitura e Buffering

**Primeira leitura (buffer vazio):**
```
┌─────────────────────────────────────────┐
│ call read_input(buffer, 1023)           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│ SYS_READ (rax=0)                        │
│ FD=STDIN (rdi=0)                        │
│ buffer=buffer (rsi)                     │
│ count=1023 (rdx)                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│ RAX = número de bytes lidos             │
│ Buffer preenchido com dados do stdin    │
│ Armazenar em buffer_size                │
└──────────────────────────────────────────┘
```

**Processamento do buffer:**
```
buffer: "echo teste\npwd\nexit\n"
         ^^^^^^^^^          ^
         linha 1      newline
         
1. Extrair "echo teste"
2. Atualizar buffer_consumed
3. Processar comando
4. Volta ao .loop
5. Processa "pwd\n"
6. Processa "exit\n"
7. EOF detectado, sai
```

### 4. Parse de Comando

Entrada: `"echo    Olá    Mundo   "`

```
1. Pular espaços iniciais
2. Extrair comando até espaço
   → "echo"
3. Pular espaços
4. Extrair argumentos até newline
   → "Olá    Mundo"
5. Retornar (comando, argumentos)
```

### 5. Routing (Dispatch)

```
┌──────────────────────────────────┐
│  comando extraído                │
└──────────────┬───────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
    ┌────────┐   ┌──────────┐
    │ "exit" │   │ Outros   │
    └───┬────┘   └────┬─────┘
        │             │
        ▼             ▼
    ┌────────────┐ ┌─────────────────┐
    │ exit(0)    │ │ fork_and_exec() │
    │            │ │ ├─ fork()       │
    │            │ │ │  ├─ Pai:      │
    │            │ │ │  │ wait4()    │
    │            │ │ │  └─ Filho:    │
    │            │ │ │    execve()   │
    │            │ │ └─ Voltar loop  │
    └────────────┘ └─────────────────┘
```

## 🔧 Módulos e Funções

### lib/string.asm

#### `strlen(rdi)`
```asm
strlen:
    xor rcx, rcx        ; contador = 0
.loop:
    cmp byte [rdi + rcx], 0  ; fim da string?
    je .done
    inc rcx              ; contador++
    jmp .loop
.done:
    mov rax, rcx         ; retorna tamanho
    ret
```
**Retorna:** RAX = tamanho da string (sem null terminator)

#### `strcmp(rdi, rsi)`
Compara duas strings byte por byte
**Retorna:** RAX = 0 se iguais, valor da diferença senão

#### `strchr(rdi, rsi)`
Procura caractere (RSI) em string (RDI)
**Retorna:** RAX = ponteiro para caractere ou 0 se não encontrado

### lib/io.asm

#### `print(rsi, rdx)`
```asm
print:
    mov rax, SYS_WRITE  ; syscall write
    mov rdi, STDOUT     ; fd = 1 (stdout)
    ; rsi = buffer
    ; rdx = tamanho
    syscall
    ret
```
**Parâmetros:**
- RSI: endereço do buffer a imprimir
- RDX: tamanho em bytes

**Retorna:** RAX = bytes escritos

#### `read_input(rsi, rdx)`
```asm
read_input:
    mov rax, SYS_READ   ; syscall read
    mov rdi, STDIN      ; fd = 0 (stdin)
    ; rsi = buffer
    ; rdx = tamanho máximo
    syscall
    ret
```

### lib/process.asm

#### `fork_and_exec(rdi, rsi)`
Cria novo processo e executa programa

```asm
1. fork() → gera novo processo
   ├─ Retorna PID no pai
   └─ Retorna 0 no filho

2. No filho: execve()
   ├─ Carrega novo programa
   └─ Não retorna se bem-sucedido

3. No pai: wait4()
   ├─ Aguarda filho terminar
   └─ Retorna ao loop
```

### lib/builtins.asm

#### `builtin_cd(rdi)`
```asm
; rdi = ponteiro para caminho
syscall chdir (80)
; Muda diretório do processo
```

#### `builtin_pwd()`
```asm
; Sem parâmetros
syscall getcwd (79)
; Obtém diretório atual
; Escreve em stdout
```

#### `builtin_echo(rdi)`
```asm
; rdi = argumentos
; Simplesmente escreve em stdout
```

#### `builtin_help()`
```asm
; Escreve mensagem de ajuda em stdout
```

## 🎯 Convenções de Chamada (System V AMD64 ABI)

### Passagem de Parâmetros

```asm
parâmetro 1 → RDI
parâmetro 2 → RSI
parâmetro 3 → RDX
parâmetro 4 → RCX
parâmetro 5 → R8
parâmetro 6 → R9
parâmetro 7+ → Stack
```

### Registradores Preservados

Funções chamadas DEVEM preservar:
- RBX, RBP, R12-R15

Funções podem modificar livremente:
- RAX, RCX, RDX, RSI, RDI, R8-R11

### Exemplo de Chamada

```asm
; Chamar: print(buffer, len)
mov rsi, buffer      ; parâmetro 1 (rdi para syscall, rsi para função)
mov rdx, len         ; parâmetro 2
call print           ; Executa

; Dentro de print:
mov rax, SYS_WRITE
mov rdi, STDOUT      ; rdi = fd (parâmetro da syscall)
syscall              ; rsi, rdx já estão configurados
ret
```

## ⚠️ Tratamento de Erros

### Verificação de Syscalls

```asm
mov rax, SYS_*      ; Executa syscall
cmp rax, 0          ; Verifica retorno
jl .error           ; Se negativo = erro
```

### Códigos de Erro

Em x86-64, syscalls retornam:
- Valores positivos = sucesso
- Valores negativos = erro (negativo é código de erro)

Exemplos:
- -1 = EPERM (Operação não permitida)
- -2 = ENOENT (Arquivo não encontrado)
- -21 = EISDIR (É um diretório)

### Tratamento em builtin_cd

```asm
builtin_cd:
    mov rax, SYS_CHDIR
    ; ... setup rdi com caminho
    syscall
    
    cmp rax, 0
    je .success
    
    ; Erro: exibir mensagem
    mov rsi, msg_chdir_error
    mov rdx, msg_chdir_error_len
    call print
    
.success:
    ret
```

## ⚡ Otimizações

### 1. Buffering de Entrada

**Sem buffering:**
- 1 leitura por linha
- Muitas syscalls (caras)

**Com buffering:**
- 1 leitura de 1024 bytes
- Processar múltiplas linhas
- Reduz overhead do kernel

### 2. Reuso de Buffers

Evita realocação:
```asm
buffer resb 1024        ; Uma vez na memória
buffer_consumed resq 1  ; Apenas índices mudam
buffer_size resq 1
```

### 3. Inlining de Funções Pequenas

Algumas funções simples são expandidas inline:
```asm
; Em vez de chamar strlen(), fazer manualmente
xor rcx, rcx
.loop:
    cmp byte [rsi + rcx], 0
    je .done
    inc rcx
    jmp .loop
.done:
    mov rdx, rcx  ; Use tamanho diretamente
```

### 4. Minimização de Registrador Saves/Restores

Apenas o necessário é preservado:
```asm
; Ruim: salvar tudo
push rax
push rbx
push rcx
...

; Bom: salvar apenas o necessário
; A maioria dos registradores é efêmera
```

## 📊 Análise de Performance

### Syscalls por Comando

```
Entrada de "echo teste":

1. SYS_READ (ler linha)         1x
2. SYS_WRITE (exibir "echo...")  2x (prompt + saída)
───────────────────────────────────
Total: 3 syscalls

Entrada redirecionada (1000 linhas):

1. SYS_READ (ler 1024 bytes)    ~1x (buffer)
2. SYS_WRITE (processamento)    ~1000x
──────────────────────────────────
Total: ~1001 syscalls
(vs ~3000 sem buffering)
```

### Overhead de Syscalls

```asm
syscall → Context switch
    ├─ Salvar contexto (user → kernel)
    ├─ Validar parâmetros
    ├─ Executar operação
    ├─ Restaurar contexto (kernel → user)
    └─ Retornar ao programa

Custo: ~100-1000 ciclos de CPU
```

## 🔐 Segurança

### Limitações

1. **Buffer overflow:** Buffer de 1024 bytes pode ser transbordado
2. **Path traversal:** Sem validação de caminhos
3. **Injection:** Sem sanitização de entrada
4. **Privilégios:** Executa com permissões do usuário

### Mitigações Presentes

- Limite de tamanho de entrada (1024 bytes)
- Verificação de EOF
- Validação de syscalls

### Melhorias Recomendadas

- [ ] Validar tamanho de caminho antes de chdir
- [ ] Sanitizar argumentos para programas externos
- [ ] Implementar quota de memória
- [ ] Verificar recursos disponíveis

## 📚 Referências Técnicas

- [System V AMD64 ABI](https://refspecs.linuxbase.org/elf/x86-64-abi-0.99.pdf)
- [Linux syscall table x86-64](https://filippo.io/linux-syscall-table/)
- [NASM Manual](https://www.nasm.us/doc/)
- [Linux Man Pages](https://man7.org/)
