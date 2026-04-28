#!/bin/bash
# install/db_config.sh - Template for Oracle DB connection configuration

echo "Configuring Database Connection Environment Variables..."

# IMPORTANT: Edit these values to match your environment
export DB_USER="system"
export DB_PASS="password"
export DB_HOST="127.0.0.1"
export DB_PORT="1521"
export DB_SERVICE="FREEPDB1"

# Connection string format: user/pass@host:port/service
export DB_CONN_STR="${DB_USER}/${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_SERVICE}"

echo "Database configuration template loaded."
echo "Connection string: ${DB_CONN_STR}"
