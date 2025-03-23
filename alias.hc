#define ALIAS_MAX_COUNT 100
#define ALIAS_NAME_MAX_LEN 64
#define ALIAS_VALUE_MAX_LEN 256

// Structure to store alias information
class Alias {
  U8 name[ALIAS_NAME_MAX_LEN];
  U8 value[ALIAS_VALUE_MAX_LEN];
};

// Global array to store aliases
Alias aliases[ALIAS_MAX_COUNT];
I64 alias_count = 0;

// Find alias by name
I64 FindAlias(U8 *name) {
  I64 i;
  for (i = 0; i < alias_count; i++) {
    if (!StrCmp(aliases[i].name, name)) {
      return i;
    }
  }
  return -1;
}

// Add or update an alias
Bool AddAlias(U8 *name, U8 *value) {
  if (!name || !value || !*name || !*value) {
    return FALSE;
  }
  
  if (StrLen(name) >= ALIAS_NAME_MAX_LEN || StrLen(value) >= ALIAS_VALUE_MAX_LEN) {
    return FALSE;
  }
  
  I64 index = FindAlias(name);
  
  if (index >= 0) {
    // Update existing alias
    StrCpy(aliases[index].value, value);
  } else {
    // Add new alias
    if (alias_count >= ALIAS_MAX_COUNT) {
      return FALSE;
    }
    
    StrCpy(aliases[alias_count].name, name);
    StrCpy(aliases[alias_count].value, value);
    alias_count++;
  }
  
  return TRUE;
}

// Remove an alias
Bool RemoveAlias(U8 *name) {
  I64 index = FindAlias(name);
  
  if (index < 0) {
    return FALSE;
  }
  
  // Shift elements to fill gap
  I64 i;
  for (i = index; i < alias_count - 1; i++) {
    StrCpy(aliases[i].name, aliases[i + 1].name);
    StrCpy(aliases[i].value, aliases[i + 1].value);
  }
  
  alias_count--;
  return TRUE;
}

// List all aliases
U0 ListAliases() {
  if (alias_count == 0) {
    "No aliases defined.\n";
    return;
  }
  
  I64 i;
  for (i = 0; i < alias_count; i++) {
    "alias %s='%s'\n", aliases[i].name, aliases[i].value;
  }
}

// Process alias command with arguments
U0 ProcessAliasCommand(I64 argc, U8 **argv) {
  if (argc == 1) {
    // No arguments, list all aliases
    ListAliases();
    return;
  }
  
  if (argc == 2) {
    // Single argument, could be "-help" or just an alias name
    if (!StrCmp(argv[1], "-help")) {
      "Usage: alias [name[='value']] [-help]\n";
      "       alias -r name\n";
      "Define or display aliases.\n\n";
      "  -help    Show this help message\n";
      "  -r name  Remove the specified alias\n";
      "With no arguments, all aliases are listed.\n";
      "With just a name, the value of that alias is displayed.\n";
      "With name='value', the alias is set to that value.\n";
      return;
    }
    
    // Check if it's an alias lookup
    I64 index = FindAlias(argv[1]);
    if (index >= 0) {
      "alias %s='%s'\n", aliases[index].name, aliases[index].value;
    } else {
      "alias: %s: not found\n", argv[1];
    }
    return;
  }
  
  if (argc == 3 && !StrCmp(argv[1], "-r")) {
    // Remove alias
    if (RemoveAlias(argv[2])) {
      "Alias '%s' removed.\n", argv[2];
    } else {
      "alias: %s: not found\n", argv[2];
    }
    return;
  }
  
  // Process alias definitions
  I64 i;
  for (i = 1; i < argc; i++) {
    U8 *arg = argv[i];
    U8 *equals_pos = StrFind(arg, "=");
    
    if (!equals_pos) {
      "alias: Invalid syntax: %s\n", arg;
      "Use 'alias name=value' or 'alias -help' for usage.\n";
      continue;
    }
    
    *equals_pos = 0; // Split string at equals sign
    U8 *name = arg;
    U8 *value = equals_pos + 1;
    
    // Remove quotes around value if present
    I64 value_len = StrLen(value);
    if (value_len >= 2 && value[0] == '\'' && value[value_len - 1] == '\'') {
      value[value_len - 1] = 0;
      value++;
    }
    
    if (AddAlias(name, value)) {
      "Alias '%s' set to '%s'.\n", name, value;
    } else {
      "alias: Failed to set alias '%s'.\n", name;
    }
    
    // Restore the equals sign for display purposes
    *equals_pos = '=';
  }
}

// Main function
U0 Alias(I64 argc, U8 **argv) {
  ProcessAliasCommand(argc, argv);
}

// If running as a standalone script, handle arguments
#if __CMD_LINE__
Alias(__argc, __argv);
#endif 