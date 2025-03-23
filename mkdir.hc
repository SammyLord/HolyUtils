#define MKDIR_MAX_PATH 1024

// Flags for mkdir command
#define MKDIR_FLAG_PARENTS 1 << 0  // -p: create parent directories as needed
#define MKDIR_FLAG_VERBOSE 1 << 1  // -v: print a message for each created directory

// Create directory recursively (like mkdir -p)
Bool MakeDirRecursive(U8 *path, I64 flags) {
  U8 tmp_path[MKDIR_MAX_PATH];
  StrCpy(tmp_path, path);
  
  // If the path ends with a slash, remove it
  I64 len = StrLen(tmp_path);
  if (len > 0 && (tmp_path[len - 1] == '/' || tmp_path[len - 1] == '\\')) {
    tmp_path[len - 1] = 0;
    len--;
  }
  
  // If the directory already exists, return success
  if (DirExists(tmp_path)) {
    if (flags & MKDIR_FLAG_VERBOSE)
      "mkdir: created directory '%s'\n", tmp_path;
    return TRUE;
  }
  
  // Try to create the directory directly
  if (DirMk(tmp_path)) {
    if (flags & MKDIR_FLAG_VERBOSE)
      "mkdir: created directory '%s'\n", tmp_path;
    return TRUE;
  }
  
  // If we're not allowed to create parent directories, fail
  if (!(flags & MKDIR_FLAG_PARENTS)) {
    "mkdir: cannot create directory '%s': No such file or directory\n", tmp_path;
    return FALSE;
  }
  
  // Find the last directory separator
  I64 i;
  for (i = len - 1; i >= 0; i--) {
    if (tmp_path[i] == '/' || tmp_path[i] == '\\')
      break;
  }
  
  // No directory separator found
  if (i < 0) {
    "mkdir: cannot create directory '%s': Invalid path\n", tmp_path;
    return FALSE;
  }
  
  // Create parent directories recursively
  tmp_path[i] = 0;
  if (!MakeDirRecursive(tmp_path, flags))
    return FALSE;
  
  // Restore the full path and try to create it again
  tmp_path[i] = '/';
  if (DirMk(tmp_path)) {
    if (flags & MKDIR_FLAG_VERBOSE)
      "mkdir: created directory '%s'\n", tmp_path;
    return TRUE;
  }
  
  "mkdir: cannot create directory '%s': Permission denied\n", tmp_path;
  return FALSE;
}

// Make a single directory
Bool MakeDir(U8 *path, I64 flags) {
  if (flags & MKDIR_FLAG_PARENTS)
    return MakeDirRecursive(path, flags);
  
  if (DirExists(path)) {
    "mkdir: cannot create directory '%s': File exists\n", path;
    return FALSE;
  }
  
  if (DirMk(path)) {
    if (flags & MKDIR_FLAG_VERBOSE)
      "mkdir: created directory '%s'\n", path;
    return TRUE;
  }
  
  "mkdir: cannot create directory '%s': No such file or directory\n", path;
  return FALSE;
}

// Main mkdir function
U0 Mkdir(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: mkdir [OPTION]... DIRECTORY...\n";
    "Create the DIRECTORY(ies), if they do not already exist.\n\n";
    "  -p, --parents     make parent directories as needed\n";
    "  -v, --verbose     print a message for each created directory\n";
    "      --help        display this help and exit\n";
    return;
  }
  
  I64 i, flags = 0;
  Bool success = TRUE;
  
  // Parse command line arguments
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-') {
      // Option argument
      if (!StrCmp(argv[i], "--help")) {
        "Usage: mkdir [OPTION]... DIRECTORY...\n";
        "Create the DIRECTORY(ies), if they do not already exist.\n\n";
        "  -p, --parents     make parent directories as needed\n";
        "  -v, --verbose     print a message for each created directory\n";
        "      --help        display this help and exit\n";
        return;
      } else if (!StrCmp(argv[i], "--parents")) {
        flags |= MKDIR_FLAG_PARENTS;
      } else if (!StrCmp(argv[i], "--verbose")) {
        flags |= MKDIR_FLAG_VERBOSE;
      } else if (argv[i][1] == 'p') {
        flags |= MKDIR_FLAG_PARENTS;
      } else if (argv[i][1] == 'v') {
        flags |= MKDIR_FLAG_VERBOSE;
      } else {
        "mkdir: invalid option -- '%s'\n", argv[i];
        "Try 'mkdir --help' for more information.\n";
        return;
      }
    } else {
      // Directory argument
      if (!MakeDir(argv[i], flags))
        success = FALSE;
    }
  }
  
  // Return appropriate exit code
  if (!success)
    Exit(1);
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Mkdir(__argc, __argv);
#endif 