# API Reference - Mini Shell

Documentação completa das funções exportadas do Mini Shell.

## 📑 Índice

1. [I/O Module (lib/io.asm)](#io-module)
2. [String Module (lib/string.asm)](#string-module)
3. [Process Module (lib/process.asm)](#process-module)
4. [Builtins Module (lib/builtins.asm)](#builtins-module)
5. [Utils Module (lib/utils.asm)](#utils-module)
6. [Constants (include/syscalls.inc)](#constants)

## I/O Module

Gerencia entrada e saída padrão.

### `print(rsi, rdx)`

Escreve dados no stdout (saída padrão).

**Sintaxe:**
```asm
mov rsi, buffer_address
mov rdx, buffer_length
call print
```

**Parâmetros:**
- `rsi`: Endereço da memória contendo dados a imprimir
- `rdx`: Número de bytes a imprimir

**Retorna:**
- `rax`: Número de bytes escritos (ou código de erro se negativo)

**Preserva:**
- nenhum registrador especial

**Modifica:**
- `rax`

**Exemplo:**
```asm
section .data
    msg db "Olá, Mundo!", NEWLINE
    msg_len equ $ - msg

section .text
    mov rsi, msg
    mov rdx, msg_len
    call print
```

**Notas:**
- Usa syscall `write` (1) com file descriptor 1 (stdout)
- Não adiciona newline automaticamente
- Pode escrever menos bytes que solicitado

---

### `read_input(rsi, rdx)`

Lê dados do stdin (entrada padrão).

**Sintaxe:**
```asm
mov rsi, buffer_address
mov rdx, max_bytes
call read_input
```

**Parâmetros:**
- `rsi`: Endereço do buffer para armazenar dados lidos
- `rdx`: Número máximo de bytes a ler

**Retorna:**
- `rax`: Número de bytes lidos (0 se EOF)

**Preserva:**
- nenhum registrador especial

**Modifica:**
- `rax`

**Exemplo:**
```asm
section .bss
    input_buffer resb 256

section .text
    mov rsi, input_buffer
    mov rdx, 256
    call read_input
    
    cmp rax, 0
    je .eof_reached
```

**Notas:**
- Usa syscall `read` (0) com file descriptor 0 (stdin)
- Bloqueia até dados estarem disponíveis
- Retorna 0 para EOF (fim de arquivo)
- Mantém o newline (\n) no buffer

---

## String Module

Manipulação e processamento de strings.

### `string_strlen(rdi)`

Calcula o comprimento de uma string.

**Sintaxe:**
```asm
mov rdi, string_address
call string_strlen
```

**Parâmetros:**
- `rdi`: Endereço de string terminada em null (\0)

**Retorna:**
- `rax`: Comprimento da string (sem contar null terminator)

**Preserva:**
- nenhum especial

**Modifica:**
- `rax`, `rcx`

**Exemplo:**
```asm
mov rdi, "teste"
call string_strlen
; rax = 5

mov rdi, ""
call string_strlen
; rax = 0
```

**Complexidade:** O(n) onde n é o comprimento

---

### `string_strcmp(rdi, rsi)`

Compara duas strings lexicograficamente.

**Sintaxe:**
```asm
mov rdi, string1_address
mov rsi, string2_address
call string_strcmp
```

**Parâmetros:**
- `rdi`: Endereço primeira string (null-terminated)
- `rsi`: Endereço segunda string (null-terminated)

**Retorna:**
- `rax`: 
  - 0 se strings são iguais
  - Negativo se string1 < string2
  - Positivo se string1 > string2

**Preserva:**
- nenhum especial

**Modifica:**
- `rax`, `rcx`

**Exemplo:**
```asm
mov rdi, "abc"
mov rsi, "abc"
call string_strcmp
; rax = 0

mov rdi, "aaa"
mov rsi, "bbb"
call string_strcmp
; rax < 0
```

**Complexidade:** O(min(n, m))

---

### `string_strchr(rdi, rsi)`

Procura um caractere dentro de uma string.

**Sintaxe:**
```asm
mov rdi, string_address
mov rsi, char_code  ; Código ASCII
call string_strchr
```

**Parâmetros:**
- `rdi`: Endereço da string para procurar
- `rsi`: Código ASCII do caractere a procurar

**Retorna:**
- `rax`: Endereço do primeiro caractere encontrado, ou 0 se não encontrado

**Preserva:**
- nenhum

**Modifica:**
- `rax`, `rcx`

**Exemplo:**
```asm
mov rdi, "olá mundo"
mov rsi, 'm'  ; Procurar 'm'
call string_strchr
; rax aponta para 'm' em "mundo"

mov rdi, "teste"
mov rsi, 'x'  ; Não existe
call string_strchr
; rax = 0
```

**Notas:**
- Retorna endereço do primeiro match
- Para múltiplos matches, chamar novamente com resultado+1

---

### `string_strrchr(rdi, rsi)`

Procura o último caractere em uma string.

**Sintaxe:**
```asm
mov rdi, string_address
mov rsi, char_code
call string_strrchr
```

**Parâmetros:**
- `rdi`: Endereço da string
- `rsi`: Código ASCII do caractere

**Retorna:**
- `rax`: Endereço do último caractere encontrado, ou 0

**Exemplo:**
```asm
mov rdi, "caminho/para/arquivo.txt"
mov rsi, '/'  ; Procurar último /
call string_strrchr
; rax aponta para o / antes de arquivo.txt
```

---

## Process Module

Gerenciamento de processos.

### `process_fork_and_exec(rdi, rsi)`

Cria novo processo filho e executa programa.

**Sintaxe:**
```asm
mov rdi, program_path  ; Ex: "/bin/ls"
mov rsi, arguments     ; Ex: "-la /tmp"
call process_fork_and_exec
```

**Parâmetros:**
- `rdi`: Caminho absoluto do programa a executar
- `rsi`: Argumentos como string única (espaços separam args)

**Retorna:**
- `rax`: 0 se sucesso, -1 se erro

**Preserva:**
- Stack preservado

**Modifica:**
- `rax`, `rdi`, `rsi` (e vários internos)

**Fluxo:**
1. Chama fork() - cria processo filho
2. Filho: Chama execve() com programa
3. Pai: Chama wait4() para aguardar filho
4. Retorna ao caller

**Exemplo:**
```asm
mov rdi, "/bin/ls"
mov rsi, "-la /tmp"
call process_fork_and_exec

cmp rax, 0
jne .error
; Sucesso - filho foi executado
```

**Notas:**
- Bloqueia até filho terminar
- Sem job control (sempre foreground)
- Sem redirecionamento de I/O
- Sem suporte a pipes

---

## Builtins Module

Comandos integrados do shell.

### `builtin_cd(rdi)`

Muda o diretório atual do processo.

**Sintaxe:**
```asm
mov rdi, path_address  ; Ex: "/tmp"
call builtin_cd
```

**Parâmetros:**
- `rdi`: Endereço da string contendo caminho (absoluto ou relativo)

**Retorna:**
- `rax`: 0 se sucesso, -1 se erro

**Preserva:**
- nenhum

**Modifica:**
- `rax`

**Exemplo:**
```asm
mov rdi, "/tmp"
call builtin_cd

cmp rax, 0
jne .cd_failed
; Sucesso

.cd_failed:
    mov rsi, error_msg
    mov rdx, error_msg_len
    call print
```

**Syscall:** chdir (80)

**Erros possíveis:**
- ENOENT: Diretório não existe
- ENOTDIR: Caminho não é diretório
- EACCES: Sem permissão de acesso

---

### `builtin_pwd()`

Exibe o diretório de trabalho atual.

**Sintaxe:**
```asm
call builtin_pwd
```

**Parâmetros:**
- nenhum

**Retorna:**
- nenhum

**Efeito:**
- Escreve o caminho completo do diretório em stdout

**Exemplo:**
```asm
call builtin_pwd
; Output: /home/usuario/bash-assembly\n
```

**Syscall:** getcwd (79)

**Buffer interno:** 256 bytes

---

### `builtin_echo(rdi, rsi)`

Imprime argumentos na saída padrão.

**Sintaxe:**
```asm
mov rdi, arguments_address
call builtin_echo
```

**Parâmetros:**
- `rdi`: Endereço de string com argumentos a imprimir

**Retorna:**
- nenhum

**Efeito:**
- Escreve argumentos em stdout com newline ao final

**Exemplo:**
```asm
mov rdi, "Olá Mundo"
call builtin_echo
; Output: Olá Mundo\n
```

---

### `builtin_help()`

Exibe ajuda dos comandos disponíveis.

**Sintaxe:**
```asm
call builtin_help
```

**Parâmetros:**
- nenhum

**Retorna:**
- nenhum

**Efeito:**
- Escreve mensagem de ajuda em stdout

**Output:**
```
=== Mini Shell - Comandos Built-in ===
cd [caminho]   - Mudar de diretório
pwd            - Mostrar diretório atual
echo [texto]   - Imprimir texto
help           - Mostrar esta ajuda
exit           - Sair do shell

Digite qualquer outro comando para executá-lo
```

---

## Utils Module

Funções utilitárias.

### `utils_atoi(rdi)`

Converte string para inteiro (base 10).

**Sintaxe:**
```asm
mov rdi, string_address  ; Ex: "42"
call utils_atoi
```

**Parâmetros:**
- `rdi`: Endereço de string contendo número decimal

**Retorna:**
- `rax`: Valor inteiro convertido

**Exemplo:**
```asm
mov rdi, "123"
call utils_atoi
; rax = 123

mov rdi, "0"
call utils_atoi
; rax = 0

mov rdi, "abc"
call utils_atoi
; rax = 0 (inválido)
```

**Notas:**
- Ignora espaços iniciais
- Retorna 0 para strings não-numéricas
- Não suporta números negativos

---

### `utils_isdigit(rax)`

Verifica se um caractere é um dígito (0-9).

**Sintaxe:**
```asm
mov al, byte [string]  ; Caractere a verificar
call utils_isdigit
```

**Parâmetros:**
- `al` (byte): Código ASCII do caractere

**Retorna:**
- `rax`:
  - 1 se é dígito (0-9)
  - 0 se não é dígito

**Exemplo:**
```asm
mov al, '5'
call utils_isdigit
; rax = 1

mov al, 'a'
call utils_isdigit
; rax = 0
```

---

## Constants

Definições em include/syscalls.inc

### Syscalls

```asm
SYS_READ       equ 0      ; read(2)
SYS_WRITE      equ 1      ; write(2)
SYS_FORK       equ 57     ; fork(2)
SYS_EXECVE     equ 59     ; execve(2)
SYS_WAIT4      equ 61     ; wait4(2)
SYS_EXIT       equ 60     ; exit(2)
SYS_CHDIR      equ 80     ; chdir(2)
SYS_GETCWD     equ 79     ; getcwd(2)
```

### File Descriptors

```asm
STDIN          equ 0      ; Entrada padrão
STDOUT         equ 1      ; Saída padrão
STDERR         equ 2      ; Saída de erro
```

### Caracteres Especiais

```asm
SPACE          equ 32     ; ' ' (espaço)
NEWLINE        equ 10     ; '\n' (quebra de linha)
```

### Limites

```asm
MAX_PATH       equ 256    ; Comprimento máximo de caminho
```

---

## Exemplos de Uso Combinado

### Exemplo 1: Listar e Imprimir

```asm
; Executar 'ls' e capturar diretório
mov rdi, "/bin/ls"
mov rsi, ""
call process_fork_and_exec

; Imprimir mensagem
mov rsi, msg
mov rdx, msg_len
call print
```

### Exemplo 2: Validar Entrada Numérica

```asm
mov rdi, user_input
call utils_atoi        ; Converter
cmp rax, 0
jne .valid
; Não é número válido
```

### Exemplo 3: Processar String com Espacos

```asm
mov rdi, input_string
call string_strlen     ; Obter tamanho
; rax = tamanho

mov rdi, input_string
mov rsi, ' '
call string_strchr     ; Procurar espaço
; rax = endereço do espaço (ou 0 se não encontrado)
```

---

## Notas de Compatibilidade

### Registradores de Preservação

| Registrador | Caller Save | Callee Save |
|-------------|:-----------:|:-----------:|
| RAX | ✓ | |
| RBX | | ✓ |
| RCX | ✓ | |
| RDX | ✓ | |
| RSI | ✓ | |
| RDI | ✓ | |
| R8-R11 | ✓ | |
| R12-R15 | | ✓ |
| RBP | | ✓ |
| RSP | | ✓ |

**Caller Save:** Função pode modificar sem salvar
**Callee Save:** Função deve preservar se usar

### Alinhamento de Stack

Antes de chamar `syscall` ou função, RSP deve estar alinhado em 16 bytes.

---

**Última atualização:** 24 de janeiro de 2026
