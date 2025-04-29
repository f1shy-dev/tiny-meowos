// shell.c - Fully self-contained with no standard library dependencies

#define MAX_CMD 512
#define MAX_ARGS 32

// Define our own environ variable
extern char **environ;

// Declare external assembly functions
extern long asm_read(int fd, char *buf, long len);
extern long asm_write(int fd, const char *buf, long len);
extern long asm_fork(void);
extern long asm_execve(const char *path, char *const argv[], char *const envp[]);
extern long asm_wait4(int pid, int *wstatus, int options);
extern void asm_exit(int code);

// Custom implementation of strcmp to avoid string.h dependency
static int my_strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char *)s1 - *(unsigned char *)s2;
}

int main(void) {
    char buf[MAX_CMD];
    char *argv[MAX_ARGS+1];
    const char *prompt = "> ";

    while (1) {
        asm_write(1, prompt, 2);

        long n = asm_read(0, buf, MAX_CMD);
        if (n <= 0) break;            // EOF or error
        if (buf[n-1] == '\n') buf[n-1] = 0;
        else buf[n] = 0;

        // split into argv[]
        int argc = 0;
        char *p = buf;
        while (*p && argc < MAX_ARGS) {
            // skip whitespace
            while (*p == ' ' || *p == '\t') *p++ = 0;
            if (!*p) break;
            argv[argc++] = p;
            while (*p && *p != ' ' && *p != '\t') p++;
        }
        argv[argc] = 0;
        if (argc == 0) continue;

        if (my_strcmp(argv[0], "cowsay") == 0) {
            char msg[MAX_CMD];
            int len = 0;
            // join all args into msg
            for (int i = 1; argv[i]; i++) {
            for (int j = 0; argv[i][j]; j++)
                msg[len++] = argv[i][j];
            if (argv[i+1])
                msg[len++] = ' ';
            }
            msg[len] = 0;

            // top border
            asm_write(1, " ", 1);
            for (int i = 0; i < len + 2; i++) asm_write(1, "_", 1);
            asm_write(1, "\n", 1);

            // message line
            asm_write(1, "< ", 2);
            asm_write(1, msg, len);
            asm_write(1, " >", 2);
            asm_write(1, "\n", 1);

            // bottom border
            asm_write(1, " ", 1);
            for (int i = 0; i < len + 2; i++) asm_write(1, "-", 1);
            asm_write(1, "\n", 1);

            // cow
            asm_write(1, "        \\   ^__^\n", 18);
            asm_write(1, "         \\  (oo)\\_______\n", 24);
            asm_write(1, "            (__)\\       )\\/\\\n", 30);
            asm_write(1, "                ||----w |\n", 24);
            asm_write(1, "                ||     ||\n", 24);

            continue;
        }

        long pid = asm_fork();
        if (pid < 0) {
            // fork failed
            continue;
        }
        if (pid == 0) {
            // child
            asm_execve(argv[0], argv, environ);
            // if execve fails:
            asm_exit(1);
        } else {
            int status;
            asm_wait4(pid, &status, 0);
        }
    }

    asm_exit(0);
    return 0;
}