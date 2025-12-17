echo "Checking who we are..."
whoami

echo "Listing current directory..."
pwd
ls -la .

echo "Adding personal .gitconfig settings..."
DOTFILES_GITCONFIG="$PWD/.gitconfig"
# Check if the include path is already configured to avoid duplicates
# "git config" will automatically create ~/.gitconfig if it doesn't exist.
if ! git config --global --get-all include.path | grep -q "$DOTFILES_GITCONFIG"; then
    git config --global --add include.path "$DOTFILES_GITCONFIG"
    echo "Linked .gitconfig via include.path"
fi

# Function to account for some devcontainers running as root or other users
# with and without sudo supported etc. and wanting to install global node
# packages (e.g. Gemini CLI).
install_npm_global() {
    PACKAGE="$1"
    
    # Get the path where npm wants to install global packages
    NPM_PREFIX=$(npm config get prefix)
    
    # Check if the current user has write access to that path
    # We check both the prefix and the lib/node_modules folder to be safe.
    if [ -w "$NPM_PREFIX" ] || [ -w "$NPM_PREFIX/lib/node_modules" ]; then
        echo "Installing $PACKAGE (no sudo needed)..."
        npm install -g "$PACKAGE"
        
    # If not writable, check if sudo exists
    elif command -v sudo >/dev/null 2>&1; then
        echo "Installing $PACKAGE via sudo..."
        sudo npm install -g "$PACKAGE"
        
    # Fallback: No sudo and no write access. 
    else
        echo "Warning: No write access to $NPM_PREFIX and 'sudo' is not available."
        echo "Attempting install anyway (likely to fail)..."
        npm install -g "$PACKAGE"
    fi
}

echo "Installing Gemini CLI..."
install_npm_global "@google/gemini-cli"
