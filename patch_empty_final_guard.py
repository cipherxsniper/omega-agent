path = "agent/agent_loop.py"
with open(path) as f:
    src = f.read()

anchor = '''            if not tool_calls:
                final_content = message.get("content", "")
                narrative_text = final_content  # pristine copy, before any system-appended blocks'''

assert src.count(anchor) == 1, "anchor not found/not unique - aborting"

replacement = '''            if not tool_calls:
                final_content = message.get("content", "")

                # Guard against silent empty-stop: the model can emit no
                # tool_calls AND no content, which previously passed through
                # as a valid "done" with a blank response - no explanation,
                # no failure report, nothing. Force one more turn instead of
                # accepting silence as completion, up to a small retry cap
                # so a persistently-empty model doesn't spin forever.
                if not final_content.strip() and step < max_steps - 1:
                    messages.append({
                        "role": "user",
                        "content": (
                            "Your last response was empty. If the task is complete, "
                            "say so explicitly and summarize what was done. If it is "
                            "not complete, continue with the next tool call."
                        ),
                    })
                    continue

                narrative_text = final_content  # pristine copy, before any system-appended blocks'''

src = src.replace(anchor, replacement, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
