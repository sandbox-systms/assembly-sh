# CHANGELOG & Project History

História do desenvolvimento e mudanças do Mini Shell.

## 📅 Versão Atual: 1.1 (10 de maio de 2026)

### ✨ Novas Características v1.1

#### Interface do Usuário Aprimorada
- [x] Prompt colorido com emoji 💻 e formato `user@machine`
- [x] Códigos ANSI para realce visual
- [x] Símbolos visuais em listagens ([DIR], [FILE], [UNK])

#### Novos Comandos Built-in
- [x] `ls` - Listagem colorida de arquivos com símbolos
- [x] `clear` - Limpeza da tela do terminal

#### Melhorias na Arquitetura
- [x] Implementação de `getdents64` para listagem de diretórios
- [x] Syscall `stat` para identificação de tipos de arquivo
- [x] Buffers otimizados para operações de I/O
- [x] Modularização aprimorada com novas funções auxiliares

#### Documentação Acadêmica
- [x] README.md reestruturado em estilo de software de pesquisa
- [x] Seções: Abstract, Introdução, Metodologia, Implementação, Resultados, Conclusão
- [x] Referências a trabalhos relacionados
- [x] Documentação técnica expandida

### 📈 Melhorias de Performance

- **Interface Visual**: Navegação mais intuitiva com cores e símbolos
- **Funcionalidade**: 7 comandos built-in (vs 5 na v1.0)
- **Usabilidade**: Prompt informativo e ajuda contextual
- **Manutenibilidade**: Código mais organizado e documentado

### 🔄 Mudanças Internas

- Adição de syscalls: `SYS_OPEN`, `SYS_CLOSE`, `SYS_STAT`, `SYS_GETDENTS64`
- Implementação de funções: `get_file_type`, `print_colored_name`
- Buffers adicionais: `dents_buffer`, `stat_buf`
- Constantes ANSI para cores e símbolos

## 📅 Versão 1.0 (24 de janeiro de 2026)

#### Core Shell
- [x] Loop interativo com prompt `mini-shell>`
- [x] Leitura inteligente com buffering (1024 bytes)
- [x] Parsing de comandos com suporte a argumentos
- [x] Routing automático (built-in vs execução de programa)
- [x] Tratamento de EOF

#### Comandos Built-in
- [x] `cd [caminho]` - Trocar diretório
- [x] `pwd` - Mostrar diretório atual
- [x] `echo [texto]` - Imprimir texto
- [x] `help` - Mostrar ajuda
- [x] `exit` - Sair do shell

#### Execução de Programas Externos
- [x] Fork + Execve automático
- [x] Aguardar conclusão de processo filho
- [x] Suporte a argumentos em programas externos

#### Módulos e Arquitetura
- [x] Modularização em 5 bibliotecas
- [x] Separação clara de responsabilidades
- [x] Cabeçalhos `.inc` com interfaces públicas
- [x] Syscalls diretas do Linux (x86-64)

#### Documentação
- [x] README.md abrangente
- [x] ARCHITECTURE.md - Detalhes técnicos
- [x] DEVELOPMENT.md - Guia para desenvolvedores
- [x] API.md - Referência de funções
- [x] FAQ.md - Perguntas e troubleshooting
- [x] CHANGELOG.md - Este arquivo

#### Build System
- [x] Makefile automático
- [x] Compilação de múltiplos arquivos
- [x] Linking automático
- [x] Targets: all, clean, run

### 🐛 Limitações Conhecidas

- ❌ Sem suporte a pipes (`|`)
- ❌ Sem redirecionamento (`>`, `<`, `>>`)
- ❌ Sem variáveis de ambiente
- ❌ Sem tratamento de sinais (SIGINT, SIGTERM)
- ❌ Sem job control (background/foreground)
- ❌ Sem histórico de comandos
- ❌ Sem tab completion
- ❌ Sem wildcards (`*`, `?`, `[...]`)
- ❌ Buffer limitado a 1024 bytes
- ❌ Caminhos limitados a 256 bytes

### 📦 Estrutura do Projeto

