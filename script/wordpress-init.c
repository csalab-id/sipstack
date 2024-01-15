#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

int main() {
    char *program1 = "/usr/sbin/php-fpm83";
    char *program2 = "/usr/sbin/nginx";
    char *arguments1[] = { "/usr/sbin/php-fpm83", NULL };
    char *arguments2[] = { "/usr/sbin/nginx", "-g", "daemon off;", NULL };
    pid_t pid1 = fork();
    
    if (pid1 == 0) {
        execvp(program1, arguments1);
        perror("execvp");
        return 1;
    } else if (pid1 > 0) {
        wait(NULL);
        pid_t pid2 = fork();
        if (pid2 == 0) {
            execvp(program2, arguments2);
            perror("execvp");
            return 1;
        } else if (pid2 > 0) {
            wait(NULL);
            printf("[!] All processes finished\n");
        } else {
            perror("fork");
            return 1;
        }
    } else {
        perror("fork");
        return 1;
    }
}