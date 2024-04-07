#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <fcntl.h>

void moveFile(const char *sourcePath, const char *destinationPath)
{
    int sourceFile = open(sourcePath, O_RDONLY);
    if (sourceFile == -1)
    {
        perror("Failed to open source file");
        return;
    }
    int destinationFile = open(destinationPath, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
    if (destinationFile == -1)
    {
        perror("Failed to create destination file");
        close(sourceFile);
        return;
    }
    char buffer[BUFSIZ];
    ssize_t bytesRead;
    while ((bytesRead = read(sourceFile, buffer, BUFSIZ)) > 0)
    {
        ssize_t bytesWritten = write(destinationFile, buffer, bytesRead);
        if (bytesWritten == -1)
        {
            perror("Failed to write to destination file");
            close(sourceFile);
            close(destinationFile);
            return;
        }
    }
    close(sourceFile);
    close(destinationFile);
    if (unlink(sourcePath) != 0)
    {
        perror("Failed to remove source file");
        return;
    }
}

void moveDirectory(const char *sourcePath, const char *destinationPath)
{
    mkdir(destinationPath, 0755);
    DIR *sourceDir = opendir(sourcePath);
    if (sourceDir == NULL)
    {
        perror("Failed to open source directory\n");
        return;
    }
    struct dirent *entry;
    while ((entry = readdir(sourceDir)) != NULL)
    {
        char sourceEntryPath[PATH_MAX];
        snprintf(sourceEntryPath, PATH_MAX, "%s/%s", sourcePath, entry->d_name);
        struct stat entryInfo;
        if (lstat(sourceEntryPath, &entryInfo) != 0)
        {
            perror("Failed to get entry information\n");
            continue;
        }
        if (S_ISDIR(entryInfo.st_mode))
        {
            if (strncmp(entry->d_name, ".", NAME_MAX) == 0 || strncmp(entry->d_name, "..", NAME_MAX) == 0)
            {
                continue;
            }
            char destinationEntryPath[PATH_MAX];
            snprintf(destinationEntryPath, PATH_MAX, "%s/%s", destinationPath, entry->d_name);
            moveDirectory(sourceEntryPath, destinationEntryPath);
        }
        else
        {
            char destinationEntryPath[PATH_MAX];
            snprintf(destinationEntryPath, PATH_MAX, "%s/%s", destinationPath, entry->d_name);
            moveFile(sourceEntryPath, destinationEntryPath);
        }
    }
    closedir(sourceDir);
    rmdir(sourcePath);
}

void changeOwnershipRecursive(const char *path, uid_t owner, gid_t group)
{
    if (chown(path, owner, group) != 0)
    {
        perror("Failed to change ownership\n");
        return;
    }
    DIR *dir = opendir(path);
    if (dir == NULL)
    {
        perror("Failed to open directory\n");
        return;
    }
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL)
    {
        char entryPath[PATH_MAX];
        snprintf(entryPath, PATH_MAX, "%s/%s", path, entry->d_name);
        struct stat entryInfo;
        if (lstat(entryPath, &entryInfo) != 0)
        {
            perror("Failed to get entry information\n");
            continue;
        }
        if (S_ISDIR(entryInfo.st_mode))
        {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            {
                continue;
            }
            changeOwnershipRecursive(entryPath, owner, group);
        }
        else
        {
            if (chown(entryPath, owner, group) != 0)
            {
                perror("Failed to change ownership\n");
            }
        }
    }
    closedir(dir);
}

int main()
{
    const char *folderPath = "/usr/src/wordpress";
    const char *destinationPath = "/var/www/html";
    struct stat folderInfo;
    uid_t owner = 10000;
    gid_t group = 10000;
    if (stat(folderPath, &folderInfo) == 0 && S_ISDIR(folderInfo.st_mode))
    {
        printf("Wordpress not found in /var/www/html - copying now...\n");
        moveDirectory(folderPath, destinationPath);
        changeOwnershipRecursive(destinationPath, owner, group);
        printf("Complete! WordPress has been successfully copied to /var/www/html\n");
    }
    printf("Starting Apache...\n");
    char *args[] = {"/usr/sbin/php-fpm83", "-F", NULL};
    execvp(args[0], args);
    perror("execvp");
    return 1;
}