echo "Listing current directory..."
ls -la .

echo "Symlinking .gitconfig..."
ln -v -s "$PWD/.gitconfig" "$HOME/.gitconfig"

echo "Installing Gemini CLI..."
npm install -g @google/gemini-cli
