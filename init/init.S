// init.S - Static assembly-only init program for MeowOS
// Directly executes /bin/sh with /init.sh as argument

.section .data
# Command to execute
path:
    .string "/bin/sh"
    
# Arguments for execve
args:
    .quad arg0
    .quad arg1
    .quad 0      # NULL terminator for argv

# Environment for execve
environ:
    .quad 0      # NULL environment

# Argument strings
arg0:
    .string "/bin/sh"
arg1:
    .string "/init.sh"

# Error message if execve fails
error_msg:
    .string "Failed to execute /bin/sh\n"
error_len = . - error_msg

.section .text
.global _start

_start:
    # Call execve(path, args, environ)
    mov $path, %rdi       # First arg: path to executable
    mov $args, %rsi       # Second arg: argument array
    mov $environ, %rdx    # Third arg: environment (empty)
    mov $59, %rax         # syscall number for execve
    syscall

    # If we get here, execve failed
    # Print error message using write syscall
    mov $1, %rdi          # First arg: file descriptor (stdout)
    mov $error_msg, %rsi  # Second arg: string to write
    mov $error_len, %rdx  # Third arg: string length
    mov $1, %rax          # syscall number for write
    syscall

    # Exit with error code 1
    mov $1, %rdi          # exit code
    mov $60, %rax         # syscall number for exit
    syscall 