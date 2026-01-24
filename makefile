ASM = nasm
LD = ld 

ASMFLAGS = -f elf64
LDFLAGS =

SRC = src/minishell.asm \
	 lib/string.asm \ 
	 lib/io.asm \ 
	 lib/process.asm 

OBJ = $(SRC:.asm=build/%.o)

BIN = bin/minishell 

all: $(BIN)

build/%.o: %.asm
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) $< -o $@

$(BIN): $(OBJ)
	@mkdir -p bin 
	$(LD) $(LDFLAGS) $< -o $@ $(BIN)

clean: rm -rf build bin 

run: all 
./$(BIN)