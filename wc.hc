#define WC_FLAG_LINES    1 << 0  // -l: print the newline counts
#define WC_FLAG_WORDS    1 << 1  // -w: print the word counts
#define WC_FLAG_CHARS    1 << 2  // -c: print the byte counts
#define WC_FLAG_MAX_LINE 1 << 3  // -L: print the maximum display width

// Count statistics for a single file
U0 CountFile(U8 *filename, I64 *lines, I64 *words, I64 *chars, I64 *max_line) {
  I64 fd = FileOpen(filename, FILE_ACCESS_READ);
  if (fd < 0) {
    "wc: %s: No such file or directory\n", filename;
    return;
  }
  
  U8 buf[4096];
  I64 bytes_read;
  I64 in_word = FALSE;
  I64 current_line_length = 0;
  
  while ((bytes_read = FileRead(fd, buf, sizeof(buf))) > 0) {
    for (I64 i = 0; i < bytes_read; i++) {
      U8 c = buf[i];
      (*chars)++;
      
      if (c == '\n') {
        (*lines)++;
        if (current_line_length > *max_line)
          *max_line = current_line_length;
        current_line_length = 0;
      } else {
        current_line_length++;
      }
      
      if (c == ' ' || c == '\t' || c == '\n') {
        in_word = FALSE;
      } else if (!in_word) {
        in_word = TRUE;
        (*words)++;
      }
    }
  }
  
  FileClose(fd);
}

// Main wc function
U0 Wc(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: wc [OPTION]... [FILE]...\n";
    "  -c, --bytes            print the byte counts\n";
    "  -l, --lines            print the newline counts\n";
    "  -w, --words            print the word counts\n";
    "  -L, --max-line-length  print the maximum display width\n";
    return;
  }
  
  I64 flags = 0;
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
        case 'c': flags |= WC_FLAG_CHARS; break;
        case 'l': flags |= WC_FLAG_LINES; break;
        case 'w': flags |= WC_FLAG_WORDS; break;
        case 'L': flags |= WC_FLAG_MAX_LINE; break;
        default: goto end_options;
      }
      j++;
    }
    first_file++;
  }
  
end_options:
  
  // If no flags specified, enable all
  if (!flags)
    flags = WC_FLAG_LINES | WC_FLAG_WORDS | WC_FLAG_CHARS;
  
  // Process files
  I64 total_lines = 0, total_words = 0, total_chars = 0;
  I64 max_line = 0;
  
  for (I64 i = first_file; i < argc; i++) {
    I64 lines = 0, words = 0, chars = 0;
    I64 file_max_line = 0;
    
    CountFile(argv[i], &lines, &words, &chars, &file_max_line);
    
    if (file_max_line > max_line)
      max_line = file_max_line;
      
    total_lines += lines;
    total_words += words;
    total_chars += chars;
    
    // Print file statistics
    if (flags & WC_FLAG_LINES)
      "%8d ", lines;
    if (flags & WC_FLAG_WORDS)
      "%8d ", words;
    if (flags & WC_FLAG_CHARS)
      "%8d ", chars;
    if (flags & WC_FLAG_MAX_LINE)
      "%8d ", file_max_line;
      
    "%s\n", argv[i];
  }
  
  // Print totals if more than one file
  if (argc - first_file > 1) {
    if (flags & WC_FLAG_LINES)
      "%8d ", total_lines;
    if (flags & WC_FLAG_WORDS)
      "%8d ", total_words;
    if (flags & WC_FLAG_CHARS)
      "%8d ", total_chars;
    if (flags & WC_FLAG_MAX_LINE)
      "%8d ", max_line;
      
    "total\n";
  }
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Wc(__argc, __argv);
#endif 