#define SHELL_MAX_CMD_LEN 1024
#define SHELL_MAX_ARGS 64
#define SHELL_HISTORY_SIZE 1000
#define SHELL_PROMPT "angshell$ "

// Shell command history
class ShellHistory {
  U8 commands[SHELL_HISTORY_SIZE][SHELL_MAX_CMD_LEN];
  I64 count;
  I64 current;
};

// Shell state
class ShellState {
  ShellHistory history;
  U8 current_dir[SHELL_MAX_CMD_LEN];
  U8 home_dir[SHELL_MAX_CMD_LEN];
  Bool running;
};

// Initialize shell state
U0 InitShell(ShellState *state) {
  state->history.count = 0;
  state->history.current = 0;
  state->running = TRUE;
  
  // Get current directory
  GetCwd(state->current_dir, SHELL_MAX_CMD_LEN);
  
  // Get home directory
  GetHomeDir(state->home_dir, SHELL_MAX_CMD_LEN);
}

// Add command to history
U0 AddToHistory(ShellState *state, U8 *cmd) {
  if (state->history.count < SHELL_HISTORY_SIZE) {
    StrCpy(state->history.commands[state->history.count], cmd);
    state->history.count++;
    state->history.current = state->history.count;
  } else {
    // Shift history up
    I64 i;
    for (i = 0; i < SHELL_HISTORY_SIZE - 1; i++)
      StrCpy(state->history.commands[i], state->history.commands[i + 1]);
    StrCpy(state->history.commands[SHELL_HISTORY_SIZE - 1], cmd);
    state->history.current = SHELL_HISTORY_SIZE;
  }
}

// Get command from history
U8 *GetHistoryCommand(ShellState *state, I64 direction) {
  if (state->history.count == 0)
    return NULL;
    
  I64 new_current = state->history.current + direction;
  if (new_current < 0)
    new_current = state->history.count - 1;
  else if (new_current >= state->history.count)
    new_current = 0;
    
  state->history.current = new_current;
  return state->history.commands[state->history.current];
}

// Parse command line into arguments
I64 ParseCommand(U8 *cmd, U8 **args) {
  I64 argc = 0;
  U8 *p = cmd;
  Bool in_quotes = FALSE;
  U8 quote_char = 0;
  
  while (*p && argc < SHELL_MAX_ARGS - 1) {
    // Skip leading whitespace
    while (*p == ' ' || *p == '\t')
      p++;
    if (!*p)
      break;
      
    // Handle quoted strings
    if (*p == '"' || *p == '\'') {
      quote_char = *p;
      in_quotes = TRUE;
      p++;
      args[argc] = p;
      
      while (*p && *p != quote_char)
        p++;
      if (*p == quote_char)
        *p = 0;
      p++;
    } else {
      // Handle unquoted arguments
      args[argc] = p;
      while (*p && *p != ' ' && *p != '\t')
        p++;
      if (*p)
        *p = 0;
      p++;
    }
    
    argc++;
  }
  
  args[argc] = NULL;
  return argc;
}

// Execute a command
U0 ExecuteCommand(ShellState *state, U8 *cmd) {
  U8 *args[SHELL_MAX_ARGS];
  I64 argc = ParseCommand(cmd, args);
  
  if (argc == 0)
    return;
    
  // Handle built-in commands
  if (!StrCmp(args[0], "cd")) {
    U8 *path = argc > 1 ? args[1] : state->home_dir;
    if (ChDir(path)) {
      GetCwd(state->current_dir, SHELL_MAX_CMD_LEN);
    } else {
      "cd: %s: No such directory\n", path;
    }
  } else if (!StrCmp(args[0], "pwd")) {
    "%s\n", state->current_dir;
  } else if (!StrCmp(args[0], "exit")) {
    state->running = FALSE;
  } else if (!StrCmp(args[0], "history")) {
    I64 i;
    for (i = 0; i < state->history.count; i++)
      "%d  %s\n", i + 1, state->history.commands[i];
  } else {
    // Try to execute external command
    I64 pid = Fork();
    if (pid == 0) {
      // Child process
      Exec(args[0], args);
      Exit(1);  // If exec fails
    } else if (pid > 0) {
      // Parent process
      I64 status;
      Wait(pid, &status);
    } else {
      "Command not found: %s\n", args[0];
    }
  }
}

// Main shell loop
U0 RunShell(ShellState *state) {
  U8 cmd[SHELL_MAX_CMD_LEN];
  I64 cmd_pos = 0;
  
  while (state->running) {
    // Display prompt
    "%s", SHELL_PROMPT;
    
    // Read command
    cmd_pos = 0;
    while (TRUE) {
      I64 c = GetChar;
      if (c == '\n') {
        cmd[cmd_pos] = 0;
        break;
      } else if (c == '\b' || c == 127) {  // Backspace or Delete
        if (cmd_pos > 0)
          cmd_pos--;
      } else if (c == 27) {  // Escape sequence (arrow keys)
        I64 c2 = GetChar;
        if (c2 == '[') {
          I64 c3 = GetChar;
          if (c3 == 'A') {  // Up arrow
            U8 *hist_cmd = GetHistoryCommand(state, -1);
            if (hist_cmd) {
              StrCpy(cmd, hist_cmd);
              cmd_pos = StrLen(cmd);
              "\r%s%s%s", SHELL_PROMPT, cmd, " " * (SHELL_MAX_CMD_LEN - cmd_pos);
            }
          } else if (c3 == 'B') {  // Down arrow
            U8 *hist_cmd = GetHistoryCommand(state, 1);
            if (hist_cmd) {
              StrCpy(cmd, hist_cmd);
              cmd_pos = StrLen(cmd);
              "\r%s%s%s", SHELL_PROMPT, cmd, " " * (SHELL_MAX_CMD_LEN - cmd_pos);
            }
          }
        }
      } else if (cmd_pos < SHELL_MAX_CMD_LEN - 1) {
        cmd[cmd_pos++] = c;
      }
    }
    
    // Add command to history and execute it
    if (cmd_pos > 0) {
      AddToHistory(state, cmd);
      ExecuteCommand(state, cmd);
    }
  }
}

// Main function
U0 AngShell(I64 argc, U8 **argv) {
  ShellState state;
  InitShell(&state);
  RunShell(&state);
}

// If running as a standalone script, start the shell
#if __CMD_LINE__
AngShell(__argc, __argv);
#endif 