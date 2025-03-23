#define RM_MAX_PATH 1024

// Flags for rm command
#define RM_FLAG_FORCE     1 << 0  // -f: ignore nonexistent files, never prompt
#define RM_FLAG_RECURSIVE 1 << 1  // -r: remove directories and their contents recursively
#define RM_FLAG_VERBOSE   1 << 2  // -v: explain what is being done
#define RM_FLAG_NOERROR   1 << 3  // Don't report errors on failure

// Remove a single file
Bool RemoveFile(U8 *path, I64 flags) {
  // Check if file exists
  if (!FileExists(path) && !DirExists(path)) {
    if (!(flags & RM_FLAG_FORCE))
      "rm: cannot remove '%s': No such file or directory\n", path;
    return (flags & RM_FLAG_FORCE);
  }

  // Try to remove the file
  if (FileDelete(path)) {
    if (flags & RM_FLAG_VERBOSE)
      "removed '%s'\n", path;
    return TRUE;
  } else {
    if (!(flags & RM_FLAG_NOERROR))
      "rm: cannot remove '%s': Permission denied\n", path;
    return FALSE;
  }
}

// Remove a directory and its contents recursively
Bool RemoveDirectoryRecursive(U8 *path, I64 flags) {
  CDirEntry de;
  I64 dir;
  U8 full_path[RM_MAX_PATH];
  
  // Open directory
  dir = DirOpen(path);
  if (dir < 0) {
    if (!(flags & RM_FLAG_FORCE))
      "rm: cannot remove '%s': Is a directory\n", path;
    return FALSE;
  }
  
  // Process each entry
  while (DirNext(dir, &de)) {
    if (!StrCmp(de.name, ".") || !StrCmp(de.name, ".."))
      continue;
    
    StrPrint(full_path, "%s/%s", path, de.name);
    
    if (de.attr & RS_ATTR_DIR) {
      // Recursively remove subdirectory
      if (!RemoveDirectoryRecursive(full_path, flags | RM_FLAG_NOERROR)) {
        DirClose(dir);
        return FALSE;
      }
    } else {
      // Remove file
      if (!RemoveFile(full_path, flags | RM_FLAG_NOERROR)) {
        DirClose(dir);
        return FALSE;
      }
    }
  }
  
  DirClose(dir);
  
  // Try to remove the now-empty directory
  if (DirDel(path)) {
    if (flags & RM_FLAG_VERBOSE)
      "removed directory '%s'\n", path;
    return TRUE;
  } else {
    if (!(flags & RM_FLAG_NOERROR))
      "rm: cannot remove '%s': Directory not empty or permission denied\n", path;
    return FALSE;
  }
}

// Remove a file or directory
Bool Remove(U8 *path, I64 flags) {
  // Check if the path is a directory
  if (DirExists(path)) {
    if (!(flags & RM_FLAG_RECURSIVE)) {
      // Cannot remove directory without -r flag
      "rm: cannot remove '%s': Is a directory\n", path;
      return FALSE;
    }
    
    return RemoveDirectoryRecursive(path, flags);
  } else {
    // Regular file or does not exist
    return RemoveFile(path, flags);
  }
}

// Main rm function
U0 Rm(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: rm [OPTION]... FILE...\n";
    "Remove (unlink) the FILE(s).\n\n";
    "  -f, --force           ignore nonexistent files, never prompt\n";
    "  -r, -R, --recursive   remove directories and their contents recursively\n";
    "  -v, --verbose         explain what is being done\n";
    "      --help            display this help and exit\n";
    return;
  }

  I64 i, flags = 0;
  Bool success = TRUE;
  
  // Parse command-line arguments
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-' && argv[i][1] != 0) {
      // Option argument
      if (!StrCmp(argv[i], "--help")) {
        "Usage: rm [OPTION]... FILE...\n";
        "Remove (unlink) the FILE(s).\n\n";
        "  -f, --force           ignore nonexistent files, never prompt\n";
        "  -r, -R, --recursive   remove directories and their contents recursively\n";
        "  -v, --verbose         explain what is being done\n";
        "      --help            display this help and exit\n";
        return;
      } else if (!StrCmp(argv[i], "--force")) {
        flags |= RM_FLAG_FORCE;
      } else if (!StrCmp(argv[i], "--recursive")) {
        flags |= RM_FLAG_RECURSIVE;
      } else if (!StrCmp(argv[i], "--verbose")) {
        flags |= RM_FLAG_VERBOSE;
      } else {
        // Process short options
        I64 j = 1;
        while (argv[i][j]) {
          switch (argv[i][j]) {
            case 'f': flags |= RM_FLAG_FORCE; break;
            case 'r': 
            case 'R': flags |= RM_FLAG_RECURSIVE; break;
            case 'v': flags |= RM_FLAG_VERBOSE; break;
            default:
              "rm: invalid option -- '%c'\n", argv[i][j];
              "Try 'rm --help' for more information.\n";
              return;
          }
          j++;
        }
      }
    } else {
      // File argument
      if (!Remove(argv[i], flags))
        success = FALSE;
    }
  }
  
  // Return appropriate exit code
  if (!success && !(flags & RM_FLAG_FORCE))
    Exit(1);
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Rm(__argc, __argv);
#endif 