#define CAT_BUF_SIZE 4096

// Flags for cat command
#define CAT_FLAG_NUMBER   1 << 0  // -n: number output lines
#define CAT_FLAG_SHOWENDS 1 << 1  // -E: display $ at end of each line
#define CAT_FLAG_TABS     1 << 2  // -T: display TAB characters as ^I
#define CAT_FLAG_SQUEEZE  1 << 3  // -s: squeeze multiple blank lines into one

// Display the contents of a file
U0 CatFile(U8 *filename, I64 flags) {
  I64 file = FOpen(filename, "r");
  if (file <= 0) {
    "cat: %s: No such file or directory\n", filename;
    return;
  }

  U8 buffer[CAT_BUF_SIZE];
  I64 line_number = 1;
  Bool last_was_blank = FALSE;
  
  while (TRUE) {
    I64 read_size = FRead(file, buffer, CAT_BUF_SIZE - 1);
    if (read_size <= 0) break;
    
    buffer[read_size] = 0; // Null-terminate the buffer
    
    // Process buffer line by line
    U8 *line = buffer;
    U8 *next_line;
    
    while (*line) {
      next_line = StrFind(line, "\n");
      Bool is_blank_line = TRUE;
      
      // Check if line is blank
      if (next_line) {
        U8 *p = line;
        while (p < next_line) {
          if (*p != ' ' && *p != '\t' && *p != '\r') {
            is_blank_line = FALSE;
            break;
          }
          p++;
        }
        
        // Null-terminate the current line for processing
        *next_line = 0;
      } else {
        // Last line without newline
        if (*line != 0)
          is_blank_line = FALSE;
      }
      
      // Handle squeeze blank lines option
      if ((flags & CAT_FLAG_SQUEEZE) && is_blank_line && last_was_blank) {
        // Skip this line
      } else {
        // Show line number if -n flag is set
        if (flags & CAT_FLAG_NUMBER)
          "%6d  ", line_number++;
          
        // Process and display the line
        U8 *p = line;
        while (*p) {
          if (*p == '\t' && (flags & CAT_FLAG_TABS)) {
            // Display tab as ^I
            "^I";
          } else {
            "%c", *p;
          }
          p++;
        }
        
        // Show end of line marker if -E flag is set
        if (flags & CAT_FLAG_SHOWENDS)
          "$";
          
        // Add the newline that we removed
        "\n";
      }
      
      last_was_blank = is_blank_line;
      
      if (!next_line) break;
      line = next_line + 1;
    }
  }
  
  FClose(file);
}

// Parse command line arguments and run cat
U0 Cat(I64 argc, U8 **argv) {
  I64 i, flags = 0;
  Bool files_processed = FALSE;

  // Parse command line arguments
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-' && argv[i][1] != 0) {
      // Option argument
      if (!StrCmp(argv[i], "--help")) {
        "Usage: cat [OPTION]... [FILE]...\n";
        "Concatenate FILE(s) to standard output.\n\n";
        "  -n, --number             number all output lines\n";
        "  -E, --show-ends          display $ at end of each line\n";
        "  -T, --show-tabs          display TAB characters as ^I\n";
        "  -s, --squeeze-blank      suppress repeated empty output lines\n";
        "      --help               display this help and exit\n";
        return;
      }
      
      I64 j = 1;
      while (argv[i][j]) {
        switch (argv[i][j]) {
          case 'n': flags |= CAT_FLAG_NUMBER; break;
          case 'E': flags |= CAT_FLAG_SHOWENDS; break;
          case 'T': flags |= CAT_FLAG_TABS; break;
          case 's': flags |= CAT_FLAG_SQUEEZE; break;
          default:
            "cat: invalid option -- '%c'\n", argv[i][j];
            "Try 'cat --help' for more information.\n";
            return;
        }
        j++;
      }
    } else {
      // File argument
      CatFile(argv[i], flags);
      files_processed = TRUE;
    }
  }
  
  // If no files were processed, read from standard input
  if (!files_processed) {
    "cat: Reading from standard input is not supported in this implementation.\n";
    "Try 'cat --help' for more information.\n";
  }
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Cat(__argc, __argv);
#endif 