#!/bin/bash
# Exit on error for safety
set -e

# --- Configuration ---
DOTFILES_GITCONFIG="$PWD/.gitconfig"
NPM_PACKAGE="@google/gemini-cli"

# --- Styling Helpers ---
print_header() { echo -e "\n\033[1;35m[ $1 ]\033[0m"; }
print_status() { echo -e "\033[0;34m[SETUP]\033[0m $1"; }
print_warning() { echo -e "\033[0;33m[WARNING]\033[0m $1"; }

# --- Debug Function ---
print_debug_info() {
    print_header "DEBUG: ENVIRONMENT CONTEXT"
    
    echo "Timestamp       : $(date)"
    echo "User            : $(whoami) (UID: $(id -u))"
    echo "User Groups     : $(groups)"
    echo "Home Dir (\$HOME): $HOME"
    echo "Current Dir     : $PWD"
    echo "Shell           : $SHELL"
    
    # Check tool availability and specific configs
    echo "Has Sudo?       : $(command -v sudo >/dev/null && echo "Yes" || echo "No")"
    
    if command -v npm >/dev/null; then
        echo "NPM Path        : $(command -v npm)"
        echo "NPM Version     : $(npm -v)"
        echo "NPM Prefix      : $(npm config get prefix)"
    else
        echo "NPM             : Not installed"
    fi

    if command -v git >/dev/null; then
        echo "Git Version     : $(git --version)"
    else
        echo "Git             : Not installed"
    fi

    echo "-----------------------------------------------------------"
    echo "Directory Listing ($PWD):"
    ls -la
    echo "==========================================================="
}

# --- Core Logic Functions ---

setup_git_config() {
    print_header "Configuring Git"

    if [ ! -f "$DOTFILES_GITCONFIG" ]; then
        print_warning "$DOTFILES_GITCONFIG not found. Skipping git config."
        return 0
    fi

    # Use 'include.path' to safely merge aliases without overwriting
    if ! git config --global --get-all include.path | grep -q "$DOTFILES_GITCONFIG"; then
        git config --global --add include.path "$DOTFILES_GITCONFIG"
        print_status "Linked dotfiles gitconfig via include.path."
    else
        print_status "Git config already linked. Skipping."
    fi
}

install_npm_global() {
    local PACKAGE="$1"
    print_header "Installing NPM Package: $PACKAGE"

    if ! command -v npm >/dev/null 2>&1; then
        print_warning "npm is not installed. Skipping $PACKAGE."
        return 0
    fi

    local NPM_PREFIX
    NPM_PREFIX=$(npm config get prefix)
    
    # PERMISSION CHECK STRATEGY:
    # 1. Try standard install if we own the folder.
    # 2. Try sudo if we don't own it but have sudo.
    # 3. Fallback to local user prefix if locked down.

    if [ -w "$NPM_PREFIX" ] || [ -w "$NPM_PREFIX/lib/node_modules" ]; then
        print_status "Standard install (writable prefix found)..."
        npm install -g "$PACKAGE"
        
    elif command -v sudo >/dev/null 2>&1; then
        print_status "Permission denied to $NPM_PREFIX. Elevating with sudo..."
        sudo npm install -g "$PACKAGE"
        
    else
        print_warning "No write access and no sudo. Switching to local user prefix..."
        
        local LOCAL_PREFIX="$HOME/.npm-global"
        mkdir -p "$LOCAL_PREFIX"
        npm config set prefix "$LOCAL_PREFIX"
        
        # Enable it for this session immediately
        export PATH="$LOCAL_PREFIX/bin:$PATH"
        
        # Persist to shell config
        for RC_FILE in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [ -f "$RC_FILE" ] && ! grep -q "$LOCAL_PREFIX/bin" "$RC_FILE"; then
                 echo "" >> "$RC_FILE"
                 echo "# NPM Global Path for user-level installs" >> "$RC_FILE"
                 echo "export PATH=\"$LOCAL_PREFIX/bin:\$PATH\"" >> "$RC_FILE"
                 print_status "Updated $RC_FILE with new NPM path."
            fi
        done

        npm install -g "$PACKAGE"
    fi
    
    print_status "$PACKAGE installed successfully."
}

# --- Main Execution ---

print_debug_info
setup_git_config
install_npm_global "$NPM_PACKAGE"

print_header "Setup Complete!"
