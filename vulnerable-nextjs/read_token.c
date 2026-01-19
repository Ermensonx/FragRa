#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

/**
 * Cloud Fragment - Secure Token Reader
 * This binary enforces TTY access for the Kubernetes Service Account Token.
 * This is an anti-cheese measure to ensure players use a real shell.
 */

int main() {
    char token[4096];
    int fd;
    ssize_t n;

    // SECURITY CHECK 1: Must be an interactive terminal
    if (!isatty(STDIN_FILENO)) {
        fprintf(stderr, "\033[91m[ERROR]\033[0m Secure access denied.\n");
        fprintf(stderr, "This binary requires an interactive terminal (PTY/TTY) for session validation.\n");
        fprintf(stderr, "Direct piped execution or non-interactive RCE detected.\n");
        return 1;
    }

    // Set real UID to root (assuming setuid bit is set)
    setuid(0);

    // Read the actual token
    fd = open("/run/secrets/kubernetes.io/serviceaccount/token", O_RDONLY);
    if (fd < 0) {
        perror("open (token path)");
        return 1;
    }

    n = read(fd, token, sizeof(token) - 1);
    if (n < 0) {
        perror("read");
        close(fd);
        return 1;
    }
    
    token[n] = '\0';
    printf("%s\n", token);

    close(fd);
    return 0;
}
