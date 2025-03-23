#define ECHO_FLAG_NO_NEWLINE  1 << 0  // -n: do not output the trailing newline
#define ECHO_FLAG_ESCAPE      1 << 1  // -e: enable interpretation of backslash escapes
#define ECHO_FLAG_NO_ESCAPE   1 << 2  // -E: disable interpretation of backslash escapes

// Process escape sequences in a string
U0 ProcessEscapes(U8 *str) {
  U8 *p = str;
  U8 *q = str;
  
  while (*p) {
    if (*p == '\\') {
      p++;
      switch (*p) {
        case 'n': *q++ = '\n'; p++; break;
        case 't': *q++ = '\t'; p++; break;
        case 'r': *q++ = '\r'; p++; break;
        case 'b': *q++ = '\b'; p++; break;
        case 'v': *q++ = '\v'; p++; break;
        case 'f': *q++ = '\f'; p++; break;
        case 'a': *q++ = '\a'; p++; break;
        case '\\': *q++ = '\\'; p++; break;
        case '"': *q++ = '"'; p++; break;
        case '\'': *q++ = '\''; p++; break;
        case '0': {
          // Octal escape sequence
          I64 val = 0;
          p++;
          for (I64 i = 0; i < 3 && *p >= '0' && *p <= '7'; i++) {
            val = val * 8 + (*p - '0');
            p++;
          }
          *q++ = val;
          break;
        }
        case 'x': {
          // Hexadecimal escape sequence
          I64 val = 0;
          p++;
          for (I64 i = 0; i < 2 && ((*p >= '0' && *p <= '9') || 
              (*p >= 'a' && *p <= 'f') || (*p >= 'A' && *p <= 'F')); i++) {
            val = val * 16 + (*p >= 'a' ? *p - 'a' + 10 :
                            *p >= 'A' ? *p - 'A' + 10 :
                            *p - '0');
            p++;
          }
          *q++ = val;
          break;
        }
        default: *q++ = *p++;
      }
    } else {
      *q++ = *p++;
    }
  }
  *q = 0;
}

// Main echo function
U0 Echo(I64 argc, U8 **argv) {
  if (argc < 2) {
    "\n";
    return;
  }
  
  I64 i, flags = 0;
  I64 first_arg = 1;
  
  // Parse options
  while (first_arg < argc && argv[first_arg][0] == '-') {
    if (!StrCmp(argv[first_arg], "--")) {
      first_arg++;
      break;
    }
    
    I64 j = 1;
    while (argv[first_arg][j]) {
      switch (argv[first_arg][j]) {
        case 'n': flags |= ECHO_FLAG_NO_NEWLINE; break;
        case 'e': flags |= ECHO_FLAG_ESCAPE; break;
        case 'E': flags |= ECHO_FLAG_NO_ESCAPE; break;
        default: goto end_options;
      }
      j++;
    }
    first_arg++;
  }
  
end_options:
  
  // Print arguments
  for (i = first_arg; i < argc; i++) {
    if (i > first_arg)
      " ";
      
    U8 *arg = argv[i];
    if (flags & ECHO_FLAG_ESCAPE && !(flags & ECHO_FLAG_NO_ESCAPE))
      ProcessEscapes(arg);
    "%s", arg;
  }
  
  if (!(flags & ECHO_FLAG_NO_NEWLINE))
    "\n";
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Echo(__argc, __argv);
#endif 