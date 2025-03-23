#define GREP_BUF_SIZE 4096
#define GREP_MAX_PATH 1024
#define GREP_MAX_LINE 4096

// Flags for grep command
#define GREP_FLAG_IGNORECASE  1 << 0  // -i: ignore case
#define GREP_FLAG_LINENUMBER  1 << 1  // -n: show line numbers
#define GREP_FLAG_COUNT       1 << 2  // -c: print only count of matching lines
#define GREP_FLAG_FILENAME    1 << 3  // Always show filename in output (used for multiple files)
#define GREP_FLAG_INVERT      1 << 4  // -v: invert match
#define GREP_FLAG_RECURSIVE   1 << 5  // -r: recursively search directories

// Structure to store match context
class GrepContext {
  I64 match_count;
  I64 total_lines;
  I64 flags;
  U8 *pattern;
  U8 current_file[GREP_MAX_PATH];
};

// Simple pattern matching (basic grep functionality)
Bool MatchPattern(U8 *text, U8 *pattern, Bool ignore_case) {
  if (!text || !pattern) 
    return FALSE;
  
  // Handle empty pattern (matches everything)
  if (!*pattern) 
    return TRUE;
  
  // Case-insensitive search
  if (ignore_case) {
    while (*text) {
      I64 i = 0;
      I64 j = 0;
      
      // Try to match pattern at current position
      while (pattern[i] && text[j]) {
        U8 p_char = pattern[i];
        U8 t_char = text[j];
        
        // Convert to lowercase if uppercase
        if (p_char >= 'A' && p_char <= 'Z') 
          p_char += 32;
        if (t_char >= 'A' && t_char <= 'Z') 
          t_char += 32;
        
        if (p_char != t_char) 
          break;
        
        i++;
        j++;
      }
      
      if (!pattern[i]) // Pattern matched completely
        return TRUE;
      
      text++;
    }
    
    return FALSE;
  } else {
    // Case-sensitive search (simpler)
    return StrFind(text, pattern) != NULL;
  }
}

// Process a single line for grep
U0 ProcessLine(GrepContext *ctx, U8 *line, I64 line_number) {
  Bool matches = MatchPattern(line, ctx->pattern, ctx->flags & GREP_FLAG_IGNORECASE);
  
  // Handle inverted matching
  if (ctx->flags & GREP_FLAG_INVERT)
    matches = !matches;
  
  if (matches)
    ctx->match_count++;
  else
    return; // Skip non-matches
  
  // If we're just counting matches, don't print anything
  if (ctx->flags & GREP_FLAG_COUNT)
    return;
  
  // Format output
  if (ctx->flags & GREP_FLAG_FILENAME)
    "%s:", ctx->current_file;
  
  if (ctx->flags & GREP_FLAG_LINENUMBER)
    "%d:", line_number;
  
  "%s\n", line;
}

// Grep a single file
U0 GrepFile(GrepContext *ctx, U8 *filename) {
  I64 file = FOpen(filename, "r");
  if (file <= 0) {
    "grep: %s: No such file or directory\n", filename;
    return;
  }
  
  // Track current file in context
  StrCpy(ctx->current_file, filename);
  
  U8 buffer[GREP_BUF_SIZE];
  U8 line[GREP_MAX_LINE];
  I64 line_number = 1;
  I64 line_pos = 0;
  
  ctx->match_count = 0;
  ctx->total_lines = 0;
  
  while (TRUE) {
    I64 read_size = FRead(file, buffer, GREP_BUF_SIZE);
    if (read_size <= 0) break;
    
    // Process buffer character by character
    for (I64 i = 0; i < read_size; i++) {
      if (buffer[i] == '\n') {
        // End of line, process it
        line[line_pos] = 0;
        ProcessLine(ctx, line, line_number);
        line_pos = 0;
        line_number++;
        ctx->total_lines++;
      } else if (line_pos < GREP_MAX_LINE - 1) {
        line[line_pos++] = buffer[i];
      }
    }
  }
  
  // Process any remaining characters in the last line if not terminated with newline
  if (line_pos > 0) {
    line[line_pos] = 0;
    ProcessLine(ctx, line, line_number);
    ctx->total_lines++;
  }
  
  // If we're counting matches, print the count
  if (ctx->flags & GREP_FLAG_COUNT) {
    if (ctx->flags & GREP_FLAG_FILENAME)
      "%s:", ctx->current_file;
    "%d\n", ctx->match_count;
  }
  
  FClose(file);
}

