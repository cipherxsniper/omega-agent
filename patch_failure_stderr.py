path = "agent/agent_loop.py"
with open(path) as f:
    src = f.read()

anchor = '''                    if is_failure:
                        err = (
                            output.get("error")
                            if isinstance(output, dict) and output.get("error")
                            else result.get("reason", "unspecified failure")
                        )'''

assert src.count(anchor) == 1, "anchor not found/not unique - aborting"

replacement = '''                    if is_failure:
                        # run_bash failures put the real message in
                        # output["stderr"], not output["error"] - this was
                        # falling through to a generic "unspecified failure"
                        # even when a specific, useful error was available,
                        # which starves the model of the detail it needs to
                        # explain what actually happened instead of guessing.
                        err = (
                            output.get("error")
                            if isinstance(output, dict) and output.get("error")
                            else output.get("stderr").strip()
                            if isinstance(output, dict) and output.get("stderr", "").strip()
                            else result.get("reason", "unspecified failure")
                        )'''

src = src.replace(anchor, replacement, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
