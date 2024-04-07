#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>

void moveDirectory(const char* sourcePath, const char* destinationPath) {
    mkdir(destinationPath, 0755);
    DIR* sourceDir = opendir(sourcePath);
    if (sourceDir == NULL) {
        perror("Failed to open source directory\n");
        return;
    }
    struct dirent* entry;
    while ((entry = readdir(sourceDir)) != NULL) {
        char sourceEntryPath[PATH_MAX];
        snprintf(sourceEntryPath, PATH_MAX, "%s/%s", sourcePath, entry->d_name);
        struct stat entryInfo;
        if (lstat(sourceEntryPath, &entryInfo) != 0) {
            perror("Failed to get entry information\n");
            continue;
        }
        if (S_ISDIR(entryInfo.st_mode)) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
                continue;
            }
            char destinationEntryPath[PATH_MAX];
            snprintf(destinationEntryPath, PATH_MAX, "%s/%s", destinationPath, entry->d_name);
            moveDirectory(sourceEntryPath, destinationEntryPath);
        } else {
            char destinationEntryPath[PATH_MAX];
            snprintf(destinationEntryPath, PATH_MAX, "%s/%s", destinationPath, entry->d_name);
            if (rename(sourceEntryPath, destinationEntryPath) != 0) {
                perror("Failed to move file\n");
            }
        }
    }
    closedir(sourceDir);
    rmdir(sourcePath);
}

void changeOwnershipRecursive(const char* path, uid_t owner, gid_t group) {
    if (chown(path, owner, group) != 0) {
        perror("Failed to change ownership\n");
        return;
    }
    DIR* dir = opendir(path);
    if (dir == NULL) {
        perror("Failed to open directory\n");
        return;
    }
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        char entryPath[PATH_MAX];
        snprintf(entryPath, PATH_MAX, "%s/%s", path, entry->d_name);
        struct stat entryInfo;
        if (lstat(entryPath, &entryInfo) != 0) {
            perror("Failed to get entry information\n");
            continue;
        }
        if (S_ISDIR(entryInfo.st_mode)) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
                continue;
            }
            changeOwnershipRecursive(entryPath, owner, group);
        } else {
            if (chown(entryPath, owner, group) != 0) {
                perror("Failed to change ownership\n");
            }
        }
    }
    closedir(dir);
}

int main() {
    const char* folderPath = "/usr/src/wordpress";
    const char* destinationPath = "/var/www/localhost/htdocs";
    struct stat folderInfo;
    uid_t owner = 10000;
    gid_t group = 10000;
    if (stat(folderPath, &folderInfo) == 0 && S_ISDIR(folderInfo.st_mode)) {
        printf("Wordpress not found in /var/www/localhost/htdocs - copying now...\n");
        moveDirectory(folderPath, destinationPath);
        changeOwnershipRecursive(destinationPath, owner, group);
        printf("Complete! WordPress has been successfully copied to /var/www/localhost/htdocs\n");
    }
    printf("Starting Apache...\n");
    char *args[] = {"/usr/sbin/httpd", "-DFOREGROUND", NULL};
    execvp(args[0], args);
    perror("execvp");
    return 1;
}