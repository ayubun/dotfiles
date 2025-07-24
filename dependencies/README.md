# Dependencies Directory

This directory contains essential setup scripts that **must** be run before other installation scripts can function properly. Dependencies are automatically executed by both `install.sh` and `with-deps` to ensure a consistent, properly configured environment.

## Purpose & Philosophy

Dependencies provide the foundational layer for all other scripts. They handle:

- **Package Managers**: Install and configure package managers (Homebrew for macOS, apt-fast for Ubuntu)
- **Core Utilities**: Install essential CLI tools like GNU `parallel` for faster script execution
- **System Setup**: Create necessary directories, configure system settings, establish base environment
- **Shared Functions**: Provide common utilities (`safer-apt`, `fix-apt`, etc.) via `shared-functions.sh`
- **Prerequisites**: Install tools that other scripts depend on (compilers, language runtimes, etc.)

## Key Components

### `shared-functions.sh` - The Foundation

This file contains shared utilities available to all scripts when run via `install.sh` or `with-deps`:

```bash
# APT package management with retries and error handling
safer-apt install package-name
safer-apt-fast install package-name  # Uses apt-fast for speed

# APT troubleshooting utilities
fix-apt          # Repair broken packages
unlock-apt       # Clear various lock files

# Parallel execution (used by install.sh)
run_script_parallel script-path
```

**Auto-loading**: These functions are automatically available when scripts run through the main system - no manual sourcing required.

## Execution Flow

### Automatic Execution Order

Dependencies run **every time** in this precise order:

1. **General dependencies** (`dependencies/*.sh`)
   - Cross-platform setup scripts
   - Run on all systems regardless of OS

2. **OS-specific dependencies** (`dependencies/{ubuntu,mac}/*.sh`)
   - Platform-specific requirements
   - Only scripts matching current OS are executed

### When Dependencies Run

#### Full Installation (`./install.sh`)
```bash
./install.sh    # Dependencies → Programs
./install.sh -e # Dependencies → Programs → Extras
```

#### Individual Script Execution (`./with-deps`)
```bash
# Single script
./with-deps programs/ubuntu/packages.sh
# Flow: Dependencies → packages.sh

# Multiple scripts  
./with-deps programs/ubuntu/lazygit.sh programs/ubuntu/kubectl.sh
# Flow: Dependencies → lazygit.sh → kubectl.sh
```

**Efficiency Note**: With `with-deps`, dependencies run once at the beginning, then all target scripts execute sequentially.

## Current Dependencies

### General Dependencies (`dependencies/`)

#### `shared-functions.sh`
- **Purpose**: Provides shared utility functions to all scripts
- **Functions**: `safer-apt`, `safer-apt-fast`, `fix-apt`, `unlock-apt`, `run_script_parallel`
- **Auto-loaded**: By both `install.sh` and `with-deps`
- **Critical**: Required for proper script operation

#### `create-dirs.sh`  
- **Purpose**: Creates essential directories required by other scripts
- **Creates**: `~/.vimtmp`, `~/.config`, `~/.config/lazygit`
- **Idempotent**: Safe to run multiple times
- **Fixed**: Now uses `mkdir -p` to avoid false failures

#### `symlink-timeout.sh`
- **Purpose**: Configures symlink handling utilities
- **Note**: May show "File exists" warnings (this is normal)
- **Platform**: Cross-platform utility setup

### Ubuntu Dependencies (`dependencies/ubuntu/`)

#### `apt-fast-and-packages.sh`
- **Purpose**: Install and configure apt-fast for faster package installations
- **Installs**: `apt-fast`, `parallel`, essential repositories
- **Benefits**: Dramatically speeds up subsequent package installations
- **Configuration**: Sets up PPA repositories for newer software versions

### Mac Dependencies (`dependencies/mac/`)

#### `brew-and-packages.sh`
- **Purpose**: Install and configure Homebrew package manager
- **Installs**: Homebrew, GNU `parallel`, essential tools
- **Platform**: macOS-specific package management setup
- **Note**: May require password input for initial Homebrew installation

## Error Handling & Reliability

### Robust Failure Detection
- **Fixed Critical Bug**: Dependencies now properly report failures (exit codes correctly captured)
- **Logging**: Failed dependencies logged to `tmp/failed_scripts.log`
- **Continuation**: Failed dependencies don't stop main script execution (logged warnings instead)
- **Visibility**: Users see which dependencies failed and can investigate

