path = "agent/core/action_engine.py"
with open(path) as f:
    src = f.read()

anchor = 'if name in ("read_file", "write_file", "list_dir") and target:'
assert src.count(anchor) == 1, "anchor not found/not unique - aborting"

replacement = (
    'if name in ("read_file", "write_file", "list_dir", "git_status", '
    '"git_diff", "git_commit", "git_log") and target:'
)

src = src.replace(anchor, replacement, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
