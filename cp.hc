#define CP_BUF_SIZE 4096
#define CP_MAX_PATH 1024

// Flags for cp command
#define CP_FLAG_FORCE     1 << 0  // -f: overwrite destination files without prompt
#define CP_FLAG_RECURSIVE 1 << 1  // -r: copy directories recursively
#define CP_FLAG_VERBOSE   1 << 2  // -v: explain what is being done
#define CP_FLAG_PRESERVE  1 << 3  // -p: preserve file attributes
#define CP_FLAG_NOERROR   1 << 4  // Don't report errors on failure (internal use)

// Copy a single file
Bool CopyFile(U8 *src_path, U8 *dst_path, I64 flags) {
  // Open source file
  I64 src_file = FOpen(src_path, "rb");
  if (src_file <= 0) {
    if (!(flags & CP_FLAG_NOERROR))
      "cp: cannot open '%s': No such file or directory\n", src_path;
    return FALSE;
  }
  
  // Check if destination exists and handle -f flag
  if (FileExists(dst_path) && !(flags & CP_FLAG_FORCE)) {
    "cp: '%s' already exists\n", dst_path;
    FClose(src_file);
    return FALSE;
  }
  
  // Open destination file
  I64 dst_file = FOpen(dst_path, "wb");
  if (dst_file <= 0) {
    FClose(src_file);
    if (!(flags & CP_FLAG_NOERROR))
      "cp: cannot create '%s': Permission denied\n", dst_path;
    return FALSE;
  }
  
  // Copy file contents
  U8 buffer[CP_BUF_SIZE];
  I64 bytes_read, bytes_written;
  Bool success = TRUE;
  
  while ((bytes_read = FRead(src_file, buffer, CP_BUF_SIZE)) > 0) {
    bytes_written = FWrite(dst_file, buffer, bytes_read);
    if (bytes_written != bytes_read) {
      success = FALSE;
      if (!(flags & CP_FLAG_NOERROR))
        "cp: error writing to '%s': Disk full or quota exceeded\n", dst_path;
      break;
    }
  }
  
  // Close files
  FClose(src_file);
  FClose(dst_file);
  
  // Preserve file attributes if requested
  if (success && (flags & CP_FLAG_PRESERVE)) {
    // HolyC doesn't have a direct equivalent to chmod/chown
    // This is where we would copy file attributes if supported
  }
  
  if (success && (flags & CP_FLAG_VERBOSE))
    "'%s' -> '%s'\n", src_path, dst_path;
  
  return success;
}

// Copy a directory recursively
Bool CopyDirectoryRecursive(U8 *src_path, U8 *dst_path, I64 flags) {
  CDirEntry de;
  I64 dir;
  U8 src_full_path[CP_MAX_PATH], dst_full_path[CP_MAX_PATH];
  Bool success = TRUE;
  
  // Create destination directory if it doesn't exist
  if (!DirExists(dst_path)) {
    if (!DirMk(dst_path)) {
      if (!(flags & CP_FLAG_NOERROR))
        "cp: cannot create directory '%s': Permission denied\n", dst_path;
      return FALSE;
    }
    
    if (flags & CP_FLAG_VERBOSE)
      "created directory '%s'\n", dst_path;
  }
  
  // Open source directory
  dir = DirOpen(src_path);
  if (dir < 0) {
    if (!(flags & CP_FLAG_NOERROR))
      "cp: cannot access '%s': No such file or directory\n", src_path;
    return FALSE;
  }
  
  // Copy each entry
  while (DirNext(dir, &de)) {
    if (!StrCmp(de.name, ".") || !StrCmp(de.name, ".."))
      continue;
    
    StrPrint(src_full_path, "%s/%s", src_path, de.name);
    StrPrint(dst_full_path, "%s/%s", dst_path, de.name);
    
    if (de.attr & RS_ATTR_DIR) {
      // Recursively copy subdirectory
      if (!(flags & CP_FLAG_RECURSIVE)) {
        "cp: omitting directory '%s'\n", src_full_path;
        success = FALSE;
        continue;
      }
      
      if (!CopyDirectoryRecursive(src_full_path, dst_full_path, flags))
        success = FALSE;
    } else {
      // Copy file
      if (!CopyFile(src_full_path, dst_full_path, flags))
        success = FALSE;
    }
  }
  
  DirClose(dir);
  return success;
}

