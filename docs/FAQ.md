# FAQ & Troubleshooting

Perguntas frequentes e soluções para problemas comuns ao usar o Mini Shell.

## ❓ Perguntas Frequentes

### Por que Assembly?

**P: Por que fazer um shell em Assembly x86-64 ao invés de usar uma linguagem de alto nível?**

**R:** Este é um projeto educacional para:
- Aprender como linguagens de alto nível funcionam "por baixo"
- Entender como o kernel Linux funciona
- Praticar programação de baixo nível
- Demonstrar conceitos de arquitetura de computadores
- Exercício de engenharia de software com restrições

### Quanto tempo levou para fazer?

**P: Quanto tempo de desenvolvimento foi necessário?**

**R:** Depende do escopo:
- Versão básica (apenas echo + pwd): ~2-4 horas
- Versão com builtins completos: ~8-12 horas
- Com tratamento robusto de erros: ~16-20 horas

### Posso usar em produção?

**P: Posso usar este shell em um servidor de produção?**

**R:** **Não recomendado.** Motivos:
- Sem tratamento robusto de erros
- Sem job control
- Sem suporte a pipes ou redirecionamento
- Sem tratamento de sinais
- Limitações de buffer (1024 bytes)
- Sem segurança vetorial

Use bash, zsh, ou fish para produção.

### Funciona em Windows?

**P: O Mini Shell funciona em Windows?**

**R:** **Não.** O código é específico para Linux x86-64:
- Usa syscalls do Linux (não compatíveis com Windows)
- Assembly x86-64 específico para ABI de Linux
- Usa convenções de chamada do System V ABI

**Opções:**
- Use WSL 2 (Windows Subsystem for Linux)
- Use uma máquina virtual com Linux
- Use Docker
- Recompile para Windows com ajustes significativos

### Funciona em ARM?

**P: Posso compilar para ARM (Raspberry Pi)?**

**R:** **Não, não diretamente.** Razões:
- Código em Assembly x86-64 específico
- Registradores diferentes (32/64 bits)
- Syscalls diferentes
- Calling conventions diferentes

**Para ARM:**
- Seria necessário reescrever todo o Assembly
- ~60-70% do código precisaria mudar
- Possível projeto futuro

### Como estender o shell?

**P: Como adiciono meus próprios comandos?**

**R:** Veja [DEVELOPMENT.md](DEVELOPMENT.md) seção "Adicionando Novos Built-ins"

Passo a passo:
1. Implementar função em `lib/builtins.asm`
2. Exportar em `lib/builtins.inc`
3. Adicionar roteamento em `src/minishell.asm`
4. Compilar com `make`
5. Testar

Exemplo simples: adicionar comando `whoami`
```asm
builtin_whoami:
    mov rsi, msg_whoami
    mov rdx, msg_whoami_len
    call print
    ret

section .data
    msg_whoami db "user", NEWLINE, 0
    msg_whoami_len equ $ - msg_whoami
```

## 🔧 Troubleshooting

### Compilação não funciona

#### Erro: "command not found: nasm"

```bash
$ make
make: nasm: No such file or directory
```

**Solução:** Instalar NASM
```bash
# Ubuntu/Debian
sudo apt-get install nasm

# Fedora/RHEL
sudo dnf install nasm

# Verificar instalação
nasm -version
```

#### Erro: "command not found: ld"

```bash
$ make
make: ld: No such file or directory
```

**Solução:** Instalar binutils
```bash
# Ubuntu/Debian
sudo apt-get install binutils

# Fedora/RHEL
sudo dnf install binutils

# Verificar instalação
ld --version
```

#### Erro de sintaxe Assembly

```bash
$ make
nasm: error: parser: instruction expected at line 45
```

**Solução:**
1. Verificar linha 45 do arquivo
2. Verificar comentários (usar `;` não `//`)
3. Verificar instrução está correta para x86-64
4. Ver documentação NASM

```bash
# Verificar sintaxe
nasm -f elf64 -w +all src/minishell.asm
```

#### Erro de linking

```bash
$ make
ld: cannot find -lc
```

**Solução:** Nosso projeto não precisa de libc
Se usar bibliotecas C, precisa linkar:
```bash
gcc -nostdlib -o bin/minishell build/**/*.o
```

### Execução não funciona

#### O programa não inicia

```bash
$ ./bin/minishell
Segmentation fault (core dumped)
```

**Debugar:**
```bash
# Com strace
strace ./bin/minishell

# Com gdb
gdb ./bin/minishell
(gdb) run
(gdb) bt  # Backtrace
```

**Causas comuns:**
- Stack não alinhado corretamente
- Registrador RSP corrompido
- Memória não inicializada

#### Nenhuma saída

```bash
$ ./bin/minishell
[sem prompt, sem resposta]
```

**Possíveis causas:**
1. Stdout buffered
2. Deadlock esperando entrada
3. Syscall bloqueado

**Verificar:**
```bash
# Com timeout
timeout 2 ./bin/minishell

# Com strace
strace -e write ./bin/minishell
```

#### Comando não encontrado

```bash
mini-shell> ls
[sem saída]
```

**Verificar:**
```bash
# É um built-in?
mini-shell> pwd      # Deve funcionar (built-in)

# Programa existe?
which ls
/bin/ls

# Usar caminho absoluto
mini-shell> /bin/ls  # Deve funcionar
```

