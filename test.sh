#!/bin/bash
# test.sh - Main test script for LLM and Oracle DB integration

REPORT_FILE="test-report.md"

echo "=== LLM x Oracle SQLcl Integration Test ==="
echo "# Test Report - $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Test Case | Status | Details |" >> "$REPORT_FILE"
echo "|-----------|--------|---------|" >> "$REPORT_FILE"

log_result() {
    local test_case=$1
    local status=$2
    local details=$3
    echo "| $test_case | $status | $details |" >> "$REPORT_FILE"
}

OLLAMA_URL=${OLLAMA_URL:-http://127.0.0.1:11434}

# 1. Check Ollama
echo "Checking Ollama..."
if curl -s "$OLLAMA_URL/api/tags" > /dev/null; then
    echo "[OK] Ollama is reachable."
    log_result "Check Ollama" "✅ OK" "Ollama is reachable at $OLLAMA_URL"
else
    echo "[FAIL] Ollama is not reachable on $OLLAMA_URL."
    log_result "Check Ollama" "❌ FAIL" "Ollama is not reachable on $OLLAMA_URL"
fi

# 2. Check SQLcl
echo "Checking SQLcl..."
if command -v sql &> /dev/null; then
    if sql -version 2>&1 | grep -q "SQLcl"; then
        echo "[OK] SQLcl is installed and verified."
        log_result "Check SQLcl" "✅ OK" "SQLcl is installed"
    else
        echo "[FAIL] 'sql' command found but it is NOT Oracle SQLcl."
        log_result "Check SQLcl" "❌ FAIL" "'sql' is not Oracle SQLcl"
        # We might want to exit or skip DB tests
    fi
else
    echo "[WARN] SQLcl (sql) not found in PATH."
    log_result "Check SQLcl" "⚠️ WARN" "SQLcl (sql) not found in PATH"
fi

# 3. Basic LLM connectivity test
LLM_MODEL=${LLM_MODEL:-llama3}
echo "Testing LLM ($LLM_MODEL) responsiveness..."
    RESPONSE=$(curl -s -X POST "$OLLAMA_URL/api/generate" -d "$(jq -n --arg model "$LLM_MODEL" --arg prompt "Say hello world in SQL" '{model: $model, prompt: $prompt, stream: false}')" | jq -r '.response' 2>/dev/null)

if [ -n "$RESPONSE" ] && [ "$RESPONSE" != "null" ]; then
    echo "[OK] LLM responded."
    # Sanitize response for markdown table
    SAFE_RESPONSE=$(echo "$RESPONSE" | tr '|' '-' | tr '\n' ' ' | cut -c1-50)
    log_result "LLM Connectivity" "✅ OK" "LLM ($LLM_MODEL) responded: $SAFE_RESPONSE"
else
    echo "[FAIL] LLM did not respond or llama3 model is not loaded."
    log_result "LLM Connectivity" "❌ FAIL" "LLM did not respond or model $LLM_MODEL not loaded"
fi

# 4. Basic DB connectivity test (if SQLcl is present)
if command -v sql &> /dev/null; then
    echo "Testing Database connectivity via SQLcl..."
    # Source config if exists
    [ -f "install/db_config.sh" ] && source install/db_config.sh

    # Try a simple select
    if [ -n "$DB_CONN_STR" ]; then
        # Use pipefail to catch sql errors
        DB_OUTPUT=$(set -o pipefail; echo "SELECT version FROM v\$instance;" | sql -L -s "$DB_CONN_STR" 2>&1)
        DB_EXIT_CODE=$?
        DB_VERSION=$(echo "$DB_OUTPUT" | grep -E "[0-9]+\.[0-9]+")
        if [ $DB_EXIT_CODE -eq 0 ] && [[ ! "$DB_OUTPUT" =~ "ORA-" ]] && [ -n "$DB_VERSION" ]; then
            echo "[OK] Database connection successful. Version: $DB_VERSION"
            log_result "DB Connectivity" "✅ OK" "Database version: $DB_VERSION"
        else
            echo "[FAIL] Could not connect to database or retrieve version."
            echo "Error Details: $DB_OUTPUT"
            # Extract ORA error if present, sanitize pipes
            ORA_ERR=$(echo "$DB_OUTPUT" | grep -o "ORA-[0-9]\+.*" | head -n 1 | cut -c1-100 | tr '|' '-')
            [ -z "$ORA_ERR" ] && ORA_ERR="Unknown Error"
            log_result "DB Connectivity" "❌ FAIL" "Connection failed ($ORA_ERR)"
        fi
    else
        echo "[SKIP] DB_CONN_STR not set. Skipping DB test."
        log_result "DB Connectivity" "⏭️ SKIP" "DB_CONN_STR not set"
    fi
else
    log_result "DB Connectivity" "⏭️ SKIP" "SQLcl not found"
fi

# 5. Integration: LLM generates SQL and SQLcl executes it
if command -v sql &> /dev/null && [ -n "$DB_CONN_STR" ]; then
    echo "Integration Test: LLM generating SQL and executing via SQLcl..."

    PROMPT="Generate a simple Oracle SQL SELECT statement to get the current date from dual. Return ONLY the SQL, no explanation."

    INTEGRATION_RESPONSE=$(curl -s -X POST "$OLLAMA_URL/api/generate" -d "$(jq -n --arg model "$LLM_MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false}')" | jq -r '.response' 2>/dev/null)

    if [ -n "$INTEGRATION_RESPONSE" ] && [ "$INTEGRATION_RESPONSE" != "null" ]; then
        # Extraction: use python helper for more robust SQL extraction
        CLEAN_SQL=$(echo "$INTEGRATION_RESPONSE" | python3 install/extract_sql.py)

        if [ -n "$CLEAN_SQL" ]; then
            echo "Executing LLM generated SQL: $CLEAN_SQL"
            # Ensure SQL ends with semicolon
            [[ "$CLEAN_SQL" != *";" ]] && EXEC_SQL="$CLEAN_SQL;" || EXEC_SQL="$CLEAN_SQL"
            # Capture output and exit code
            SQL_OUTPUT=$(echo "$EXEC_SQL" | sql -L -s "$DB_CONN_STR" 2>&1)
            SQL_EXIT_CODE=$?
            # Sanitize result for markdown table
            CLEAN_RESULT=$(echo "$SQL_OUTPUT" | grep -v "connected" | grep -v "USER          =" | grep -v "URL           =" | grep -v "Error Message =" | tr -d '\r' | tr '\n' ' ' | tr -s ' ' | sed 's/^ //;s/ $//' | tr '|' '-' | cut -c1-100)

            if [ $SQL_EXIT_CODE -eq 0 ] && [[ ! "$SQL_OUTPUT" =~ "ORA-" ]]; then
                echo "[OK] Integration test successful."
                echo "Result: $CLEAN_RESULT"
                log_result "Integration Test" "✅ OK" "SQL executed successfully: \`$CLEAN_SQL\`"
            else
                echo "[FAIL] Failed to execute generated SQL."
                echo "Error: $SQL_OUTPUT"
                # Extract ORA error, sanitize pipes
                ORA_ERR=$(echo "$SQL_OUTPUT" | grep -o "ORA-[0-9]\+.*" | head -n 1 | cut -c1-100 | tr '|' '-')
                [ -z "$ORA_ERR" ] && ORA_ERR="SQL Execution Error"
                log_result "Integration Test" "❌ FAIL" "SQL error ($ORA_ERR) for \`$CLEAN_SQL\`"
            fi
        else
            echo "[FAIL] Could not extract SQL from LLM response. Response was: $INTEGRATION_RESPONSE"
            SAFE_RESPONSE=$(echo "$INTEGRATION_RESPONSE" | tr '|' '-' | tr '\n' ' ' | cut -c1-50)
            log_result "Integration Test" "❌ FAIL" "No SQL extracted from: $SAFE_RESPONSE"
        fi
    else
        echo "[FAIL] LLM did not respond for integration test."
        log_result "Integration Test" "❌ FAIL" "LLM did not respond"
    fi
else
    echo "[SKIP] SQLcl or DB_CONN_STR missing. Skipping integration test."
    log_result "Integration Test" "⏭️ SKIP" "SQLcl or DB_CONN_STR missing"
fi

# 6. Integration: LLM queries SCOTT schema
if command -v sql &> /dev/null && [ -n "$DB_CONN_STR" ]; then
    echo "Integration Test: LLM querying SCOTT.EMP table..."

    PROMPT="Generate an Oracle SQL SELECT statement to find the name (ENAME) and salary (SAL) of all employees in department 10 from the SCOTT.EMP table. Return ONLY the SQL, no explanation."

    SCOTT_RESPONSE=$(curl -s -X POST "$OLLAMA_URL/api/generate" -d "$(jq -n --arg model "$LLM_MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false}')" | jq -r '.response' 2>/dev/null)

    if [ -n "$SCOTT_RESPONSE" ] && [ "$SCOTT_RESPONSE" != "null" ]; then
        # Extraction: use python helper for more robust SQL extraction
        CLEAN_SQL=$(echo "$SCOTT_RESPONSE" | python3 install/extract_sql.py)

        if [ -n "$CLEAN_SQL" ]; then
            echo "Executing LLM generated SQL on SCOTT schema: $CLEAN_SQL"
            # Ensure SQL ends with semicolon
            [[ "$CLEAN_SQL" != *";" ]] && EXEC_SQL="$CLEAN_SQL;" || EXEC_SQL="$CLEAN_SQL"
            # Capture output and exit code
            SQL_OUTPUT=$(echo "$EXEC_SQL" | sql -L -s "$DB_CONN_STR" 2>&1)
            SQL_EXIT_CODE=$?
            # Sanitize result for markdown table
            CLEAN_RESULT=$(echo "$SQL_OUTPUT" | grep -v "connected" | grep -v "USER          =" | grep -v "URL           =" | grep -v "Error Message =" | tr -d '\r' | tr '\n' ' ' | tr -s ' ' | sed 's/^ //;s/ $//' | tr '|' '-' | cut -c1-100)

            if [ $SQL_EXIT_CODE -eq 0 ] && [[ ! "$SQL_OUTPUT" =~ "ORA-" ]]; then
                echo "[OK] SCOTT integration test successful."
                echo "Result: $CLEAN_RESULT"
                log_result "SCOTT Integration" "✅ OK" "SQL executed successfully on SCOTT.EMP: \`$CLEAN_SQL\`"
            else
                echo "[FAIL] Failed to execute generated SQL on SCOTT schema."
                echo "Error: $SQL_OUTPUT"
                # Extract ORA error, sanitize pipes
                ORA_ERR=$(echo "$SQL_OUTPUT" | grep -o "ORA-[0-9]\+.*" | head -n 1 | cut -c1-100 | tr '|' '-')
                [ -z "$ORA_ERR" ] && ORA_ERR="SQL Execution Error"
                log_result "SCOTT Integration" "❌ FAIL" "SQL error ($ORA_ERR) for \`$CLEAN_SQL\`"
            fi
        else
            echo "[FAIL] Could not extract SQL from LLM response. Response was: $SCOTT_RESPONSE"
            SAFE_RESPONSE=$(echo "$SCOTT_RESPONSE" | tr '|' '-' | tr '\n' ' ' | cut -c1-50)
            log_result "SCOTT Integration" "❌ FAIL" "No SQL extracted from: $SAFE_RESPONSE"
        fi
    else
        echo "[FAIL] LLM did not respond for SCOTT integration test."
        log_result "SCOTT Integration" "❌ FAIL" "LLM did not respond"
    fi
else
    echo "[SKIP] SQLcl or DB_CONN_STR missing. Skipping SCOTT integration test."
    log_result "SCOTT Integration" "⏭️ SKIP" "SQLcl or DB_CONN_STR missing"
fi

echo "" >> "$REPORT_FILE"
echo "=== Test Run Complete ==="
