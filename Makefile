# HolyUtils Makefile
# Builds all utilities in the dist/ directory

# Compiler settings
HCC = hcc
CFLAGS = -O2 -Wall
DIST_DIR = dist

# List of all utility source files
UTILS = alias ls cat mkdir rm cp grep mv echo printf wc head tail angshell

# Default target
all: $(DIST_DIR) $(addprefix $(DIST_DIR)/, $(UTILS))

# Create distribution directory
$(DIST_DIR):
	mkdir -p $(DIST_DIR)

# Build individual utilities
$(DIST_DIR)/%: %.hc
	$(HCC) $(CFLAGS) -o $@ $<

# Clean build artifacts
clean:
	rm -rf $(DIST_DIR)

# Install utilities to system (requires root)
install: all
	sudo cp $(DIST_DIR)/* /usr/local/bin/

# Uninstall utilities from system (requires root)
uninstall:
	sudo rm -f $(addprefix /usr/local/bin/, $(UTILS))

.PHONY: all clean install uninstall 