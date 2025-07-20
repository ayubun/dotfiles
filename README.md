# Dotfiles Installation System

A robust, modular dotfiles installation system with comprehensive error detection, multi-script support, and both full installation and individual script execution capabilities.

## Installation Methods

### 1. Full Installation

Run the complete installation with all dependencies and scripts:

```bash
# Basic installation (programs only)
./install.sh

# With extra programs (includes programs/extras/)
./install.sh -e

# With verbose output (detailed logging)
./install.sh -v

# With extras and verbose (recommended for debugging)
./install.sh -ev
```

**Key Features:**
- ✅ **Accurate error detection** - Fixed critical exit code bugs that previously masked failures
- ✅ **Timeout handling** - Automatically detects hung scripts and switches to interactive mode
- ✅ **Comprehensive logging** - Tracks failed and prompted scripts with detailed reports
- ✅ **Automatic cleanup** - Removes temporary files and logs after execution

### 2. Individual Script Execution (Recommended)

Run individual scripts or multiple scripts with all necessary dependencies using the `with-deps` wrapper:

```bash
# Single script execution (dependencies run automatically)
./with-deps programs/ubuntu/packages.sh

# Multiple scripts sequentially (dependencies run once)
./with-deps programs/ubuntu/lazygit.sh programs/ubuntu/kubectl.sh

# Mix different script types in one command
./with-deps dependencies/create-dirs.sh programs/ubuntu/packages.sh programs/extras/java.sh

# Complex multi-tool installation
./with-deps programs/ubuntu/packages.sh programs/ubuntu/lazygit.sh programs/ubuntu/kubectl.sh programs/extras/java.sh
```

**Multi-Script Benefits:**
- 🚀 **Efficiency** - Dependencies run once, then all scripts execute sequentially
- 📊 **Progress tracking** - Individual script success/failure reporting
- 🧹 **Automatic cleanup** - Temporary files cleaned up after all scripts complete
- 📋 **Execution summary** - Detailed report of successes and failures

### 3. Standalone Script Execution (Limited)

Some scripts can run standalone, but `with-deps` is **strongly recommended**:

```bash
# Direct execution (missing shared functions like safer-apt, apt-fast)
bash programs/ubuntu/lazygit.sh

# Better: Use with-deps for full functionality
./with-deps programs/ubuntu/lazygit.sh
```

## Architecture

### Core Files

- **`install.sh`** - Main installation orchestrator with robust error detection
- **`dependencies/shared-functions.sh`** - Shared functions exported to all scripts
- **`with-deps`** - Enhanced wrapper for individual/multi-script execution
  - Always runs dependencies first
  - Supports multiple scripts in one command
  - Comprehensive success/failure tracking
  - Automatic cleanup

### Shared Functions

Available to all scripts when run via `install.sh` or `with-deps`:

- **`safer-apt`** - Robust apt installation with timeout and retry logic
- **`safer-apt-fast`** - Fast apt installation using apt-fast with fallbacks
- **`fix-apt`** - Repair common apt package manager issues
- **`unlock-apt`** - Clear various apt lock files
- **`run_script_parallel`** - Execute scripts in parallel (used by install.sh)

### Directory Structure

```
dotfiles/
├── install.sh                    # Main installer with fixed error detection
├── with-deps                     # Multi-script wrapper with cleanup
├── dependencies/                 # Core dependencies (always run first)
│   ├── shared-functions.sh       # Shared functions and utilities
│   ├── create-dirs.sh            # Create essential directories
│   ├── symlink-timeout.sh        # Symlink timeout utility
│   ├── ubuntu/
│   │   └── apt-fast-and-packages.sh  # Fast package manager setup
│   └── mac/
│       └── brew-and-packages.sh      # Homebrew setup
├── programs/                     # Main installation scripts
│   ├── lunarvim.sh               # Neovim distribution
│   ├── ohmyz.sh                  # Oh My Zsh + Powerlevel10k
│   ├── ubuntu/                   # Ubuntu-specific programs
│   │   ├── packages.sh           # Essential system packages
│   │   ├── lazygit.sh            # Git TUI
│   │   ├── kubectl.sh            # Kubernetes CLI
│   │   └── grpcurl.sh            # gRPC client
│   └── extras/                   # Optional programs (-e flag)
│       └── java.sh               # OpenJDK installation
└── configs/                      # Configuration files
    ├── .zshrc                    # Zsh configuration
    ├── .vimrc                    # Vim configuration
    ├── .gitconfig                # Git configuration
    ├── .p10k.zsh                 # Powerlevel10k theme
    └── lazygit/                  # Lazygit configuration
        └── config.yml
```

## Features

### Robust Error Detection
- **Fixed Critical Bugs**: Resolved exit code masking that caused false success reports
- **Accurate Failure Tracking**: Scripts that fail are properly detected and logged
- **Real Exit Codes**: `install.sh` exits with appropriate codes based on actual results
- **Detailed Logging**: Failed scripts logged to `tmp/failed_scripts.log`

### Smart Script Execution
- **Timeout Detection**: Scripts hanging (waiting for input) are automatically detected
- **Interactive Fallback**: Hung scripts are killed and re-run interactively
- **Prompted Script Tracking**: Scripts requiring user input are logged to `tmp/prompted_scripts.log`
- **Multi-Script Support**: Run multiple scripts sequentially with shared dependency setup
- **Automatic Cleanup**: All temporary files and logs are cleaned up after execution

### Dependency Management
- **Always Available**: Dependencies automatically run before any script execution
- **Shared Functions**: Common utilities available to all scripts via `dependencies/shared-functions.sh`
- **Environment Setup**: Variables like `DOTFILES_FOLDER` automatically configured
- **Graceful Fallbacks**: Scripts provide fallback implementations for standalone operation

