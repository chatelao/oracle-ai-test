import sys
import html
import os

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
    report_html = ""
    for filename in ["test-report.md", "complexity-report.md"]:
        if os.path.exists(filename):
            with open(filename, "r") as f:
                report_html += md_to_html(f.read())
                report_html += "<hr>"

    print(f"""
<html><head><title>Test Results</title><style>
body{{font-family:sans-serif;margin:2em;line-height:1.6;color:#333;max-width:1200px;margin:auto;}}
table{{border-collapse:collapse;width:100%;margin-bottom:2em;}}
th,td{{border:1px solid #ddd;padding:12px;text-align:left;}}
th{{background-color:#f8f9fa;}}
tr:nth-child(even){{background-color:#f2f2f2;}}
h1,h2{{color:#0056b3;}}
hr{{margin:2em 0;}}
</style></head><body>
<h1>LLM x Oracle SQLcl Integration Test Results</h1>
{report_html}
</body></html>
""")
