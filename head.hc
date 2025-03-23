#define HEAD_FLAG_BYTES    1 << 0  // -c: print the first N bytes
#define HEAD_FLAG_LINES    1 << 1  // -n: print the first N lines
#define HEAD_FLAG_QUIET    1 << 2  // -q: never print headers giving file names
#define HEAD_FLAG_VERBOSE  1 << 3  // -v: always print headers giving file names

// Print file header
U0 PrintHeader(U8 *filename, Bool verbose) {
  if (verbose)
    "==> %s <==\n", filename;
}

// Process a single file
U0 ProcessFile(U8 *filename, I64 count, I64 flags) {
  I64 fd = FileOpen(filename, FILE_ACCESS_READ);
  if (fd < 0) {
    "head: cannot open '%s' for reading: No such file or directory\n", filename;
    return;
  }
  
  Bool verbose = (flags & HEAD_FLAG_VERBOSE) || 
                 (!(flags & HEAD_FLAG_QUIET) && __argc > 3);
                 
  if (verbose)
    PrintHeader(filename, TRUE);
  
  if (flags & HEAD_FLAG_BYTES) {
    // Print first N bytes
    U8 buf[4096];
    I64 bytes_read;
    I64 total_bytes = 0;
    
    while (total_bytes < count && 
           (bytes_read = FileRead(fd, buf, Min(sizeof(buf), count - total_bytes))) > 0) {
      for (I64 i = 0; i < bytes_read; i++)
        PutChar(buf[i]);
      total_bytes += bytes_read;
    }
  } else {
    // Print first N lines
    U8 buf[4096];
    I64 bytes_read;
    I64 lines = 0;
    I64 pos = 0;
    
    while (lines < count && (bytes_read = FileRead(fd, buf, sizeof(buf))) > 0) {
      for (I64 i = 0; i < bytes_read && lines < count; i++) {
        if (buf[i] == '\n') {
          lines++;
          if (lines < count)
            PutChar('\n');
        } else {
          PutChar(buf[i]);
        }
      }
    }
  }
  
  FileClose(fd);
  
  if (verbose)
    "\n";
}

// Main head function
U0 Head(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: head [OPTION]... [FILE]...\n";
    "  -c, --bytes=N        print the first N bytes\n";
    "  -n, --lines=N        print the first N lines\n";
    "  -q, --quiet          never print headers giving file names\n";
    "  -v, --verbose        always print headers giving file names\n";
    return;
  }
  
  I64 flags = HEAD_FLAG_LINES;  // Default to lines
  I64 count = 10;  // Default to 10 lines
  I64 first_file = 1;
  
  // Parse options
  while (first_file < argc && argv[first_file][0] == '-') {
    if (!StrCmp(argv[first_file], "--")) {
      first_file++;
      break;
    }
    
    I64 j = 1;
    while (argv[first_file][j]) {
      switch (argv[first_file][j]) {
        case 'c': 
          flags = (flags & ~HEAD_FLAG_LINES) | HEAD_FLAG_BYTES;
          if (argv[first_file][j + 1] == '=') {
            count = StrToI64(argv[first_file] + j + 2);
            goto next_arg;
          }
          break;
        case 'n':
          flags = (flags & ~HEAD_FLAG_BYTES) | HEAD_FLAG_LINES;
          if (argv[first_file][j + 1] == '=') {
            count = StrToI64(argv[first_file] + j + 2);
            goto next_arg;
          }
          break;
        case 'q': flags |= HEAD_FLAG_QUIET; break;
        case 'v': flags |= HEAD_FLAG_VERBOSE; break;
        default: goto end_options;
      }
      j++;
    }
    
next_arg:
    first_file++;
  }
  
end_options:
  
  // If no files specified, read from stdin
  if (first_file >= argc) {
    ProcessFile("", count, flags);
    return;
  }
  
  // Process each file
  for (I64 i = first_file; i < argc; i++) {
    ProcessFile(argv[i], count, flags);
  }
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Head(__argc, __argv);
#endif 