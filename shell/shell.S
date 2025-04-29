\
// filepath: /workspaces/codespaces-blank/moo/shell.S
.section .text
.global asm_read
.global asm_write
.global asm_fork
.global asm_execve
.global asm_wait4
.global asm_exit
.global _start   // Custom entry point for static compilation without libc
.global environ  // Export environ symbol

// Define environ - we'll initialize it in _start
.section .data
environ:
    .quad 0      // Initialize as NULL pointer

.section .text
// Custom entry point for static compilation
_start:
    // Save environment pointer from initial stack
    pop %rdi     // argc (discard)
    pop %rdi     // argv (discard)
    pop %rdi     // envp
    mov %rdi, environ(%rip)  // Save envp to our environ variable
    
    // Call main() - we're handling this directly to avoid libc
    call main
    // main's return value is in %eax, use it as exit code
    mov %eax, %edi
    mov $60, %rax  // SYS_exit
    syscall
    // No return needed

// long asm_read(int fd, char *buf, long len)
// syscall number 0: rax = 0
// arg 1 (fd):   rdi
// arg 2 (buf):  rsi
// arg 3 (len):  rdx
asm_read:
    mov $0, %rax
    syscall
    ret

// long asm_write(int fd, const char *buf, long len)
// syscall number 1: rax = 1
// arg 1 (fd):   rdi
// arg 2 (buf):  rsi
// arg 3 (len):  rdx
asm_write:
    mov $1, %rax
    syscall
    ret

// long asm_fork(void)
// syscall number 57: rax = 57
asm_fork:
    mov $57, %rax
    syscall
    ret

// long asm_execve(const char *path, char *const argv[], char *const envp[])
// syscall number 59: rax = 59
// arg 1 (path): rdi
// arg 2 (argv): rsi
// arg 3 (envp): rdx
asm_execve:
    mov $59, %rax
    syscall
    ret

// long asm_wait4(int pid, int *wstatus, int options)
// syscall number 61: rax = 61
// arg 1 (pid):     rdi
// arg 2 (wstatus): rsi
// arg 3 (options): rdx
// arg 4 (rusage):  r10 (set to 0)
asm_wait4:
    mov $61, %rax
    mov $0, %r10  // rusage = NULL
    syscall
    ret

// void asm_exit(int code)
// syscall number 60: rax = 60
// arg 1 (code): rdi
asm_exit:
    mov $60, %rax
    syscall
    // No ret needed as exit does not return
