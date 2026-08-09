path = "agent/agent_loop.py"
with open(path) as f:
    src = f.read()

anchor = '''    try:
        args = json.loads(tool_call["function"]["arguments"])
    except json.JSONDecodeError as e:
        return {"error": f"Model sent malformed tool arguments: {e}"}'''

assert src.count(anchor) == 1, "anchor not found/not unique - aborting"

replacement = '''    try:
        args = json.loads(tool_call["function"]["arguments"])
    except json.JSONDecodeError as e:
        return {"error": f"Model sent malformed tool arguments: {e}"}

    # json.loads("null") succeeds and returns None without raising -
    # args.get(...) below then crashes with AttributeError, not caught
    # by the except above. Guard explicitly: null/non-dict arguments are
    # malformed input, same as unparseable JSON, and should fail the same
    # clean way instead of taking down the whole request.
    if not isinstance(args, dict):
        return {"error": f"Model sent non-dict tool arguments: {args!r}"}'''

src = src.replace(anchor, replacement, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
