#!/bin/bash
# install/sqlcl.sh - Setup script for Oracle SQLcl

echo "Starting SQLcl setup..."

# Check if sqlcl is already in path
if command -v sql &> /dev/null; then
    echo "SQLcl (sql) is already installed."
else
    echo "SQLcl not found in PATH."
    echo "Please download SQLcl from https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/"
    echo "After downloading and extracting, add the 'bin' directory to your PATH."
    echo ""
    echo "Example for Linux/macOS:"
    echo "export PATH=\$PATH:/path/to/sqlcl/bin"
fi

# Basic check for Java, which is required by SQLcl
if command -v java &> /dev/null; then
    echo "Java is installed: $(java -version 2>&1 | head -n 1)"
else
    echo "Warning: Java is not found. SQLcl requires Java to run."
fi

echo "SQLcl setup script finished."
