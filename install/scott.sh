#!/bin/bash
# install/scott.sh - Install SCOTT schema

SCRIPT_DIR=$(dirname "$0")

# Check if db_config.sh exists
if [ -f "$SCRIPT_DIR/db_config.sh" ]; then
    source "$SCRIPT_DIR/db_config.sh"
else
    echo "Error: $SCRIPT_DIR/db_config.sh not found."
    exit 1
fi

echo "Installing SCOTT schema using $DB_CONN_STR..."

# Check if sqlcl is in PATH
if command -v sql &> /dev/null; then
    sql -L -s "$DB_CONN_STR" @"$SCRIPT_DIR/scott.sql"
    if [ $? -eq 0 ]; then
        echo "SCOTT schema installed successfully."
    else
        echo "Error: Failed to install SCOTT schema."
        exit 1
    fi
else
    echo "Error: SQLcl (sql) not found in PATH. Please run install/sqlcl.sh first and ensure 'sql' is in your PATH."
    exit 1
fi
