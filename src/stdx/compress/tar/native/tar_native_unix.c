/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

#include <sys/types.h>
#include <sys/stat.h>
#if defined(__linux__)
#include <sys/sysmacros.h>   // Only linux need this
#endif
#include <pwd.h>
#include <grp.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <utime.h>
#include <time.h>
#include <stdint.h>
extern int32_t CJ_TAR_GetMode(const char *path) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    return (int32_t)(st.st_mode & 07777);
}

extern int32_t CJ_TAR_GetUid(const char *path) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    return (int32_t)st.st_uid;
}

extern int32_t CJ_TAR_GetGid(const char *path) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    return (int32_t)st.st_gid;
}

extern char *CJ_TAR_GetUserName(const char *path) {
    if (!path) {
        return NULL;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return NULL;
    }
    struct passwd *pw = getpwuid(st.st_uid);
    if (!pw) {
        return "";
    }
    return pw->pw_name;
}

extern char *CJ_TAR_GetGroupName(const char *path) {
    if (!path) {
        return NULL;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return NULL;
    }
    struct group *gr = getgrgid(st.st_gid);
    if (!gr) {
        return "";
    }
    return gr->gr_name;
}

extern int32_t CJ_TAR_GetDeviceMajor(const char *path) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    return (int32_t)major(st.st_rdev);
}

extern int32_t CJ_TAR_GetDeviceMinor(const char *path) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    return (int32_t)minor(st.st_rdev);
}

extern int CJ_TAR_SetMode(const char *path, int32_t mode) {
    if (!path) {
        return -1;
    }
    if (chmod(path, (mode_t)mode) != 0) {
        return -1;
    }
    return 0;
}

extern int CJ_TAR_SetUid(const char *path, int32_t uid) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    if (lchown(path, (uid_t)uid, st.st_gid) != 0) {
        return -1;
    }
    return 0;
}

extern int CJ_TAR_SetGid(const char *path, int32_t gid) {
    if (!path) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    if (lchown(path, st.st_uid, (gid_t)gid) != 0) {
        return -1;
    }
    return 0;
}

extern int CJ_TAR_SetUserName(const char *path, const char *username) {
    if (!path || !username) {
        return -1;
    }
    struct passwd *pw = getpwnam(username);
    if (!pw) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    if (lchown(path, pw->pw_uid, st.st_gid) != 0) {
        return -1;
    }
    return 0;
}

extern int CJ_TAR_SetGroupName(const char *path, const char *groupname) {
    if (!path || !groupname) {
        return -1;
    }
    struct group *gr = getgrnam(groupname);
    if (!gr) {
        return -1;
    }
    struct stat st;
    if (lstat(path, &st) != 0) {
        return -1;
    }
    if (lchown(path, st.st_uid, gr->gr_gid) != 0) {
        return -1;
    }
    return 0;
}

extern int CJ_TAR_SetModificationTime(const char *path, int64_t timestamp) {
    struct stat st;
    if (stat(path, &st) != 0) {
        return -1;
    }

    struct utimbuf times;
    times.actime = st.st_atime;
    times.modtime = (time_t)timestamp;
    return utime(path, &times);
}

extern int CJ_TAR_SetAccessTime(const char *path, int64_t timestamp) {
    struct stat st;
    if (stat(path, &st) != 0) {
        return -1;
    }

    struct utimbuf times;
    times.actime = (time_t)timestamp;
    times.modtime = st.st_mtime;
    return utime(path, &times);
}
