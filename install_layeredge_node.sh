#!/bin/bash

set -e

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root (use sudo)."
    exit 1
fi

# Function to install Go 1.23.1
install_go() {
    echo "Removing old Go version..."
    rm -rf /usr/local/go

    echo "Installing Go 1.23.1..."
    wget https://dl.google.com/go/go1.23.1.linux-amd64.tar.gz -O /tmp/go1.23.1.linux-amd64.tar.gz
    tar -C /usr/local -xzf /tmp/go1.23.1.linux-amd64.tar.gz
    rm /tmp/go1.23.1.linux-amd64.tar.gz

    export PATH="/usr/local/go/bin:$PATH"
    echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

    go version
}

# Ensure Go is installed and correct version is used
if ! command -v go &> /dev/null || [[ "$(go version)" != *"go1.23.1"* ]]; then
    install_go
fi

# Install required dependencies
apt update && apt install -y screen curl git lsof fuser

# Kill any existing process using port 3001
echo "Checking for existing processes on port 3001..."
if lsof -i :3001 &> /dev/null; then
    echo "Port 3001 is in use. Killing process..."
    fuser -k 3001/tcp
fi

# Clone LayerEdge light node if not already cloned
cd ~
if [ ! -d "layeredge-cli-node" ]; then
    git clone https://github.com/LayerEdge-Network/layeredge-cli-node.git
fi
cd layeredge-cli-node

# Install Risc0 toolchain if not installed
if ! command -v rzup &> /dev/null; then
    echo "Installing Risc0 Toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://risc0.com/install.sh | sh
    export PATH="$HOME/.cargo/bin:$HOME/.risc0/bin:$PATH"
    echo 'export PATH="$HOME/.cargo/bin:$HOME/.risc0/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi

# Ensure cargo-risczero is installed
rzup install cargo-risczero@1.2.5
rzup default cargo-risczero@1.2.5

# Ensure .env file exists
ENV_FILE="$HOME/layeredge-cli-node/light-node/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating .env file..."
    read -p "Please enter your private key: " PRIVATE_KEY
    echo "PRIVATE_KEY=$PRIVATE_KEY" > "$ENV_FILE"
    echo ".env file created successfully."
fi

# Start the LayerEdge node in a detached screen session
echo "Starting LayerEdge light node in a screen session..."
screen -S layeredge-node -dm bash -c 'cd ~/layeredge-cli-node/light-node && export $(cat .env | xargs) && ./light-node'

echo "LayerEdge light node is now running in a screen session named 'layeredge-node'."
echo "To attach to it, run: screen -r layeredge-node"
echo "To detach, press Ctrl + A, then D."
