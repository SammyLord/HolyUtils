#define MV_MAX_PATH 1024

// Flags for mv command
#define MV_FLAG_FORCE     1 << 0  // -f: force move by overwriting destination without prompt
#define MV_FLAG_VERBOSE   1 << 1  // -v: explain what is being done
#define MV_FLAG_NOERROR   1 << 2  // Don't report errors on failure (internal use)

// Move a single file or directory
Bool Move(U8 *src_path, U8 *dst_path, I64 flags) {
  // Check if source exists
  if (!FileExists(src_path) && !DirExists(src_path)) {
    if (!(flags & MV_FLAG_NOERROR))
      "mv: cannot stat '%s': No such file or directory\n", src_path;
    return FALSE;
  }
  
  // Check if destination exists
  if (FileExists(dst_path) || DirExists(dst_path)) {
    if (!(flags & MV_FLAG_FORCE)) {
      "mv: cannot move '%s': File exists\n", src_path;
      return FALSE;
    }
    
    // Try to remove destination first
    if (DirExists(dst_path)) {
      if (!DirDel(dst_path)) {
        if (!(flags & MV_FLAG_NOERROR))
          "mv: cannot remove '%s': Directory not empty or permission denied\n", dst_path;
        return FALSE;
      }
    } else {
      if (!FileDelete(dst_path)) {
        if (!(flags & MV_FLAG_NOERROR))
          "mv: cannot remove '%s': Permission denied\n", dst_path;
        return FALSE;
      }
    }
  }
  
  // Try to move the file/directory
  if (FileMove(src_path, dst_path)) {
    if (flags & MV_FLAG_VERBOSE)
      "renamed '%s' -> '%s'\n", src_path, dst_path;
    return TRUE;
  }
  
  if (!(flags & MV_FLAG_NOERROR))
    "mv: cannot move '%s': Permission denied\n", src_path;
  return FALSE;
}

// Main mv function
U0 Mv(I64 argc, U8 **argv) {
  if (argc < 3) {
    "Usage: mv [OPTION]... SOURCE DEST\n";
    "  or:  mv [OPTION]... SOURCE... DIRECTORY\n";
    "Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.\n\n";
    "  -f, --force           do not prompt before overwriting\n";
    "  -v, --verbose         explain what is being done\n";
    "      --help            display this help and exit\n";
    return;
  }
  
  I64 i, flags = 0;
  Bool success = TRUE;
  
  // Parse command line options
  I64 first_non_option = 1;
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-' && argv[i][1] != 0) {
      // Option argument
      if (!StrCmp(argv[i], "--help")) {
        "Usage: mv [OPTION]... SOURCE DEST\n";
        "  or:  mv [OPTION]... SOURCE... DIRECTORY\n";
        "Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.\n\n";
        "  -f, --force           do not prompt before overwriting\n";
        "  -v, --verbose         explain what is being done\n";
        "      --help            display this help and exit\n";
        return;
      } else if (!StrCmp(argv[i], "--force")) {
        flags |= MV_FLAG_FORCE;
      } else if (!StrCmp(argv[i], "--verbose")) {
        flags |= MV_FLAG_VERBOSE;
      } else {
        // Process short options
        I64 j = 1;
        while (argv[i][j]) {
          switch (argv[i][j]) {
            case 'f': flags |= MV_FLAG_FORCE; break;
            case 'v': flags |= MV_FLAG_VERBOSE; break;
            default:
              "mv: invalid option -- '%c'\n", argv[i][j];
              "Try 'mv --help' for more information.\n";
              return;
          }
          j++;
        }
      }
      first_non_option++;
    } else {
      break;
    }
  }
  
  // Get source and destination paths
  if (argc - first_non_option < 2) {
    "mv: missing destination file operand after '%s'\n", argv[argc - 1];
    "Try 'mv --help' for more information.\n";
    return;
  }
  
  U8 *dst_path = argv[argc - 1];
  Bool dst_is_dir = DirExists(dst_path);
  
  if (argc - first_non_option > 2 && !dst_is_dir) {
    "mv: target '%s' is not a directory\n", dst_path;
    return;
  }
  
  // Move files/directories
  for (i = first_non_option; i < argc - 1; i++) {
    if (dst_is_dir) {
      // If destination is a directory, append source name
      U8 *src_name = StrLastOcc(argv[i], "/");
      if (src_name)
        src_name++;  // Skip the '/'
      else
        src_name = argv[i];
        
      U8 new_dst_path[MV_MAX_PATH];
      StrPrint(new_dst_path, "%s/%s", dst_path, src_name);
      
      if (!Move(argv[i], new_dst_path, flags))
        success = FALSE;
    } else {
      if (!Move(argv[i], dst_path, flags))
        success = FALSE;
    }
  }
  
  // Return appropriate exit code
  if (!success)
    Exit(1);
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Mv(__argc, __argv);
#endif 