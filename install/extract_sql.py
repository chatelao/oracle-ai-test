import sys
import re

def extract_sql(text):
    # 1. Check for markdown blocks
    code_blocks = re.findall(r'```(?:sql)?\s*(.*?)\s*```', text, re.DOTALL | re.IGNORECASE)
    if code_blocks:
        for block in code_blocks:
            if re.search(r'SELECT', block, re.IGNORECASE):
                return block.strip().rstrip(';')

    # 2. Look for the first SELECT and try to find a natural end
    # We want everything from SELECT to the first ; or the end of the text
    # But we need to handle potential surrounding text.

    # Try to find a SELECT that ends with a semicolon
    match_semi = re.search(r'((?:SELECT|select).*?);', text, re.DOTALL)
    if match_semi:
        return match_semi.group(1).strip()

    # Try to find a SELECT that is at the end of the string or followed by some common non-SQL patterns
    match_plain = re.search(r'((?:SELECT|select).*)', text, re.DOTALL)
    if match_plain:
        sql = match_plain.group(1).strip()
        # Remove trailing junk if LLM added some
        sql = re.split(r'\n\n|\r\n\r\n', sql)[0] # Split by double newline
        return sql.strip().rstrip(';')

    return None

if __name__ == "__main__":
    content = sys.stdin.read()
    result = extract_sql(content)
    if result:
        sys.stdout.write(result)
