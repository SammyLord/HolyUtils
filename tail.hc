#define TAIL_FLAG_BYTES    1 << 0  // -c: output the last N bytes
#define TAIL_FLAG_LINES    1 << 1  // -n: output the last N lines
#define TAIL_FLAG_FOLLOW   1 << 2  // -f: follow file changes
#define TAIL_FLAG_QUIET    1 << 3  // -q: never output headers giving file names
#define TAIL_FLAG_VERBOSE  1 << 4  // -v: always output headers giving file names

// Print file header
U0 PrintHeader(U8 *filename, Bool verbose) {
  if (verbose)
    "==> %s <==\n", filename;
}

// Get file size
I64 GetFileSize(I64 fd) {
  I64 pos = FileSeek(fd, 0, FILE_SEEK_CUR);
  I64 size = FileSeek(fd, 0, FILE_SEEK_END);
  FileSeek(fd, pos, FILE_SEEK_SET);
  return size;
}

// Process a single file
U0 ProcessFile(U8 *filename, I64 count, I64 flags) {
  I64 fd = FileOpen(filename, FILE_ACCESS_READ);
  if (fd < 0) {
    "tail: cannot open '%s' for reading: No such file or directory\n", filename;
    return;
  }
  
  Bool verbose = (flags & TAIL_FLAG_VERBOSE) || 
                 (!(flags & TAIL_FLAG_QUIET) && __argc > 3);
                 
  if (verbose)
    PrintHeader(filename, TRUE);
  
  if (flags & TAIL_FLAG_BYTES) {
    // Print last N bytes
    I64 size = GetFileSize(fd);
    I64 start_pos = Max(0, size - count);
    FileSeek(fd, start_pos, FILE_SEEK_SET);
    
    U8 buf[4096];
    I64 bytes_read;
    while ((bytes_read = FileRead(fd, buf, sizeof(buf))) > 0) {
      for (I64 i = 0; i < bytes_read; i++)
        PutChar(buf[i]);
    }
  } else {
    // Print last N lines
    I64 size = GetFileSize(fd);
    I64 pos = size;
    I64 lines = 0;
    U8 buf[4096];
    I64 buf_pos = 0;
    
    // Read file backwards until we find enough newlines
    while (pos > 0 && lines < count) {
      I64 read_size = Min(sizeof(buf), pos);
      pos -= read_size;
      FileSeek(fd, pos, FILE_SEEK_SET);
      I64 bytes_read = FileRead(fd, buf, read_size);
      
      for (I64 i = bytes_read - 1; i >= 0; i--) {
        if (buf[i] == '\n') {
          lines++;
          if (lines >= count)
            break;
        }
      }
    }
    
    // Print from the found position
    FileSeek(fd, pos, FILE_SEEK_SET);
    I64 bytes_read;
    while ((bytes_read = FileRead(fd, buf, sizeof(buf))) > 0) {
      for (I64 i = 0; i < bytes_read; i++)
        PutChar(buf[i]);
    }
  }
  
  FileClose(fd);
  
  if (verbose)
    "\n";
}

// Follow file changes
U0 FollowFile(U8 *filename, I64 count, I64 flags) {
  I64 fd = FileOpen(filename, FILE_ACCESS_READ);
  if (fd < 0) {
    "tail: cannot open '%s' for reading: No such file or directory\n", filename;
    return;
  }
  
  Bool verbose = (flags & TAIL_FLAG_VERBOSE) || 
                 (!(flags & TAIL_FLAG_QUIET) && __argc > 3);
                 
  if (verbose)
    PrintHeader(filename, TRUE);
  
  // Print initial content
  ProcessFile(filename, count, flags);
  
  // Follow changes
  I64 last_size = GetFileSize(fd);
  U8 buf[4096];
  
  while (TRUE) {
    Sleep(1000);  // Wait for 1 second
    
    I64 current_size = GetFileSize(fd);
    if (current_size > last_size) {
      FileSeek(fd, last_size, FILE_SEEK_SET);
      I64 bytes_read;
      while ((bytes_read = FileRead(fd, buf, sizeof(buf))) > 0) {
        for (I64 i = 0; i < bytes_read; i++)
          PutChar(buf[i]);
      }
      last_size = current_size;
    }
  }
  
  FileClose(fd);
}

// Main tail function
U0 Tail(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: tail [OPTION]... [FILE]...\n";
    "  -c, --bytes=N        output the last N bytes\n";
    "  -n, --lines=N        output the last N lines\n";
    "  -f, --follow         follow file changes\n";
    "  -q, --quiet          never output headers giving file names\n";
    "  -v, --verbose        always output headers giving file names\n";
    return;
  }
  
  I64 flags = TAIL_FLAG_LINES;  // Default to lines
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
          flags = (flags & ~TAIL_FLAG_LINES) | TAIL_FLAG_BYTES;
          if (argv[first_file][j + 1] == '=') {
            count = StrToI64(argv[first_file] + j + 2);
            goto next_arg;
          }
          break;
        case 'n':
          flags = (flags & ~TAIL_FLAG_BYTES) | TAIL_FLAG_LINES;
          if (argv[first_file][j + 1] == '=') {
            count = StrToI64(argv[first_file] + j + 2);
            goto next_arg;
          }
          break;
        case 'f': flags |= TAIL_FLAG_FOLLOW; break;
        case 'q': flags |= TAIL_FLAG_QUIET; break;
        case 'v': flags |= TAIL_FLAG_VERBOSE; break;
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
    if (flags & TAIL_FLAG_FOLLOW)
      FollowFile(argv[i], count, flags);
    else
      ProcessFile(argv[i], count, flags);
  }
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Tail(__argc, __argv);
#endif 