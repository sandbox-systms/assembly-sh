# ========================================
# Makefile para compilação do Mini Shell
# ========================================

# Definir assembler e linker
ASM = nasm
LD = ld

# Flags para assembler
ASMFLAGS = -f elf64

# Flags para linker
LDFLAGS = -m elf_x86_64

# Arquivos fonte em Assembly
SRC = src/minishell.asm \
      lib/string.asm \
      lib/io.asm \
      lib/process.asm \
      lib/builtins.asm \
      lib/utils.asm

# Converter nomes de arquivos fonte para objetos
OBJ = $(patsubst %.asm,build/%.o,$(SRC))

# Executável final
BIN = bin/minishell

# Alvo padrão (compilar tudo)
all: $(BIN)

# Regra para compilar arquivos Assembly em objetos
build/%.o: %.asm
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) $< -o $@

# Regra para linkar objetos e criar executável
$(BIN): $(OBJ)
	@mkdir -p bin
	$(LD) $(LDFLAGS) $(OBJ) -o $@

# Limpar arquivos gerados
clean:
	rm -rf build bin

# Compilar e executar
run: all
	./$(BIN)

.PHONY: all clean run