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

# 1. Check Ollama
echo "Checking Ollama..."
if curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
    echo "[OK] Ollama is reachable."
    log_result "Check Ollama" "✅ OK" "Ollama is reachable"
else
    echo "[FAIL] Ollama is not reachable on 127.0.0.1:11434."
    log_result "Check Ollama" "❌ FAIL" "Ollama is not reachable on 127.0.0.1:11434"
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
RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/generate -d "{
  \"model\": \"$LLM_MODEL\",
  \"prompt\": \"Say hello world in SQL\",
  \"stream\": false
}" | jq -r '.response' 2>/dev/null)

if [ -n "$RESPONSE" ]; then
    echo "[OK] LLM responded."
    echo "LLM Response: $RESPONSE"
    log_result "LLM Connectivity" "✅ OK" "LLM ($LLM_MODEL) responded"
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
        if [ $DB_EXIT_CODE -eq 0 ] && [ -n "$DB_VERSION" ]; then
            echo "[OK] Database connection successful. Version: $DB_VERSION"
            log_result "DB Connectivity" "✅ OK" "Database version: $DB_VERSION"
        else
            echo "[FAIL] Could not connect to database or retrieve version."
            echo "Error Details: $DB_OUTPUT"
            # Extract ORA error if present
            ORA_ERR=$(echo "$DB_OUTPUT" | grep -o "ORA-[0-9]\+" | head -n 1)
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

    INTEGRATION_RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/generate -d "{
      \"model\": \"$LLM_MODEL\",
      \"prompt\": \"$PROMPT\",
      \"stream\": false
    }" | jq -r '.response' 2>/dev/null)

    if [ -n "$INTEGRATION_RESPONSE" ]; then
        # Extraction: remove markdown backticks and isolate the SELECT statement
        CLEAN_SQL=$(echo "$INTEGRATION_RESPONSE" | tr -d '`' | tr '\n' ' ' | sed -n 's/.*\(SELECT[^;]*\).*/\1/p' | head -n 1)

        if [ -n "$CLEAN_SQL" ]; then
            echo "Executing LLM generated SQL: $CLEAN_SQL"
            # Capture output and exit code
            SQL_OUTPUT=$(echo "$CLEAN_SQL" | sql -L -s "$DB_CONN_STR" 2>&1)
            SQL_EXIT_CODE=$?
            CLEAN_RESULT=$(echo "$SQL_OUTPUT" | grep -v "connected" | grep -v "USER          =" | grep -v "URL           =" | grep -v "Error Message =" | xargs)

            if [ $SQL_EXIT_CODE -eq 0 ] && [[ ! "$SQL_OUTPUT" =~ "ORA-" ]]; then
                echo "[OK] Integration test successful."
                echo "Result: $CLEAN_RESULT"
                log_result "Integration Test" "✅ OK" "SQL executed successfully"
            else
                echo "[FAIL] Failed to execute generated SQL."
                echo "Error: $SQL_OUTPUT"
                log_result "Integration Test" "❌ FAIL" "Failed to execute generated SQL"
            fi
        else
            echo "[FAIL] Could not extract SQL from LLM response. Response was: $INTEGRATION_RESPONSE"
            log_result "Integration Test" "❌ FAIL" "Could not extract SQL from LLM response"
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

    SCOTT_RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/generate -d "{
      \"model\": \"$LLM_MODEL\",
      \"prompt\": \"$PROMPT\",
      \"stream\": false
    }" | jq -r '.response' 2>/dev/null)

    if [ -n "$SCOTT_RESPONSE" ]; then
        # Extraction: remove markdown backticks and isolate the SELECT statement
        CLEAN_SQL=$(echo "$SCOTT_RESPONSE" | tr -d '`' | tr '\n' ' ' | sed -n 's/.*\(SELECT[^;]*\).*/\1/p' | head -n 1)

        if [ -n "$CLEAN_SQL" ]; then
            echo "Executing LLM generated SQL on SCOTT schema: $CLEAN_SQL"
            # Capture output and exit code
            SQL_OUTPUT=$(echo "$CLEAN_SQL" | sql -L -s "$DB_CONN_STR" 2>&1)
            SQL_EXIT_CODE=$?
            CLEAN_RESULT=$(echo "$SQL_OUTPUT" | grep -v "connected" | grep -v "USER          =" | grep -v "URL           =" | grep -v "Error Message =" | xargs)

            if [ $SQL_EXIT_CODE -eq 0 ] && [[ ! "$SQL_OUTPUT" =~ "ORA-" ]]; then
                echo "[OK] SCOTT integration test successful."
                echo "Result: $CLEAN_RESULT"
                log_result "SCOTT Integration" "✅ OK" "SQL executed successfully on SCOTT.EMP"
            else
                echo "[FAIL] Failed to execute generated SQL on SCOTT schema."
                echo "Error: $SQL_OUTPUT"
                log_result "SCOTT Integration" "❌ FAIL" "Failed to execute generated SQL on SCOTT.EMP"
            fi
        else
            echo "[FAIL] Could not extract SQL from LLM response. Response was: $SCOTT_RESPONSE"
            log_result "SCOTT Integration" "❌ FAIL" "Could not extract SQL from LLM response"
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
