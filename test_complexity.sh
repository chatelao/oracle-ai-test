#!/bin/bash
# test_complexity.sh - 10 Queries of increasing complexity for SCOTT/TIGER

REPORT_FILE="complexity-report.md"
LLM_MODEL=${LLM_MODEL:-llama3}
[ -f "install/db_config.sh" ] && source install/db_config.sh

echo "=== SCOTT/TIGER Complexity Test ==="

# 1. Check SQLcl
if command -v sql &> /dev/null; then
    if ! sql -version 2>&1 | grep -q "SQLcl"; then
        echo "Error: 'sql' command found but it is NOT Oracle SQLcl."
        exit 1
    fi
else
    echo "Error: SQLcl (sql) not found in PATH."
    exit 1
fi

# 2. Check Database Connectivity
echo "Checking Database connectivity..."
if ! echo "SELECT 1 FROM DUAL;" | sql -L -s "$DB_CONN_STR" &> /dev/null; then
    echo "Error: Could not connect to database. Aborting tests."
    # We write a report with a failure message if DB is down
    echo "# Complexity Test Report - $(date)" > "$REPORT_FILE"
    echo "## Database Connectivity Error" >> "$REPORT_FILE"
    echo "The tests could not be executed because the database is unreachable." >> "$REPORT_FILE"
    exit 1
fi

echo "# Complexity Test Report - $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Level | Task | Status | SQL | Result |" >> "$REPORT_FILE"
echo "|-------|------|--------|-----|--------|" >> "$REPORT_FILE"

declare -a PROMPTS=(
    "List all employees from SCOTT.EMP table."
    "List employees from SCOTT.EMP with a salary (SAL) greater than 2000."
    "List employee names (ENAME) and their department names (DNAME) by joining SCOTT.EMP and SCOTT.DEPT on DEPTNO."
    "Count the number of employees in each department. Show DEPTNO and the count from SCOTT.EMP."
    "Find the average salary (SAL) for each job (JOB) in the SCOTT.EMP table."
    "Find the name (ENAME) of the highest paid employee in each department (DEPTNO) from SCOTT.EMP."
    "List employees (ENAME) who earn more than their managers. Join SCOTT.EMP with itself on MGR = EMPNO."
    "Find departments (DNAME) from SCOTT.DEPT that have no employees in SCOTT.EMP."
    "List the top 3 highest earning employees (ENAME, SAL) from the SCOTT.EMP table."
    "For each department, show the employee name (ENAME), hire date (HIREDATE), and a running total of salaries (SAL) (cumulative sum) ordered by hire date."
)

run_test() {
    local level=$1
    local task=$2
    echo "Running Level $level: $task"

    PROMPT="Task: $task.
    Context: Oracle Database, SCOTT schema. Use SCOTT.EMP and SCOTT.DEPT tables.
    Requirement: Return ONLY the Oracle SQL SELECT statement. No explanation. No markdown backticks. No trailing characters."

    RESPONSE=$(curl -s -X POST http://127.0.0.1:11434/api/generate -d "$(jq -n --arg model "$LLM_MODEL" --arg prompt "$PROMPT" '{model: $model, prompt: $prompt, stream: false}')" | jq -r '.response' 2>/dev/null)

    if [ -z "$RESPONSE" ]; then
        echo "| $level | $task | ❌ FAIL | No response | |" >> "$REPORT_FILE"
        return
    fi

    # Extraction - use python helper for more robust SQL extraction
    CLEAN_SQL=$(echo "$RESPONSE" | python3 install/extract_sql.py)

    if [ -z "$CLEAN_SQL" ]; then
        echo "| $level | $task | ❌ FAIL | Could not extract SQL | $RESPONSE |" >> "$REPORT_FILE"
        return
    fi

    # Normalize SQL for report (remove newlines and extra spaces)
    REPORT_SQL=$(echo "$CLEAN_SQL" | tr '\n' ' ' | tr -s ' ')

    echo "Executing: $CLEAN_SQL"
    # Ensure SQL ends with semicolon if not present
    [[ "$CLEAN_SQL" != *";" ]] && CLEAN_SQL="$CLEAN_SQL;"

    SQL_OUTPUT=$(echo "$CLEAN_SQL" | sql -L -s "$DB_CONN_STR" 2>&1)
    SQL_EXIT_CODE=$?

    # Remove connection info and extra whitespace
    CLEAN_RESULT=$(echo "$SQL_OUTPUT" | grep -v "connected" | grep -v "USER          =" | grep -v "URL           =" | grep -v "Error Message =" | tr -d '\r' | tr '\n' ' ' | tr -s ' ' | sed 's/^ //;s/ $//' | cut -c1-100)

    if [ $SQL_EXIT_CODE -eq 0 ] && [[ ! "$SQL_OUTPUT" =~ "ORA-" ]]; then
        echo "| $level | $task | ✅ OK | \`$REPORT_SQL\` | $CLEAN_RESULT |" >> "$REPORT_FILE"
    else
        # Extract ORA error and some context
        ORA_ERR=$(echo "$SQL_OUTPUT" | grep -o "ORA-[0-9]\+.*" | head -n 1 | cut -c1-100)
        [ -z "$ORA_ERR" ] && ORA_ERR="Unknown Error"
        echo "| $level | $task | ❌ FAIL | \`$REPORT_SQL\` | Error: $ORA_ERR |" >> "$REPORT_FILE"
    fi
}

for i in "${!PROMPTS[@]}"; do
    run_test $((i+1)) "${PROMPTS[$i]}"
done

echo "=== Complexity Test Complete ==="
