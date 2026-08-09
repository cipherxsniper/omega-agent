path = "agent/agent_loop.py"
with open(path) as f:
    src = f.read()

anchor = '''                        trimmed = trimmed + [{"role": "system", "content": todo_reminder}]
            except Exception:
                pass  # todo injection is a convenience, never block the main loop on it'''

assert src.count(anchor) == 1, "anchor not found/not unique - aborting"

replacement = anchor + '''

            # Same problem, different shape: the model was re-running
            # glob_find/grep_search/read_file for files it had already
            # located and read earlier in the session, once those steps
            # fell out of the trimmed window - burning steps on repeat
            # searches (observed: ~35 of 59 steps in one run re-searching
            # for the same already-found file). Scan the FULL transcript
            # (not the trimmed slice) for successful file discoveries and
            # remind the model what's already known, every turn.
            try:
                known_files = set()
                for entry in transcript:
                    if entry.get("role") != "tool":
                        continue
                    result = entry.get("result", {})
                    output = result.get("output", {}) if isinstance(result, dict) else {}
                    if not isinstance(output, dict):
                        continue
                    if result.get("success") is True and output.get("path"):
                        known_files.add(output["path"])
                    for m in output.get("matches", []):
                        known_files.add(m)

                if known_files:
                    files_reminder = (
                        "[FILES ALREADY LOCATED/READ THIS SESSION - do not "
                        "re-run glob_find/grep_search/read_file for these, "
                        "use what you already know instead]\\n"
                        + "\\n".join(f"- {f}" for f in sorted(known_files))
                    )
                    trimmed = trimmed + [{"role": "system", "content": files_reminder}]
            except Exception:
                pass  # convenience only, never block the main loop on it'''

src = src.replace(anchor, replacement, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