### Non-Interactive Operation
- **Goal**: Dependencies should run without user prompts when possible
- **Implementation**: Use `DEBIAN_FRONTEND=noninteractive`, `--yes` flags, etc.
- **Fallback**: If interaction needed, scripts are re-run interactively
- **Tracking**: Scripts requiring interaction logged to `tmp/prompted_scripts.log`

## Development Guidelines

### Adding New Dependencies

1. **Placement Strategy**:
   ```bash
   # Cross-platform (most common)
   dependencies/new-tool.sh
   
   # Ubuntu/Debian specific
   dependencies/ubuntu/ubuntu-specific.sh
   
   # macOS specific  
   dependencies/mac/mac-specific.sh
   ```

2. **Script Structure**:
   ```bash
   #!/bin/bash
   
   # Check if already installed (idempotent)
   if command -v tool &> /dev/null; then
       echo "Tool already installed, skipping..."
       exit 0
   fi
   
   # Install logic here
   install_tool
   
   # Verify installation
   if ! command -v tool &> /dev/null; then
       echo "Failed to install tool"
       exit 1
   fi
   ```

3. **Best Practices**:
   - **Idempotent**: Safe to run multiple times
   - **Focused**: One dependency per script
   - **Non-interactive**: Avoid prompts when possible
   - **Verified**: Check installation success
   - **Documented**: Clear comments explaining purpose

4. **Shared Functions**:
   ```bash
   # Add to shared-functions.sh if function will be used by multiple scripts
   new-utility-function() {
       # Implementation
   }
   export -f new-utility-function
   ```

### Testing Dependencies

```bash
# Test individual dependency
./with-deps dependencies/new-dependency.sh

# Test with existing system
./with-deps dependencies/new-dependency.sh programs/ubuntu/packages.sh

# Test full dependency chain
./install.sh -v  # Verbose output shows dependency execution
```

### Integration Requirements

Dependencies should integrate smoothly with the broader system:

- **Environment Variables**: `DOTFILES_FOLDER` automatically available
- **Temporary Files**: Use `$DOTFILES_FOLDER/tmp/` when possible
- **Logging**: Output to stdout/stderr for capture in logs
- **Exit Codes**: Use proper codes (0=success, 1+=failure)
- **Cleanup**: Clean up temporary files on exit

## Troubleshooting Dependencies

### Common Dependency Issues

1. **Network failures**:
   ```bash
   # Check internet connectivity
   curl -Is https://google.com | head -n 1
   
   # Re-run specific dependency
   ./with-deps dependencies/problematic-dep.sh
   ```

2. **Permission issues**:
   ```bash
   # Verify sudo access
   sudo -v
   
   # Check script permissions
   ls -la dependencies/
   ```

3. **Package manager issues**:
   ```bash
   # Ubuntu: Clear package manager state
   sudo apt update && sudo apt --fix-broken install
   
   # macOS: Reinstall Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   ```

### Debugging Dependencies

```bash
# Run dependencies only
./with-deps dependencies/create-dirs.sh

# Verbose dependency execution  
./install.sh -v  # Shows detailed dependency output

# Check what failed
cat tmp/failed_scripts.log

# Manual execution for debugging
bash -x dependencies/problematic-script.sh
```

## Advanced Concepts

### Dependency Optimization

- **Parallel Execution**: `install.sh` runs some dependencies in parallel for speed
- **Caching**: Idempotent scripts avoid redundant work
- **Conditional Logic**: OS detection ensures only relevant dependencies run

### Integration with Main System

Dependencies seamlessly integrate with:
- **Error Detection**: Fixed exit code bugs ensure real failures are caught
- **Multi-Script Support**: Dependencies run once, benefit multiple target scripts  
- **Cleanup**: Temporary files automatically cleaned up
- **Logging**: Comprehensive success/failure tracking

## Migration Notes

If migrating from older versions:
- **Shared Functions**: Now located at `dependencies/shared-functions.sh` (was `deps.sh`)
- **Error Detection**: Much more accurate - may reveal previously hidden failures
- **Multi-Script**: Can now run multiple scripts efficiently with shared dependency setup

Dependencies form the reliable foundation that makes the entire dotfiles system work smoothly and consistently across different environments. 🏗️