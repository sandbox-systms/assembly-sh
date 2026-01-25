# Mini Shell em Assembly x86-64

Um shell minimalista implementado em Assembly x86-64 puro, rodando nativamente em sistemas Linux de 64 bits. Este projeto demonstra conceitos fundamentais de programação de baixo nível, syscalls do Linux e manipulação de processos.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Características](#características)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Uso](#uso)
- [Arquitetura](#arquitetura)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Comandos Built-in](#comandos-built-in)
- [Exemplos de Uso](#exemplos-de-uso)
- [Contribuição](#contribuição)
- [Licença](#licença)

## 🎯 Visão Geral

O **Mini Shell** é uma implementação educacional de um interpretador de linha de comando (shell) em Assembly x86-64. Ele demonstra como interagir diretamente com o kernel do Linux através de syscalls, gerenciando entrada/saída, processos e funcionamento básico de um shell.

Este projeto é ideal para:
- Aprender programação em Assembly x86-64
- Entender como shells funcionam internamente
- Estudar syscalls do Linux
- Compreender gerenciamento de processos em nível de sistema operacional

## ✨ Características

- ✅ **Interface interativa com prompt** - Exibe `mini-shell>` para entrada de comandos
- ✅ **Comandos Built-in**:
  - `cd [caminho]` - Muda o diretório atual
  - `pwd` - Exibe o diretório atual
  - `echo [texto]` - Imprime texto na tela
  - `help` - Mostra ajuda dos comandos disponíveis
  - `exit` - Sai do shell
- ✅ **Execução de programas externos** - Suporta fork + execve para rodar qualquer programa do sistema
- ✅ **Gerenciamento de entrada/saída** - Lê comandos do stdin e escreve na stdout
- ✅ **Parsing de argumentos** - Processa comandos com argumentos
- ✅ **Buffering inteligente** - Processa múltiplas linhas de entrada eficientemente
- ✅ **Navegação de diretórios** - Suporta caminhos absolutos e relativos

## 📦 Requisitos

- **Sistema Operacional**: Linux (64 bits)
- **Assembler**: NASM (Netwide Assembler) - versão 2.13+
- **Linker**: GNU ld (binutils)
- **Make**: Para automação da compilação

### Instalar dependências (Ubuntu/Debian):

```bash
sudo apt-get update
sudo apt-get install nasm binutils build-essential
```

## 🚀 Instalação

1. **Clone o repositório**:
```bash
git clone https://github.com/usuario/bash-assembly.git
cd bash-assembly
```

2. **Compile o projeto**:
```bash
make
```

3. **Verifique se o executável foi criado**:
```bash
ls -la bin/minishell
```

## 💻 Uso

### Execução interativa:
```bash
./bin/minishell
```

Você verá o prompt `mini-shell>` e poderá digitar comandos:
```
mini-shell> pwd
/home/usuario/bash-assembly
mini-shell> echo Olá, Assembly!
Olá, Assembly!
mini-shell> help
=== Mini Shell - Comandos Built-in ===
cd [caminho]   - Mudar de diretório
pwd            - Mostrar diretório atual
echo [texto]   - Imprimir texto
help           - Mostrar esta ajuda
exit           - Sair do shell

Digite qualquer outro comando para executá-lo
mini-shell> exit
```

### Execução com entrada redirecionada:
```bash
echo -e "pwd\necho Teste\nexit" | ./bin/minishell
```

### Compilação e limpeza:
```bash
make       # Compila o projeto
make clean # Remove arquivos gerados (build/ e bin/)
make run   # Compila e executa
```

## 🏗️ Arquitetura

### Fluxo de Execução

```
┌─────────────────────────────────────┐
│       _start (Ponto de entrada)     │
└──────────────┬──────────────────────┘
               │
               ▼
       ┌───────────────────┐
       │  Exibir Prompt    │
       └───────────┬───────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Ler Entrada/Buffer  │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Parse Comando       │
        └──────────┬───────────┘
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
    ┌──────────────┐  ┌──────────────┐
    │ Built-in?    │  │ Fork + Execve│
    └──────┬───────┘  └──────┬───────┘
           │                 │
      Sim  │ Não             │
           │                 ▼
           │            ┌─────────────┐
           │            │ Esperar filho│
           │            └──────┬──────┘
           │                   │
           └───────────┬───────┘
                       │
                       ▼
              ┌────────────────┐
              │  Loop novamente│
              └────────────────┘
```

### Stack de Registradores

O projeto utiliza a convenção de chamada System V AMD64 ABI:

- **rax**: Retorno de função, número de syscall
- **rdi, rsi, rdx, rcx, r8, r9**: Parâmetros de função
- **rsp**: Apontador de stack
- **rbp**: Base pointer (quando necessário)
- **rbx, r12-r15**: Preservados entre chamadas

## 📁 Estrutura do Projeto

```
bash-assembly/
├── README.md              # Este arquivo
├── LICENSE               # Licença MIT
├── makefile              # Automação de compilação
├── test_input.txt        # Arquivo de entrada para testes
│
├── include/
│   └── syscalls.inc      # Definições de syscalls do Linux (x86-64)
│
├── lib/
│   ├── builtins.asm      # Implementação de comandos built-in
│   ├── builtins.inc      # Cabeçalho de funções built-in
│   ├── io.asm            # Funções de entrada/saída
│   ├── io.inc            # Cabeçalho de funções I/O
│   ├── process.asm       # Gerenciamento de processos (fork/execve/wait)
│   ├── process.inc       # Cabeçalho de funções de processo
│   ├── string.asm        # Manipulação de strings
│   ├── string.inc        # Cabeçalho de funções de string
│   ├── utils.asm         # Funções utilitárias gerais
│   └── utils.inc         # Cabeçalho de funções utilitárias
│
├── src/
│   └── minishell.asm     # Programa principal do shell
│
├── bin/                  # (Gerado na compilação)
│   └── minishell         # Executável final
│
└── build/                # (Gerado na compilação)
    ├── src/
    │   └── minishell.o   # Objeto compilado do main
    └── lib/
        ├── builtins.o
        ├── io.o
        ├── process.o
        ├── string.o
        └── utils.o
```

## 📚 Estrutura Modular

### 1. **include/syscalls.inc** - Definições de Syscalls
Contém constantes para as syscalls do Linux utilizadas pelo projeto:
- `SYS_READ` (0) - Ler dados
- `SYS_WRITE` (1) - Escrever dados
- `SYS_FORK` (57) - Criar processo filho
- `SYS_EXECVE` (59) - Executar novo programa
- `SYS_WAIT4` (61) - Aguardar processo filho
- `SYS_EXIT` (60) - Sair do programa
- `SYS_CHDIR` (80) - Mudar diretório
- `SYS_GETCWD` (79) - Obter diretório atual

### 2. **lib/io.asm** - Entrada e Saída
Implementa funções básicas de I/O:
- `print(rsi, rdx)` - Escreve dados em stdout
- `read_input(rsi, rdx)` - Lê dados de stdin

### 3. **lib/string.asm** - Manipulação de Strings
Funções para trabalhar com strings:
- `strlen()` - Calcula comprimento de string
- `strcmp()` - Compara strings
- `strchr()` - Procura caractere em string
- `strrchr()` - Procura último caractere em string
- Parsing de argumentos e tokenização

### 4. **lib/process.asm** - Gerenciamento de Processos
Implementa operações com processos:
- `fork_and_exec()` - Cria novo processo e executa programa
- Aguarda conclusão de processo filho
- Gerencia PIDs de processos

### 5. **lib/builtins.asm** - Comandos Built-in
Implementação dos comandos internos do shell:
- `builtin_cd()` - Muda diretório (syscall chdir)
- `builtin_pwd()` - Exibe diretório atual (syscall getcwd)
- `builtin_echo()` - Imprime argumentos
- `builtin_help()` - Mostra ajuda

### 6. **lib/utils.asm** - Utilitários
Funções auxiliares:
- `atoi()` - Converte string para inteiro
- `isdigit()` - Verifica se é dígito
- Funções de conversão e validação

### 7. **src/minishell.asm** - Loop Principal
Implementa o loop principal do shell:
- Exibe prompt
- Lê entrada (com suporte a buffering)
- Parse de comandos
- Routing para built-ins ou fork+exec
- Tratamento de sinais e EOF

## 🎮 Comandos Built-in

### `cd [caminho]`
Muda o diretório atual do shell.

**Sintaxe:**
```bash
mini-shell> cd /caminho/do/diretorio
mini-shell> cd ~                    # Diretório home
mini-shell> cd ..                   # Diretório pai
mini-shell> cd .                    # Diretório atual
```

**Implementação:** Usa syscall `chdir` (80)

### `pwd`
Exibe o caminho completo do diretório atual.

**Sintaxe:**
```bash
mini-shell> pwd
/home/usuario/bash-assembly
```

**Implementação:** Usa syscall `getcwd` (79)

### `echo [texto...]`
Imprime os argumentos fornecidos na tela.

**Sintaxe:**
```bash
mini-shell> echo Olá, Mundo!
Olá, Mundo!
mini-shell> echo Múltiplos argumentos
Múltiplos argumentos
```

### `help`
Exibe informações sobre os comandos disponíveis.

**Sintaxe:**
```bash
mini-shell> help
=== Mini Shell - Comandos Built-in ===
cd [caminho]   - Mudar de diretório
pwd            - Mostrar diretório atual
echo [texto]   - Imprimir texto
help           - Mostrar esta ajuda
exit           - Sair do shell

Digite qualquer outro comando para executá-lo
```

### `exit`
Encerra o shell.

**Sintaxe:**
```bash
mini-shell> exit
```

## 🔧 Programas Externos

Além dos comandos built-in, o shell pode executar qualquer programa disponível no PATH do sistema:

```bash
mini-shell> ls -la
mini-shell> cat arquivo.txt
mini-shell> whoami
usuario
mini-shell> date
Wed Jan 24 10:30:45 -03 2026
```

O shell fará fork (criar processo filho) e execve (executar novo programa), aguardando sua conclusão.

## 💡 Exemplos de Uso

### Exemplo 1: Navegação básica
```bash
$ ./bin/minishell
mini-shell> pwd
/home/usuario/bash-assembly
mini-shell> cd /tmp
mini-shell> pwd
/tmp
mini-shell> cd -
mini-shell> pwd
/home/usuario/bash-assembly
mini-shell> exit
$
```

### Exemplo 2: Uso de echo e comando externo
```bash
$ ./bin/minishell
mini-shell> echo Testando o shell
Testando o shell
mini-shell> ls
bin  build  include  lib  LICENSE  makefile  README.md  src  test_input.txt
mini-shell> exit
$
```

### Exemplo 3: Entrada redirecionada
```bash
$ cat << 'EOF' | ./bin/minishell
pwd
echo "Teste de entrada"
ls -la
exit
EOF
mini-shell> /home/usuario/bash-assembly
mini-shell> Teste de entrada
mini-shell> [listagem de arquivos]
$
```

### Exemplo 4: Teste de arquivo
```bash
$ cat test_input.txt
pwd
exit
$ ./bin/minishell < test_input.txt
mini-shell> /home/usuario/bash-assembly
$
```

## 🔍 Detalhes Técnicos

### Buffering de Entrada

O shell implementa um sistema de buffering inteligente para otimizar leituras:

1. Primeiro `read()` preenche um buffer de 1024 bytes
2. Processar linhas do buffer uma por vez
3. Quando o buffer esvaziar, ler novos dados
4. Suporta múltiplas linhas em uma única chamada de `read()`

**Vantagens:**
- Reduz syscalls (caro para o kernel)
- Melhora performance em entrada redirecionada
- Permite processar blocos de comandos eficientemente

### Parsing de Comandos

O parser divide uma linha em comando e argumentos:

```
entrada: "echo    Olá   Mundo"
                ↓
      ┌─────────┴──────────┐
      │                    │
comando: "echo"      args: "Olá Mundo"
```

### Syscalls Utilizadas

| Syscall | Número | Descrição |
|---------|--------|-----------|
| read | 0 | Lê dados de arquivo/stdin |
| write | 1 | Escreve dados em arquivo/stdout |
| fork | 57 | Cria novo processo |
| execve | 59 | Executa novo programa |
| wait4 | 61 | Aguarda processo filho |
| exit | 60 | Sai do programa |
| chdir | 80 | Muda diretório |
| getcwd | 79 | Obtém diretório atual |

### Registradores Importantes

```asm
RAX  - Retorno de syscall, número de syscall
RDI  - 1º argumento de syscall (fd)
RSI  - 2º argumento (buffer)
RDX  - 3º argumento (tamanho)
RCX  - 4º argumento
R8   - 5º argumento
R9   - 6º argumento
```

## 🐛 Debugando

Para debug, recompile com símbolos:

```bash
# Modificar ASMFLAGS no makefile para incluir -g
nasm -f elf64 -g -F dwarf src/minishell.asm
```

Depois use um debugger:

```bash
gdb ./bin/minishell
```

## 🚦 Limitações Conhecidas

- Sem suporte a pipes (`|`) ou redirecionamento (`>`, `<`)
- Sem suporte a variáveis de ambiente
- Comandos limitados a ~1024 bytes
- Sem tratamento de sinais (SIGINT, SIGTERM)
- Sem job control (background/foreground)
- Sem histórico de comandos
- Sem tab completion
- Caminhos limitados a 256 bytes

## 📈 Possibilidades de Expansão

- [ ] Implementar pipes (`|`)
- [ ] Redirecionamento de I/O (`>`, `<`, `>>`)
- [ ] Variáveis de ambiente
- [ ] Operadores lógicos (`&&`, `||`)
- [ ] Wildcards e globbing (`*`, `?`)
- [ ] Job control
- [ ] Histórico de comandos
- [ ] Tab completion
- [ ] Tratamento de sinais
- [ ] Alias de comandos
- [ ] Scripts shell
- [ ] Expansão de tilde (`~`)

## 🛠️ Processo de Desenvolvimento

### Compilação

O makefile automático compila em 2 fases:

**Fase 1: Montagem (nasm)**
```
src/minishell.asm → build/src/minishell.o
lib/*.asm → build/lib/*.o
```

**Fase 2: Ligação (ld)**
```
build/**/*.o → bin/minishell
```

### Dependências entre Módulos

```
minishell.asm
├── inclui string.inc
├── inclui io.inc
├── inclui process.inc
├── inclui builtins.inc
└── inclui utils.inc
    │
    └── Cada .inc inclui syscalls.inc
```

## 📖 Referências e Recursos

### Documentação
- [Linux man pages - syscalls](https://man7.org/linux/man-pages/man2/)
- [System V ABI AMD64 Architecture](https://gitlab.com/x86-psABIs/x86-64-ABI/)
- [NASM Manual](https://www.nasm.us/doc/)

### Tutoriais Úteis
- [x86-64 Assembly by Gustavo Duarte](http://www.duartes.org/)
- [Modern x86-64 Assembly](https://www.felixcloutier.com/x86/)
- [Linux Syscall Reference](https://filippo.io/linux-syscall-table/)

### Ferramentas
- [GDB Debugger](https://www.gnu.org/software/gdb/)
- [OBJDUMP](https://sourceware.org/binutils/docs/binutils/objdump.html)
- [STRACE](https://strace.io/)

## 👤 Autor

**Manoel E. S. S** - 2026

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

### O que você pode fazer:
- ✅ Usar comercialmente
- ✅ Modificar o código
- ✅ Distribuir
- ✅ Usar em projetos privados

### O que você deve fazer:
- ℹ️ Incluir aviso de licença e copyright
- ℹ️ Indicar mudanças feitas

### O que você NÃO pode fazer:
- ❌ Reivindicar responsabilidade por código original
- ❌ Colocar responsabilidade no autor por modificações

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor:

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -am 'Adicionar MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📧 Contato

Para dúvidas ou sugestões, abra uma issue no repositório.

---

**Última atualização**: 24 de janeiro de 2026
