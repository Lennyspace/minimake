#include <stddef.h>
#include <stdio.h>
#include <sys/stat.h>

int main(int argc, char *argv[])
{
    if (argc == 1)
        return 0;

    for (int i = 1; i < argc; i++)
    {
        char *filepath = argv[i];

        struct stat stats;
        if (stat(filepath, &stats) == -1)
        {
            fprintf(stderr, "stat on %s failed\n", filepath);
            return 1;
        }
        long a = stats.st_dev;
        printf("st_dev=%ld\n", a);

        a = stats.st_ino;
        printf("st_ino=%ld\n", a);

        printf("st_mode=%#o\n", stats.st_mode);

        a = stats.st_nlink;
        printf("st_nlink=%ld\n", a);

        a = stats.st_uid;
        printf("st_uid=%ld\n", a);

        a = stats.st_gid;
        printf("st_gid=%ld\n", a);

        a = stats.st_rdev;
        printf("st_rdev=%ld\n", a);

        a = stats.st_size;
        printf("st_size=%ld\n", a);

        a = stats.st_atime;
        printf("st_atime=%ld\n", a);

        a = stats.st_mtime;
        printf("st_mtime=%ld\n", a);

        a = stats.st_ctime;
        printf("st_ctime=%ld\n", a);

        a = stats.st_blksize;
        printf("st_blksize=%ld\n", a);

        a = stats.st_blocks;
        printf("st_blocks=%ld\n", a);
    }
    return 0;
}
