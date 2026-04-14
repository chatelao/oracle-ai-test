#!/bin/bash
# test.sh - Main test script for LLM and Oracle DB integration

echo "=== LLM x Oracle SQLcl Integration Test ==="

# 1. Check Ollama
echo "Checking Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "[OK] Ollama is reachable."
else
    echo "[FAIL] Ollama is not reachable on localhost:11434."
fi

# 2. Check SQLcl
echo "Checking SQLcl..."
if command -v sql &> /dev/null; then
    echo "[OK] SQLcl is installed."
else
    echo "[WARN] SQLcl (sql) not found in PATH."
fi

# 3. Basic LLM connectivity test
echo "Testing LLM (llama3) responsiveness..."
RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Say hello world in SQL",
  "stream": false
}' | jq -r '.response' 2>/dev/null)

if [ -n "$RESPONSE" ]; then
    echo "[OK] LLM responded."
    echo "LLM Response: $RESPONSE"
else
    echo "[FAIL] LLM did not respond or llama3 model is not loaded."
fi

# 4. Basic DB connectivity test (if SQLcl is present)
if command -v sql &> /dev/null; then
    echo "Testing Database connectivity via SQLcl..."
    # Source config if exists
    [ -f "install/db_config.sh" ] && source install/db_config.sh

    # Try a simple select
    if [ -n "$DB_CONN_STR" ]; then
        DB_VERSION=$(echo "SELECT version FROM v\$instance;" | sql -s "$DB_CONN_STR" | grep -E "[0-9]+\.[0-9]+")
        if [ -n "$DB_VERSION" ]; then
            echo "[OK] Database connection successful. Version: $DB_VERSION"
        else
            echo "[FAIL] Could not connect to database or retrieve version."
        fi
    else
        echo "[SKIP] DB_CONN_STR not set. Skipping DB test."
    fi
fi

echo "=== Test Run Complete ==="