```
bash-assembly/
├── README.md              # Documentação principal
├── ARCHITECTURE.md        # Arquitetura técnica
├── DEVELOPMENT.md         # Guia de desenvolvimento
├── API.md                # Referência de funções
├── FAQ.md                # Perguntas frequentes
├── CHANGELOG.md          # Este arquivo
├── LICENSE               # Licença MIT
├── makefile              # Build automation
├── test_input.txt        # Arquivo de teste
├── include/
│   └── syscalls.inc      # Definições de syscalls
├── lib/
│   ├── builtins.asm      # Comandos internos
│   ├── builtins.inc
│   ├── io.asm            # Entrada/saída
│   ├── io.inc
│   ├── process.asm       # Gerenciamento de processos
│   ├── process.inc
│   ├── string.asm        # Manipulação de strings
│   ├── string.inc
│   ├── utils.asm         # Funções utilitárias
│   └── utils.inc
└── src/
    └── minishell.asm     # Programa principal
```

### 📊 Estatísticas de Código

| Métrica | Valor |
|---------|-------|
| Linhas de Assembly | ~1400 |
| Funções Públicas | 15 |
| Módulos | 5 |
| Documentação (Markdown) | ~5000 linhas |
| Tamanho do Executável | ~8 KB |

### 🎯 Objetivos Atingidos

- ✅ Shell funcional em Assembly x86-64 puro
- ✅ Código educacional bem documentado
- ✅ Arquitetura modular e extensível
- ✅ Zero dependências externas
- ✅ Compilação automática com make

---

## 🚀 Roadmap Futuro

### Versão 1.1 (Próximos passos recomendados)

#### Built-ins Adicionais
- [ ] `cd -` - Volta ao diretório anterior
- [ ] `cd ~` - Va para home directory
- [ ] `clear` - Limpa a tela
- [ ] `date` - Mostra data/hora
- [ ] `whoami` - Mostra usuário atual

#### Melhorias de I/O
- [ ] Tratamento de SIGINT (Ctrl+C)
- [ ] Tratamento de SIGTERM
- [ ] Tratamento adequado de SIGCHLD

#### Parsing Avançado
- [ ] Suporte a aspas duplas
- [ ] Suporte a aspas simples
- [ ] Escape de caracteres especiais
- [ ] Variáveis de ambiente ($VAR)

#### Features de Shell
- [ ] Pipes (`|`)
- [ ] Redirecionamento de saída (`>`)
- [ ] Redirecionamento de entrada (`<`)
- [ ] Append (`>>`)
- [ ] Operadores lógicos (`&&`, `||`, `;`)

#### Performance e Estabilidade
- [ ] Buffer dinâmico (não fixo em 1024)
- [ ] Tratamento robusto de erros
- [ ] Validação de limites
- [ ] Memory safety

### Versão 2.0 (Expansão Significativa)

#### Funcionalidades Avançadas
- [ ] Job control (background/foreground)
- [ ] Histórico de comandos (história)
- [ ] Tab completion
- [ ] Wildcards e globbing
- [ ] Expansão de tilde (~)

#### Novos Built-ins
- [ ] `alias` - Criar alias de comandos
- [ ] `export` - Variáveis de ambiente
- [ ] `source`/`.` - Executar scripts
- [ ] `history` - Ver histórico
- [ ] `fg`/`bg` - Job control
- [ ] `jobs` - Listar jobs

#### Scripts Shell
- [ ] Suporte a arquivos `.sh`
- [ ] Condicionals (`if`/`else`)
- [ ] Loops (`for`, `while`, `until`)
- [ ] Funções
- [ ] Argumentos de script (`$0`, `$1`, etc)

### Versão 3.0+ (Longo Prazo)

- [ ] Suporte a múltiplas arquiteturas (ARM, etc)
- [ ] Compatibilidade com bash scripts
- [ ] Sistema de plugins
- [ ] Modo gráfico opcional
- [ ] Integração com linguagens de script

---

## 🔍 Histórico de Commits (Conceitual)

### Fase 1: Foundation (Base)
- Estrutura inicial do projeto
- Makefile e build system
- Módulos básicos de I/O
- Loop principal simples

