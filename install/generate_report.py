import sys
import html
import os
import glob
import re
from datetime import datetime, timezone

def parse_report_for_matrix(filename):
    # Extract model name from filename like complexity-report-llama3.md or test-report-llama3.md
    model_match = re.search(r'report-(.+)\.md', filename)
    if not model_match:
        return None, {}
    model_name = model_match.group(1)

    tasks = {}
    with open(filename, 'r') as f:
        for line in f:
            if '|' in line and '---' not in line:
                parts = [p.strip() for p in line.split('|')]
                # Filter out header rows
                if not parts or len(parts) < 3: continue
                if parts[1].lower() in ['level', 'test case', 'task']: continue

                if 'complexity-report' in filename:
                    # | Level | Task | Status | SQL | Result |
                    if len(parts) >= 4:
                        task = parts[2]
                        status = parts[3]
                        tasks[task] = status
                else:
                    # | Test Case | Status | Details |
                    if len(parts) >= 3:
                        task = parts[1]
                        status = parts[2]
                        tasks[task] = status
    return model_name, tasks

def generate_matrix_html():
    complexity_files = glob.glob("complexity-report-*.md")
    test_files = glob.glob("test-report-*.md")

    all_models = set()
    all_tasks = []
    matrix = {} # (task, model) -> status

    # Process files to build the matrix
    for f in sorted(complexity_files) + sorted(test_files):
        model, tasks = parse_report_for_matrix(f)
        if not model: continue
        all_models.add(model)
        for task, status in tasks.items():
            if task not in all_tasks:
                all_tasks.append(task)
            matrix[(task, model)] = status

    if not all_tasks:
        return ""

    models = sorted(list(all_models))

    html_out = "<h2>Model Comparison Matrix</h2>"
    html_out += "<table><thead><tr><th>Task</th>"
    for m in models:
        html_out += f"<th>{m}</th>"
    html_out += "</tr></thead><tbody>"

    for t in all_tasks:
        html_out += f"<tr><td>{html.escape(t)}</td>"
        for m in models:
            status = matrix.get((t, m), "-")
            icon = status
            if "OK" in status or "✅" in status:
                icon = "✅"
            elif "FAIL" in status or "❌" in status:
                icon = "❌"
            elif "SKIP" in status or "⏭️" in status:
                icon = "⏭️"

            html_out += f"<td style='text-align:center'>{icon}</td>"
        html_out += "</tr>"

    html_out += "</tbody></table>"
    return html_out

def md_to_html(md_text):
    lines = md_text.splitlines()
    html_output = []
    in_table = False

    for line in lines:
        line = line.strip()
        if not line:
            if in_table:
                html_output.append("</table>")
                in_table = False
            continue

        if line.startswith("# "):
            if in_table: html_output.append("</table>"); in_table = False
            html_output.append(f"<h1>{html.escape(line[2:])}</h1>")
        elif line.startswith("## "):
            if in_table: html_output.append("</table>"); in_table = False
            html_output.append(f"<h2>{html.escape(line[3:])}</h2>")
        elif "|" in line:
            if "---" in line:
                continue
            cells = [c.strip() for c in line.split("|")]
            # Handle leading/trailing pipes
            if not cells[0]: cells = cells[1:]
            if not cells[-1]: cells = cells[:-1]

            if not cells: continue

            if not in_table:
                html_output.append("<table><thead>")
                in_table = True
                html_output.append("<tr>" + "".join(f"<th>{html.escape(c)}</th>" for c in cells) + "</tr>")
                html_output.append("</thead><tbody>")
            else:
                html_output.append("<tr>" + "".join(f"<td>{html.escape(c)}</td>" for c in cells) + "</tr>")
        else:
            if in_table:
                html_output.append("</tbody></table>")
                in_table = False
            html_output.append(f"<p>{html.escape(line)}</p>")

    if in_table:
        html_output.append("</tbody></table>")

    return "\n".join(html_output)

if __name__ == "__main__":
    matrix_html = generate_matrix_html()
    timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')

    report_html = ""
    # Find all model-specific reports first
    report_files = glob.glob("*-report-*.md")
    # If none found, fall back to default names (for local testing)
    if not report_files:
        report_files = [f for f in ["test-report.md", "complexity-report.md"] if os.path.exists(f)]

    # Sort files to ensure consistent order
    report_files.sort()

    for filename in report_files:
        with open(filename, "r") as f:
            report_html += md_to_html(f.read())
            report_html += "<hr>"

    print(f"""
<!DOCTYPE html>
<html><head><title>LLM Oracle SQLcl Test Results</title>
<meta charset="UTF-8">
<style>
body{{font-family:sans-serif;margin:2em;line-height:1.6;color:#333;max-width:1200px;margin:auto;}}
table{{border-collapse:collapse;width:100%;margin-bottom:2em;}}
th,td{{border:1px solid #ddd;padding:12px;text-align:left;}}
th{{background-color:#f8f9fa;position: sticky; top: 0;}}
tr:nth-child(even){{background-color:#f2f2f2;}}
tr:hover {{background-color: #e9ecef;}}
h1,h2{{color:#0056b3;border-bottom: 2px solid #0056b3; padding-bottom: 0.3em;}}
hr{{margin:3em 0; border: 0; border-top: 5px solid #eee;}}
.matrix-container {{ overflow-x: auto; }}
</style></head><body>
<h1>LLM x Oracle SQLcl Integration Test Results</h1>
<p style="font-style: italic;">Last updated: {timestamp}</p>
<div class="matrix-container">
{matrix_html}
</div>
<hr>
{report_html}
</body></html>
""")
