#!/bin/bash
# install/llm.sh - Installation script for Ollama (local LLM)

echo "Starting Ollama installation..."

if command -v ollama &> /dev/null; then
    echo "Ollama is already installed."
else
    echo "Installing Ollama via official install script..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Check if Ollama service is running, if not, try to start it in background if possible
# Note: In some environments, systemd might not be available.
if pgrep -x "ollama" > /dev/null; then
    echo "Ollama is already running."
else
    echo "Starting Ollama serve in background..."
    ollama serve > ollama.log 2>&1 &
    sleep 5
fi

# Pull a small model for testing
echo "Pulling llama3 model (this might take a while)..."
ollama pull llama3

echo "Ollama setup complete."