**Causa:** O shell procura `ls` no PATH
- Só suporta caminhos absolutos atualmente
- Veja limitações conhecidas em README.md

### Comportamento inesperado

#### Comando não responde

```bash
mini-shell> sleep 10
[esperando...]
```

**Comportamento esperado:** O shell aguarda a conclusão

Se não retornar após alguns segundos:
```bash
# Pressionar Ctrl+C para interromper
```

Se Ctrl+C não funcionar:
- Projeto não implementa tratamento de sinais SIGINT
- Abrir outro terminal:
  ```bash
  ps aux | grep minishell
  kill -9 <PID>
  ```

#### Buffer overflow com entrada grande

```bash
# Gerar 1500 bytes
python3 -c "print('echo ' + 'A' * 1500)" | ./bin/minishell
[comportamento imprevisível]
```

**Limitação conhecida:** Buffer de 1024 bytes

**Solução:**
1. Aumentar tamanho em minishell.asm
2. Recompilar
3. Testar

```asm
; Mudar de 1024 para 4096
buffer resb 4096
```

#### Cores ANSI não funcionam

```bash
mini-shell> echo -e "\033[31mVermelho\033[0m"
[não mostra cor]
```

**Causa:** `echo` simples não interpreta sequências de escape

**Workaround:**
```bash
# Usar comando externo
mini-shell> /bin/echo -e "\033[31mVermelho\033[0m"
```

#### Caracteres especiais quebram

```bash
mini-shell> echo "teste 'aspas'"
[erro ou saída estranha]
```

**Causa:** Processamento ingênuo de argumentos

**Limitação:** Sem suporte adequado a quoting

**Workaround:** Usar argumentos simples
```bash
mini-shell> echo teste aspas
```

### Performance

#### Shell lento com entrada grande

```bash
# 10000 comandos
python3 -c "for i in range(10000): print('pwd')" | time ./bin/minishell > /dev/null
```

**Esperado:** ~2-5 segundos

Se muito mais lento:
1. Verificar capacidade do sistema
2. Verificar disco (SSD vs HDD)
3. Verificar carga do sistema

**Otimizar:**
- O buffering já é implementado
- Syscalls são minimizados
- Melhorias adicionais requerem reescrever o parser

#### Uso alto de CPU

```bash
top
[minishell usando 100% CPU]
```

**Possível causa:** Loop infinito não intencional

**Debugar:**
```bash
strace -c ./bin/minishell < test_input.txt
# Ver quais syscalls estão sendo chamadas frequentemente
```

### Plataforma específica

#### No WSL (Windows Subsystem for Linux)

**Funciona?** Sim, normalmente funciona bem

**Se tiver problemas:**
```bash
# Verificar versão do WSL
wsl --version

# Atualizar
wsl --update

# Usar WSL 2 em vez de WSL 1
wsl --list -v
```

#### No container Docker

**Dockerfile simples:**
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y nasm binutils
WORKDIR /app
COPY . .
RUN make
CMD ["./bin/minishell"]
```

**Construir e rodar:**
```bash
docker build -t minishell .
docker run -it minishell
```

#### Em distribuições Linux antigas

**Problema:** Estruturas kernel podem ser diferentes

**Verificar versão:**
```bash
uname -a
# x86_64 required
# kernel > 2.6 required
```

**Se antigo:** Pode precisar adaptar syscalls

## 📊 Diagnóstico

### Script de diagnóstico

Criar `diagnose.sh`:

```bash
#!/bin/bash

echo "=== Mini Shell Diagnóstico ==="
echo ""

echo "1. Verificar ferramentas:"
which nasm && echo "  ✓ NASM encontrado" || echo "  ✗ NASM não encontrado"
which ld && echo "  ✓ LD encontrado" || echo "  ✗ LD não encontrado"
which gdb && echo "  ✓ GDB encontrado" || echo "  ✗ GDB não encontrado"

echo ""
echo "2. Verificar SO:"
uname -a

echo ""
echo "3. Tentar compilar:"
if make clean && make; then
    echo "  ✓ Compilação bem-sucedida"
else
    echo "  ✗ Compilação falhou"
    exit 1
fi

echo ""
echo "4. Testar execução básica:"
if timeout 2 ./bin/minishell < test_input.txt > /dev/null 2>&1; then
    echo "  ✓ Execução bem-sucedida"
else
    echo "  ✗ Execução falhou"
    exit 1
fi

echo ""
echo "Diagnóstico completo!"
```

**Executar:**
```bash
chmod +x diagnose.sh
./diagnose.sh
```

## 📞 Obtendo Ajuda

### Antes de reportar um bug:

1. ✅ Executar diagnóstico (veja acima)
2. ✅ Verificar FAQ (este arquivo)
3. ✅ Verificar [README.md](README.md)
4. ✅ Verificar [DEVELOPMENT.md](DEVELOPMENT.md)
5. ✅ Testar em outro sistema se possível
6. ✅ Coletar informações:
   ```bash
   uname -a
   nasm --version
   ld --version
   ./diagnose.sh
   ```

### Reportar um bug

Incluir:
1. Descrição do problema
2. Passos para reproduzir
3. Saída do diagnóstico
4. Erro/log completo
5. Seu SO e versão

### Adicionar feature

Sugerir:
1. Problema que resolve
2. Como seria usado
3. Não quebrar compatibilidade
4. Manter simplicidade (Assembly é verbose)

---

**Última atualização:** 24 de janeiro de 2026
