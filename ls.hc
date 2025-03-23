#define LS_MAX_ENTRIES 1000
#define LS_NAME_MAX_LEN 256
#define LS_PATH_MAX_LEN 1024

// File entry types
#define LS_TYPE_FILE    0
#define LS_TYPE_DIR     1
#define LS_TYPE_LINK    2
#define LS_TYPE_UNKNOWN 3

// Flags for ls command
#define LS_FLAG_LONG    1 << 0  // -l: long listing format
#define LS_FLAG_ALL     1 << 1  // -a: show hidden files
#define LS_FLAG_HUMAN   1 << 2  // -h: human-readable sizes
#define LS_FLAG_RECUR   1 << 3  // -R: recursive listing

// Entry structure
class LSEntry {
  U8 name[LS_NAME_MAX_LEN];
  I64 type;
  I64 size;
  I64 time;
  I64 mode;
};

// Formats file size to human-readable form
U8 *FormatSize(I64 size, U8 *buf) {
  if (size < 1024)
    StrPrint(buf, "%d", size);
  else if (size < 1024 * 1024)
    StrPrint(buf, "%.1fK", size / 1024.0);
  else if (size < 1024 * 1024 * 1024)
    StrPrint(buf, "%.1fM", size / (1024.0 * 1024));
  else
    StrPrint(buf, "%.1fG", size / (1024.0 * 1024 * 1024));
  return buf;
}

// Format file mode/permissions
U8 *FormatMode(I64 mode, U8 *buf) {
  // Simple approximation of Unix-style permissions
  StrCpy(buf, "----------");
  
  // File type
  if (mode & 0x4000)
    buf[0] = 'd';
  
  // Owner permissions
  if (mode & 0x0100) buf[1] = 'r';
  if (mode & 0x0080) buf[2] = 'w';
  if (mode & 0x0040) buf[3] = 'x';
  
  // Group permissions
  if (mode & 0x0020) buf[4] = 'r';
  if (mode & 0x0010) buf[5] = 'w';
  if (mode & 0x0008) buf[6] = 'x';
  
  // Other permissions
  if (mode & 0x0004) buf[7] = 'r';
  if (mode & 0x0002) buf[8] = 'w';
  if (mode & 0x0001) buf[9] = 'x';
  
  return buf;
}

// Compare entries for sorting (by name)
I64 LSEntryCmp(LSEntry *a, LSEntry *b) {
  return StrCmp(a->name, b->name);
}

// List directory contents
U0 ListDirectory(U8 *path, I64 flags, I64 indent_level) {
  CDirEntry de;
  I64 count = 0;
  LSEntry entries[LS_MAX_ENTRIES];
  U8 full_path[LS_PATH_MAX_LEN];
  
  if (indent_level > 0)
    "\n%s:\n", path;
  
  // Open directory for reading
  I64 dir = DirOpen(path);
  if (dir < 0) {
    "ls: cannot access '%s': No such file or directory\n", path;
    return;
  }
  
  // Read directory entries
  while (DirNext(dir, &de) && count < LS_MAX_ENTRIES) {
    // Skip hidden files unless -a flag is set
    if (de.name[0] == '.' && !(flags & LS_FLAG_ALL) && 
        StrCmp(de.name, ".") && StrCmp(de.name, ".."))
      continue;
    
    // Store entry information
    StrCpy(entries[count].name, de.name);
    entries[count].size = de.size;
    entries[count].time = de.datetime;
    entries[count].mode = de.attr;
    
    // Determine entry type
    if (de.attr & RS_ATTR_DIR)
      entries[count].type = LS_TYPE_DIR;
    else
      entries[count].type = LS_TYPE_FILE;
    
    count++;
  }
  
  DirClose(dir);
  
  // Sort entries by name
  QSort(entries, count, sizeof(LSEntry), &LSEntryCmp);
  
  // Display entries
  I64 i;
  for (i = 0; i < count; i++) {
    if (flags & LS_FLAG_LONG) {
      // Long listing format (-l)
      U8 mode_str[16], size_str[16], time_str[32];
      
      FormatMode(entries[i].mode, mode_str);
      
      if (flags & LS_FLAG_HUMAN)
        FormatSize(entries[i].size, size_str);
      else
        StrPrint(size_str, "%10d", entries[i].size);
      
      Date2Str(time_str, entries[i].time);
      
      "%s %8s %s ", mode_str, size_str, time_str;
      
      // Highlight directories in output
      if (entries[i].type == LS_TYPE_DIR)
        "\e[36m%s\e[0m\n", entries[i].name;
      else
        "%s\n", entries[i].name;
    } else {
      // Simple format
      if (entries[i].type == LS_TYPE_DIR)
        "\e[36m%-16s\e[0m", entries[i].name;
      else
        "%-16s", entries[i].name;
      
      // Line break every 5 entries in simple format
      if (i % 5 == 4) "\n";
    }
  }
  
  // Ensure we end with a newline
  if (!(flags & LS_FLAG_LONG) && count % 5 != 0)
    "\n";
  
  // Recursive listing (-R)
  if (flags & LS_FLAG_RECUR) {
    for (i = 0; i < count; i++) {
      if (entries[i].type == LS_TYPE_DIR && 
          StrCmp(entries[i].name, ".") && 
          StrCmp(entries[i].name, "..")) {
        
        StrPrint(full_path, "%s/%s", path, entries[i].name);
        ListDirectory(full_path, flags, indent_level + 1);
      }
    }
  }
}

// Parse command line arguments and execute ls
U0 Ls(I64 argc, U8 **argv) {
  I64 i, flags = 0;
  U8 *path = ".";  // Default to current directory
  
  // Parse command line arguments
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-') {
      // Option argument
      I64 j = 1;
      while (argv[i][j]) {
        switch (argv[i][j]) {
          case 'l': flags |= LS_FLAG_LONG; break;
          case 'a': flags |= LS_FLAG_ALL; break;
          case 'h': flags |= LS_FLAG_HUMAN; break;
          case 'R': flags |= LS_FLAG_RECUR; break;
          case 'h':
            "Usage: ls [OPTION]... [FILE]...\n";
            "List information about files.\n\n";
            "  -a        do not hide entries starting with .\n";
            "  -l        use a long listing format\n";
            "  -h        with -l, print sizes in human readable format\n";
            "  -R        list subdirectories recursively\n";
            "  --help    display this help and exit\n";
            return;
          default:
            "ls: invalid option -- '%c'\n", argv[i][j];
            "Try 'ls --help' for more information.\n";
            return;
        }
        j++;
      }
    } else {
      // Path argument (use last one if multiple provided)
      path = argv[i];
    }
  }
  
  // List the directory
  ListDirectory(path, flags, 0);
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Ls(__argc, __argv);
#endif 