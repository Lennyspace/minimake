#include <dirent.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    char *dossier = ".";
    if (argc == 2)
    {
        dossier = argv[1];
    }
    if (argc > 2)
    {
        return 1;
    }
    DIR *dir = opendir(dossier);

    if (dir == NULL)
    {
        fprintf(stderr, "No such fuke ir directory\n");
        return 1;
    }

    struct dirent *file = readdir(dir);
    while (file)
    {
        if (file->d_name[0] != '.')
        {
            printf("%s\n", file->d_name);
        }
        file = readdir(dir);
    }
    closedir(dir);
    return 0;
}