// Recursively grep through directories
U0 GrepDirectory(GrepContext *ctx, U8 *dir_path) {
  CDirEntry de;
  I64 dir;
  U8 full_path[GREP_MAX_PATH];
  
  dir = DirOpen(dir_path);
  if (dir < 0) {
    "grep: %s: No such directory\n", dir_path;
    return;
  }
  
  while (DirNext(dir, &de)) {
    if (!StrCmp(de.name, ".") || !StrCmp(de.name, ".."))
      continue;
    
    StrPrint(full_path, "%s/%s", dir_path, de.name);
    
    if (de.attr & RS_ATTR_DIR) {
      // Recursively process subdirectory
      GrepDirectory(ctx, full_path);
    } else {
      // Process file
      GrepFile(ctx, full_path);
    }
  }
  
  DirClose(dir);
}

// Main grep function
U0 Grep(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: grep [OPTION]... PATTERN [FILE]...\n";
    "Search for PATTERN in each FILE.\n";
    "Example: grep -i 'hello world' menu.lst\n\n";
    "  -c, --count               print only a count of matching lines per file\n";
    "  -i, --ignore-case         ignore case distinctions\n";
    "  -n, --line-number         print line number with output lines\n";
    "  -r, --recursive           read all files under each directory, recursively\n";
    "  -v, --invert-match        select non-matching lines\n";
    "      --help                display this help and exit\n";
    return;
  }
  
  GrepContext ctx;
  I64 i, pattern_index = 0;
  ctx.flags = 0;
  
  // Parse command line options
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-' && argv[i][1] != 0) {
      // Option argument
      if (!StrCmp(argv[i], "--help")) {
        "Usage: grep [OPTION]... PATTERN [FILE]...\n";
        "Search for PATTERN in each FILE.\n";
        "Example: grep -i 'hello world' menu.lst\n\n";
        "  -c, --count               print only a count of matching lines per file\n";
        "  -i, --ignore-case         ignore case distinctions\n";
        "  -n, --line-number         print line number with output lines\n";
        "  -r, --recursive           read all files under each directory, recursively\n";
        "  -v, --invert-match        select non-matching lines\n";
        "      --help                display this help and exit\n";
        return;
      } else if (!StrCmp(argv[i], "--count")) {
        ctx.flags |= GREP_FLAG_COUNT;
      } else if (!StrCmp(argv[i], "--ignore-case")) {
        ctx.flags |= GREP_FLAG_IGNORECASE;
      } else if (!StrCmp(argv[i], "--line-number")) {
        ctx.flags |= GREP_FLAG_LINENUMBER;
      } else if (!StrCmp(argv[i], "--invert-match")) {
        ctx.flags |= GREP_FLAG_INVERT;
      } else if (!StrCmp(argv[i], "--recursive")) {
        ctx.flags |= GREP_FLAG_RECURSIVE;
      } else {
        // Process short options
        I64 j = 1;
        while (argv[i][j]) {
          switch (argv[i][j]) {
            case 'c': ctx.flags |= GREP_FLAG_COUNT; break;
            case 'i': ctx.flags |= GREP_FLAG_IGNORECASE; break;
            case 'n': ctx.flags |= GREP_FLAG_LINENUMBER; break;
            case 'v': ctx.flags |= GREP_FLAG_INVERT; break;
            case 'r': ctx.flags |= GREP_FLAG_RECURSIVE; break;
            default:
              "grep: invalid option -- '%c'\n", argv[i][j];
              "Try 'grep --help' for more information.\n";
              return;
          }
          j++;
        }
      }
    } else if (!pattern_index) {
      // First non-option argument is the pattern
      pattern_index = i;
      break;
    }
  }
  
  if (!pattern_index) {
    "grep: missing pattern\n";
    "Try 'grep --help' for more information.\n";
    return;
  }
  
  ctx.pattern = argv[pattern_index];
  
  if (pattern_index + 1 >= argc) {
    "grep: no input files\n";
    "Try 'grep --help' for more information.\n";
    return;
  }
  
  // Set flag to show filenames if multiple files are specified
  if (pattern_index + 2 < argc)
    ctx.flags |= GREP_FLAG_FILENAME;
  
  // Process each file/directory
  for (i = pattern_index + 1; i < argc; i++) {
    if ((ctx.flags & GREP_FLAG_RECURSIVE) && DirExists(argv[i])) {
      GrepDirectory(&ctx, argv[i]);
    } else {
      GrepFile(&ctx, argv[i]);
    }
  }
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Grep(__argc, __argv);
#endif 