#!/bin/bash
# install/sqlcl.sh - Setup script for Oracle SQLcl

echo "Starting SQLcl setup..."

# Basic check for Java, which is required by SQLcl
if command -v java &> /dev/null; then
    echo "Java is installed: $(java -version 2>&1 | head -n 1)"
else
    echo "Error: Java is not found. SQLcl requires Java to run."
    # In CI we might want to install it, but usually the runner has it or we install it in the workflow
fi

# Check if sqlcl is already in path
if command -v sql &> /dev/null; then
    echo "SQLcl (sql) is already installed."
else
    echo "SQLcl not found in PATH. Attempting to install..."

    SQLCL_DIR="$HOME/sqlcl"
    if [ ! -d "$SQLCL_DIR" ]; then
        mkdir -p "$SQLCL_DIR"
        echo "Downloading SQLcl..."
        curl -L https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip -o sqlcl-latest.zip
        echo "Unzipping SQLcl..."
        unzip -q sqlcl-latest.zip -d "$SQLCL_DIR"
        rm sqlcl-latest.zip
    fi

    # Find the bin directory
    SQLCL_BIN=$(find "$SQLCL_DIR" -name "sql" -type f | grep "/bin/sql" | head -n 1)
    if [ -n "$SQLCL_BIN" ]; then
        SQLCL_BIN_DIR=$(dirname "$SQLCL_BIN")
        echo "SQLcl installed to $SQLCL_BIN_DIR"
        echo "Add this to your PATH: export PATH=\$PATH:$SQLCL_BIN_DIR"

        # If in GitHub Actions, add to GITHUB_PATH
        if [ -n "$GITHUB_PATH" ]; then
            echo "$SQLCL_BIN_DIR" >> "$GITHUB_PATH"
            echo "Added $SQLCL_BIN_DIR to GITHUB_PATH"
        fi
    else
        echo "Error: Could not find sql binary after installation."
        exit 1
    fi
fi

echo "SQLcl setup script finished."

# Output version
if command -v sql &> /dev/null; then
    sql -v
elif [ -n "$SQLCL_BIN" ]; then
    "$SQLCL_BIN" -v
fi
