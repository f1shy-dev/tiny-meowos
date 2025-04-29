#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    char *const argv[] = {"/bin/sh", "/init.sh", NULL};
    char *const envp[] = {NULL};

    if (execve("/bin/sh", argv, envp) == -1) {
        perror("Failed to execute init.sh");
        return 1;
    }

    return 0;
}