// Copy a file or directory
Bool Copy(U8 *src_path, U8 *dst_path, I64 flags) {
  // Check if source exists
  if (!FileExists(src_path) && !DirExists(src_path)) {
    if (!(flags & CP_FLAG_NOERROR))
      "cp: cannot stat '%s': No such file or directory\n", src_path;
    return FALSE;
  }
  
  // Check if source is a directory
  if (DirExists(src_path)) {
    if (!(flags & CP_FLAG_RECURSIVE)) {
      "cp: omitting directory '%s'\n", src_path;
      return FALSE;
    }
    
    // If destination is a directory, append source directory name
    if (DirExists(dst_path)) {
      U8 *src_name = StrLastOcc(src_path, "/");
      if (src_name)
        src_name++;  // Skip the '/'
      else
        src_name = src_path;
        
      U8 new_dst_path[CP_MAX_PATH];
      StrPrint(new_dst_path, "%s/%s", dst_path, src_name);
      
      return CopyDirectoryRecursive(src_path, new_dst_path, flags);
    } else {
      return CopyDirectoryRecursive(src_path, dst_path, flags);
    }
  } else {
    // Handle copying file to directory
    if (DirExists(dst_path)) {
      U8 *src_name = StrLastOcc(src_path, "/");
      if (src_name)
        src_name++;  // Skip the '/'
      else
        src_name = src_path;
        
      U8 new_dst_path[CP_MAX_PATH];
      StrPrint(new_dst_path, "%s/%s", dst_path, src_name);
      
      return CopyFile(src_path, new_dst_path, flags);
    } else {
      return CopyFile(src_path, dst_path, flags);
    }
  }
}

// Main cp function
U0 Cp(I64 argc, U8 **argv) {
  if (argc < 3) {
    "Usage: cp [OPTION]... SOURCE DEST\n";
    "  or:  cp [OPTION]... SOURCE... DIRECTORY\n";
    "Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.\n\n";
    "  -f, --force                 if an existing destination file cannot be\n";
    "                              opened, remove it and try again\n";
    "  -p, --preserve              preserve file attributes if possible\n";
    "  -r, -R, --recursive         copy directories recursively\n";
    "  -v, --verbose               explain what is being done\n";
    "      --help                  display this help and exit\n";
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
        "Usage: cp [OPTION]... SOURCE DEST\n";
        "  or:  cp [OPTION]... SOURCE... DIRECTORY\n";
        "Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.\n\n";
        "  -f, --force                 if an existing destination file cannot be\n";
        "                              opened, remove it and try again\n";
        "  -p, --preserve              preserve file attributes if possible\n";
        "  -r, -R, --recursive         copy directories recursively\n";
        "  -v, --verbose               explain what is being done\n";
        "      --help                  display this help and exit\n";
        return;
      } else if (!StrCmp(argv[i], "--force")) {
        flags |= CP_FLAG_FORCE;
      } else if (!StrCmp(argv[i], "--recursive")) {
        flags |= CP_FLAG_RECURSIVE;
      } else if (!StrCmp(argv[i], "--verbose")) {
        flags |= CP_FLAG_VERBOSE;
      } else if (!StrCmp(argv[i], "--preserve")) {
        flags |= CP_FLAG_PRESERVE;
      } else {
        // Process short options
        I64 j = 1;
        while (argv[i][j]) {
          switch (argv[i][j]) {
            case 'f': flags |= CP_FLAG_FORCE; break;
            case 'r': 
            case 'R': flags |= CP_FLAG_RECURSIVE; break;
            case 'v': flags |= CP_FLAG_VERBOSE; break;
            case 'p': flags |= CP_FLAG_PRESERVE; break;
            default:
              "cp: invalid option -- '%c'\n", argv[i][j];
              "Try 'cp --help' for more information.\n";
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
    "cp: missing destination file operand after '%s'\n", argv[argc - 1];
    "Try 'cp --help' for more information.\n";
    return;
  }
  
  U8 *dst_path = argv[argc - 1];
  Bool dst_is_dir = DirExists(dst_path);
  
  if (argc - first_non_option > 2 && !dst_is_dir) {
    "cp: target '%s' is not a directory\n", dst_path;
    return;
  }
  
  // Copy files/directories
  for (i = first_non_option; i < argc - 1; i++) {
    if (!Copy(argv[i], dst_path, flags))
      success = FALSE;
  }
  
  // Return appropriate exit code
  if (!success)
    Exit(1);
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Cp(__argc, __argv);
#endif 