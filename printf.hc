#define PRINTF_MAX_FORMAT 1024
#define PRINTF_MAX_ARGS 64

// Format specifier types
#define PRINTF_TYPE_INT     1
#define PRINTF_TYPE_UINT    2
#define PRINTF_TYPE_FLOAT   3
#define PRINTF_TYPE_STRING  4
#define PRINTF_TYPE_CHAR    5
#define PRINTF_TYPE_POINTER 6

// Format specifier flags
#define PRINTF_FLAG_LEFT    1 << 0  // Left-justify
#define PRINTF_FLAG_SIGN    1 << 1  // Always show sign
#define PRINTF_FLAG_SPACE   1 << 2  // Space if no sign
#define PRINTF_FLAG_ALT     1 << 3  // Alternate form
#define PRINTF_FLAG_ZERO    1 << 4  // Zero-pad

// Parse format specifier
I64 ParseFormatSpec(U8 *format, I64 *width, I64 *precision, I64 *flags, I64 *type) {
  I64 i = 0;
  *flags = 0;
  *width = 0;
  *precision = -1;
  *type = 0;
  
  // Parse flags
  while (TRUE) {
    switch (format[i]) {
      case '-': *flags |= PRINTF_FLAG_LEFT; i++; break;
      case '+': *flags |= PRINTF_FLAG_SIGN; i++; break;
      case ' ': *flags |= PRINTF_FLAG_SPACE; i++; break;
      case '#': *flags |= PRINTF_FLAG_ALT; i++; break;
      case '0': *flags |= PRINTF_FLAG_ZERO; i++; break;
      default: goto end_flags;
    }
  }
  
end_flags:
  
  // Parse width
  if (format[i] >= '0' && format[i] <= '9') {
    *width = 0;
    while (format[i] >= '0' && format[i] <= '9') {
      *width = *width * 10 + (format[i] - '0');
      i++;
    }
  }
  
  // Parse precision
  if (format[i] == '.') {
    i++;
    *precision = 0;
    while (format[i] >= '0' && format[i] <= '9') {
      *precision = *precision * 10 + (format[i] - '0');
      i++;
    }
  }
  
  // Parse type
  switch (format[i]) {
    case 'd': case 'i': *type = PRINTF_TYPE_INT; break;
    case 'u': *type = PRINTF_TYPE_UINT; break;
    case 'f': case 'F': *type = PRINTF_TYPE_FLOAT; break;
    case 's': *type = PRINTF_TYPE_STRING; break;
    case 'c': *type = PRINTF_TYPE_CHAR; break;
    case 'p': *type = PRINTF_TYPE_POINTER; break;
    default: return 0;
  }
  
  return i + 1;
}

// Format a number with the given specifiers
U0 FormatNumber(I64 num, U8 *buf, I64 width, I64 precision, I64 flags, I64 type) {
  U8 num_str[32];
  I64 len = 0;
  Bool is_negative = FALSE;
  
  // Handle negative numbers
  if (type == PRINTF_TYPE_INT && num < 0) {
    is_negative = TRUE;
    num = -num;
  }
  
  // Convert number to string
  if (type == PRINTF_TYPE_UINT) {
    do {
      num_str[len++] = '0' + (num % 10);
      num /= 10;
    } while (num > 0);
  } else {
    do {
      num_str[len++] = '0' + (num % 10);
      num /= 10;
    } while (num > 0);
  }
  
  // Reverse string
  for (I64 i = 0; i < len / 2; i++) {
    U8 temp = num_str[i];
    num_str[i] = num_str[len - 1 - i];
    num_str[len - 1 - i] = temp;
  }
  
  // Add sign if needed
  if (is_negative)
    num_str[len++] = '-';
  else if (flags & PRINTF_FLAG_SIGN)
    num_str[len++] = '+';
  else if (flags & PRINTF_FLAG_SPACE)
    num_str[len++] = ' ';
    
  // Pad with zeros or spaces
  I64 padding = width - len;
  if (padding > 0) {
    if (flags & PRINTF_FLAG_ZERO && !(flags & PRINTF_FLAG_LEFT)) {
      for (I64 i = 0; i < padding; i++)
        buf[i] = '0';
      StrCpy(buf + padding, num_str);
    } else {
      if (!(flags & PRINTF_FLAG_LEFT)) {
        for (I64 i = 0; i < padding; i++)
          buf[i] = ' ';
        StrCpy(buf + padding, num_str);
      } else {
        StrCpy(buf, num_str);
        for (I64 i = 0; i < padding; i++)
          buf[len + i] = ' ';
      }
    }
  } else {
    StrCpy(buf, num_str);
  }
}

// Main printf function
U0 Printf(I64 argc, U8 **argv) {
  if (argc < 2) {
    "Usage: printf FORMAT [ARGUMENT]...\n";
    return;
  }
  
  U8 *format = argv[1];
  I64 arg_index = 2;
  U8 *p = format;
  U8 buf[PRINTF_MAX_FORMAT];
  
  while (*p) {
    if (*p != '%') {
      PutChar(*p++);
      continue;
    }
    
    p++;  // Skip '%'
    
    // Handle %% escape
    if (*p == '%') {
      PutChar('%');
      p++;
      continue;
    }
    
    // Parse format specifier
    I64 width, precision, flags, type;
    I64 spec_len = ParseFormatSpec(p, &width, &precision, &flags, &type);
    if (spec_len == 0) {
      PutChar('%');
      p++;
      continue;
    }
    
    p += spec_len;
    
    // Handle arguments
    if (arg_index >= argc) {
      "printf: missing argument\n";
      return;
    }
    
    switch (type) {
      case PRINTF_TYPE_INT:
      case PRINTF_TYPE_UINT: {
        I64 num = StrToI64(argv[arg_index]);
        FormatNumber(num, buf, width, precision, flags, type);
        "%s", buf;
        break;
      }
      case PRINTF_TYPE_STRING: {
        U8 *str = argv[arg_index];
        I64 len = StrLen(str);
        if (precision >= 0 && precision < len)
          len = precision;
          
        I64 padding = width - len;
        if (padding > 0 && !(flags & PRINTF_FLAG_LEFT)) {
          for (I64 i = 0; i < padding; i++)
            PutChar(' ');
        }
        
        for (I64 i = 0; i < len; i++)
          PutChar(str[i]);
          
        if (padding > 0 && (flags & PRINTF_FLAG_LEFT)) {
          for (I64 i = 0; i < padding; i++)
            PutChar(' ');
        }
        break;
      }
      case PRINTF_TYPE_CHAR: {
        I64 padding = width - 1;
        if (padding > 0 && !(flags & PRINTF_FLAG_LEFT)) {
          for (I64 i = 0; i < padding; i++)
            PutChar(' ');
        }
        PutChar(argv[arg_index][0]);
        if (padding > 0 && (flags & PRINTF_FLAG_LEFT)) {
          for (I64 i = 0; i < padding; i++)
            PutChar(' ');
        }
        break;
      }
      case PRINTF_TYPE_POINTER: {
        U8 *ptr = argv[arg_index];
        "0x%X", (I64)ptr;
        break;
      }
    }
    
    arg_index++;
  }
  
  "\n";
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Printf(__argc, __argv);
#endif 