### Fase 2: Built-ins
- Implementar cd
- Implementar pwd
- Implementar echo
- Implementar help
- Roteamento de comandos

### Fase 3: Programas Externos
- Syscalls fork/execve
- wait4 para sincronização
- Argumentos para execução

### Fase 4: Otimizações
- Buffering inteligente
- Parser melhorado
- Tratamento de erros

### Fase 5: Documentação
- README completo
- Documentação técnica
- Guia de desenvolvimento
- Referência de API
- FAQ e troubleshooting

---

## 📈 Evolução de Features

```
v1.0 (Atual)
├── echo         ✓
├── pwd          ✓
├── cd           ✓
├── help         ✓
├── exit         ✓
└── ext programs ✓

v1.1 (Planejado)
├── Mais built-ins
├── Tratamento de sinais
└── Parser melhorado

v2.0+ (Futuro)
├── Job control
├── Histórico
├── Scripts shell
├── Aliases
└── Pipes & redirecionamento
```

---

## 🎓 Lições Aprendidas

### O que funcionou bem:
1. **Modularização**: Separar em módulos facilitou manutenção
2. **Documentação early**: Bem-documentado desde o início
3. **Arquitetura simples**: Sem over-engineering
4. **Testes constantes**: Testar frequentemente
5. **Limitar escopo**: v1.0 focou no essencial

### Desafios encontrados:
1. **Syscalls**: Exigem leitura cuidadosa de documentação
2. **Stack alignment**: x86-64 ABI é restritivo
3. **Assembly verbosity**: Código Assembly é muito texto
4. **Debugging**: GDB ajuda, mas ainda é difícil
5. **Portabilidade**: Linux x86-64 é muito específico

### Decisões arquiteturais:
1. **Sem libc**: Chamadas diretas ao kernel
2. **Buffer fixo**: Simples, não dinâmico
3. **Sem job control**: Mantém simplicidade
4. **Modules com includes**: Assembly não tem packages
5. **Global entry point**: Simplifica

---

## 🙋 Como Contribuir

### Para relatórios de bugs:

1. Descrever problema claramente
2. Fornecer passos para reproduzir
3. Incluir saída de erro
4. Mencionar SO e versão

### Para sugestões de features:

1. Abrir issue com discussão
2. Descrever caso de uso
3. Explicar benefício
4. Manter simplicidade em mente

### Para pull requests:

1. Fork o repositório
2. Criar branch descritivo
3. Fazer mudanças bem documentadas
4. Testar thoroughly
5. Enviar PR com descrição clara

---

## 📄 Notas de Release

### v1.0 - Release Inicial
**Data:** 24 de janeiro de 2026

**Highlights:**
- Shell funcional em Assembly puro
- 5 comandos built-in essenciais
- Suporte a programas externos
- Documentação completa
- Build automático

**Status:** Stable, Production-ready para aprendizado

**Download:** GitHub Release v1.0

**Notas de Instalação:**
```bash
git clone https://github.com/usuario/bash-assembly.git
cd bash-assembly
make
./bin/minishell
```

---

## 🤝 Agradecimentos

### Inspirações
- Linux source code
- MIT 6.828 (OS course)
- Berkeley CS61C

### Ferramentas Usadas
- NASM Assembler
- GNU Binutils
- GDB Debugger
- Linux kernel documentation

### Comunidade
- Stack Overflow
- Linux man pages
- GitHub community

---

## 📞 Contato e Support

**Autor:** Manoel E. S. S

**Email:** [seu email]

**GitHub:** [seu repositório]

**Issues:** Use GitHub Issues para reportar bugs

**Discussions:** Use GitHub Discussions para perguntas

---

## 📚 Referências de Versionamento

Segue [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (v1.0 → v2.0): Breaking changes
- **MINOR** (v1.0 → v1.1): New features, backward compatible
- **PATCH** (v1.0 → v1.0.1): Bug fixes

---

**Última atualização:** 24 de janeiro de 2026

**Próxima revisão planejada:** 30 de janeiro de 2026