### Platform Support
- **Ubuntu/Debian**: Full support with apt-fast integration
- **macOS**: Homebrew-based installation with platform-specific scripts
- **Cross-platform**: Shared scripts work across both platforms

## Usage Examples

### Development Workflow
```bash
# Set up development environment
./with-deps programs/ubuntu/packages.sh programs/ubuntu/lazygit.sh programs/extras/java.sh

# Quick tool installation
./with-deps programs/ubuntu/kubectl.sh programs/ubuntu/grpcurl.sh

# Full development setup
./install.sh -e  # Install everything including extras
```

### Package Management
```bash
# Install core packages only
./with-deps programs/ubuntu/packages.sh

# Install packages with git workflow tools
./with-deps programs/ubuntu/packages.sh programs/ubuntu/lazygit.sh
```

### Configuration Management
```bash
# Set up shell and editor configs
./with-deps programs/ohmyz.sh programs/lunarvim.sh

# Just create necessary directories
./with-deps dependencies/create-dirs.sh
```

### Debugging and Troubleshooting
```bash
# Verbose installation with detailed output
./install.sh -ev

# Check what failed after installation
cat tmp/failed_scripts.log
cat tmp/prompted_scripts.log

# Run individual problematic script for debugging
./with-deps programs/ubuntu/problematic-script.sh
```

## Error Handling

### Exit Codes
- **0**: All scripts completed successfully
- **1**: One or more scripts failed (check logs for details)
- **130**: Installation interrupted by user (Ctrl+C)

### Log Files
- **`tmp/failed_scripts.log`**: Scripts that exited with non-zero codes
- **`tmp/prompted_scripts.log`**: Scripts that required user interaction
- **`tmp/with-deps-*.log`**: Individual script execution logs (cleaned up automatically)

### Failure Recovery
```bash
# Re-run specific failed scripts
./with-deps $(cat tmp/failed_scripts.log)

# Debug with verbose output
./install.sh -v

# Manual script execution for debugging
bash -x programs/ubuntu/problematic-script.sh
```

## Troubleshooting

### Common Issues

1. **Script hangs indefinitely**:
   - **Cause**: Script waiting for sudo password or user input
   - **Solution**: The installer detects this and switches to interactive mode automatically
   - **Alternative**: Use `./with-deps` for more controlled execution

2. **Permission denied errors**:
   - **Cause**: Scripts not executable or insufficient sudo privileges
   - **Solution**: 
     ```bash
     chmod +x with-deps
     sudo -v  # Verify sudo access
     ```

3. **Missing shared functions**:
   - **Cause**: Script run without dependency loading
   - **Solution**: Always use `./with-deps script.sh` instead of `bash script.sh`
   - **Check**: Ensure `dependencies/shared-functions.sh` exists and is readable

4. **False success reports** (Fixed in latest version):
   - **Was**: Scripts failing but reported as successful
   - **Fix**: Exit code detection completely rewritten to capture real results
   - **Verify**: Check `tmp/failed_scripts.log` for actual failures

5. **Temporary files not cleaned up**:
   - **Cause**: Script interrupted before completion
   - **Solution**: `with-deps` automatically cleans up on exit; manually remove `tmp/` if needed

### Advanced Debugging

```bash
# Enable bash debugging for specific script
bash -x programs/ubuntu/problematic-script.sh

# Check shared functions are loading
./with-deps --help  # Should show multi-script usage

# Verify dependency execution
./with-deps dependencies/create-dirs.sh  # Should run all deps first

# Test exit code detection
echo 'exit 1' > /tmp/test-fail.sh && chmod +x /tmp/test-fail.sh
./with-deps /tmp/test-fail.sh  # Should report failure correctly
```

## Development Guidelines

### Adding New Scripts

1. **Choose correct location**:
   - Core dependencies → `dependencies/`
   - OS-specific deps → `dependencies/{ubuntu,mac}/`
   - Main programs → `programs/`
   - Optional programs → `programs/extras/`
   - OS-specific programs → `programs/{ubuntu,mac}/`

2. **Use shared functions**:
   ```bash
   # Scripts automatically have access to:
   safer-apt install package-name
   safer-apt-fast install package-name
   fix-apt  # Repair package issues
   unlock-apt  # Clear locks
   ```

3. **Make scripts idempotent**:
   ```bash
   # Check before installing
   if ! command -v tool &> /dev/null; then
       install_tool
   fi
   ```

4. **Handle temporary directories**:
   ```bash
   # Use smart temp handling
   if [[ -d "$HOME/dotfiles" ]]; then
       TMP_DIR="$HOME/dotfiles/tmp"
       mkdir -p "$TMP_DIR"
   else
       TMP_DIR=$(mktemp -d)
   fi
   ```

5. **Test thoroughly**:
   ```bash
   # Test standalone
   bash programs/new-script.sh
   
   # Test with dependencies
   ./with-deps programs/new-script.sh
   
   # Test multi-script
   ./with-deps programs/new-script.sh programs/ubuntu/packages.sh
   ```

### Script Best Practices

- **Exit codes**: Use appropriate exit codes (0 for success, 1+ for failure)
- **Error handling**: Don't mask errors with `|| true` unless intentional
- **User interaction**: Minimize prompts; use non-interactive flags when possible
- **Logging**: Use descriptive output for debugging
- **Dependencies**: Clearly document what the script requires

This system is now battle-tested with proper error detection, multi-script support, and comprehensive cleanup. Happy dotfile management! 🚀 