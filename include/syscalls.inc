%ifndef SYSCALLS_INC
%define SYSCALLS_INC

; Definições de syscalls para x86-64 (Linux)
%define SYS_READ       0      ; Leitura de arquivo
%define SYS_WRITE      1      ; Escrita em arquivo
%define SYS_FORK      57      ; Criar novo processo
%define SYS_EXECVE    59      ; Executar programa
%define SYS_WAIT4     61      ; Aguardar conclusão de processo filho
%define SYS_EXIT      60      ; Sair do programa
%define SYS_CHDIR     80      ; Mudar diretório
%define SYS_GETCWD    79      ; Obter diretório atual

; Definições de file descriptors
%define STDIN         0       ; Entrada padrão
%define STDOUT        1       ; Saída padrão
%define STDERR        2       ; Saída de erro

; Constantes úteis
%define MAX_PATH      256     ; Tamanho máximo de caminho
%define SPACE         32      ; Código ASCII para espaço
%define NEWLINE       10      ; Código ASCII para quebra de linha

%endif