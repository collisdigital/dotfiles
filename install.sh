echo "Checking who we are..."
whoami

echo "Listing current directory..."
ls -la .

echo "Adding personal .gitconfig settings..."
DOTFILES_GITCONFIG="$PWD/.gitconfig"
# Check if the include path is already configured to avoid duplicates
# "git config" will automatically create ~/.gitconfig if it doesn't exist.
if ! git config --global --get-all include.path | grep -q "$DOTFILES_GITCONFIG"; then
    git config --global --add include.path "$DOTFILES_GITCONFIG"
    echo "Linked .gitconfig via include.path"
fi

echo "Installing Gemini CLI..."
npm install @google/gemini-cli
