#!/bin/bash

set -e  # Exit immediately if any command fails

echo "Updating package lists and installing dependencies..."
apt update && apt install -y screen curl git lsof psmisc

# Function to kill any process using port 3001
kill_process_on_port() {
    if command -v fuser &>/dev/null; then
        fuser -k 3001/tcp 2>/dev/null && echo "Killed process using port 3001 with fuser."
    else
        echo "fuser not found, using lsof instead..."
        lsof -ti :3001 | xargs kill -9 2>/dev/null || echo "No process found on port 3001."
    fi
}

echo "Removing old Go version..."
rm -rf /usr/local/go

# Install Go
GO_VERSION="1.23.1"
echo "Installing Go $GO_VERSION..."
wget -q https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz -O /tmp/go$GO_VERSION.linux-amd64.tar.gz
tar -C /usr/local -xzf /tmp/go$GO_VERSION.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc

# Verify Go installation
if ! go version | grep -q "go$GO_VERSION"; then
    echo "Go installation failed! Exiting..."
    exit 1
fi

echo "Installing Rust..."
if ! command -v rustc &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "Installing RISC Zero toolchain..."
if ! command -v rzup &>/dev/null; then
    if curl -L https://risczero.com/install -o /tmp/rzup_install.sh; then
        bash /tmp/rzup_install.sh
        source "$HOME/.bashrc"
    else
        echo "rzup installer not available, attempting alternative installation..."
        cargo install cargo-binstall
        cargo binstall cargo-risczero
    fi
fi

echo "Please enter your private key:"
read -s PRIVATE_KEY
echo "Private key recorded."

# Clone LayerEdge light node if it doesn't exist
if [ ! -d "light-node" ]; then
    git clone https://github.com/Layer-Edge/light-node.git
else
    echo "LayerEdge light node directory already exists. Skipping clone..."
fi

# Always continue the execution, even if the directory exists
cd light-node || { echo "Failed to enter light-node directory!"; exit 1; }

# Kill any process using port 3001
kill_process_on_port

# Run in a detached screen session
echo "Starting LayerEdge node in a screen session..."
screen -dmS layeredge bash -c '
    cd risc0-merkle-service
    echo "Building Merkle service..."
    cargo build --release
    ./target/release/host &

    cd ..
    echo "Building and running LayerEdge light node..."
    go mod tidy
    go build -o light-node
    ./light-node
'

echo "LayerEdge node is now running in a detached screen session."
echo "To attach to the session, use: screen -r layeredge"
