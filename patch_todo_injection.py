path = "agent/agent_loop.py"
with open(path) as f:
    src = f.read()

anchor = '''            MAX_RECENT_MESSAGES = 6
            trimmed = messages[:2] + messages[2:][-MAX_RECENT_MESSAGES:]'''

assert src.count(anchor) == 1, "anchor not found/not unique - aborting"

replacement = '''            MAX_RECENT_MESSAGES = 6
            trimmed = messages[:2] + messages[2:][-MAX_RECENT_MESSAGES:]

            # Auto-inject current todo state every turn, independent of
            # whether the model remembers to call read_todos. Root cause
            # of the multi-item task looping bug: history trimming drops
            # earlier progress out of context, and todos were pure on-disk
            # storage with no auto-recall - the model would re-check items
            # it already finished because it could no longer see that it
            # had. This makes progress durable across trimming regardless
            # of task length, instead of just raising the trim window and
            # delaying the same problem at a bigger N.
            try:
                todo_path = os.path.expanduser("~/.omega/logs/agent_todos.json")
                if os.path.exists(todo_path):
                    with open(todo_path) as tf:
                        todo_state = json.load(tf)
                    todos = todo_state.get("todos", [])
                    if todos:
                        todo_reminder = (
                            "[CURRENT TODO STATE - auto-injected, reflects your "
                            "last write_todos call. Do not re-do items already "
                            "reflected as complete here; check this before "
                            "repeating any prior tool call.]\\n"
                            + "\\n".join(f"- {t}" for t in todos)
                        )
                        trimmed = trimmed + [{"role": "system", "content": todo_reminder}]
            except Exception:
                pass  # todo injection is a convenience, never block the main loop on it'''

src = src.replace(anchor, replacement, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
