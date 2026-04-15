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
if pgrep -x "ollama" > /dev/null; then
    echo "Ollama is already running."
else
    echo "Starting Ollama serve in background..."
    ollama serve > ollama.log 2>&1 &

    # Wait for Ollama to be ready
    echo "Waiting for Ollama service to be ready..."
    MAX_RETRIES=30
    COUNT=0
    while ! curl -s http://localhost:11434/api/tags > /dev/null; do
        sleep 2
        COUNT=$((COUNT + 1))
        if [ $COUNT -ge $MAX_RETRIES ]; then
            echo "Error: Ollama service failed to start after 60 seconds."
            exit 1
        fi
    done
    echo "Ollama service is ready."
fi

# Pull a small model for testing
LLM_MODEL=${LLM_MODEL:-llama3}
echo "Pulling $LLM_MODEL model (this might take a while)..."
ollama pull "$LLM_MODEL"

echo "Ollama setup complete."
ollama --version
