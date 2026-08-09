path = "agent/agent_loop.py"
with open(path) as f:
    src = f.read()

anchor = '''def run_agent_task(task_description, max_steps=10, signed_log=None, cwd_hint=None, resume=False):'''
assert src.count(anchor) == 1, "anchor1 not found/not unique - aborting"

src = src.replace(
    anchor,
    '''def run_agent_task(task_description, max_steps=10, signed_log=None, cwd_hint=None, resume=False, require_plan=False):''',
    1,
)

anchor2 = '''    system = SYSTEM_PROMPT
    if cwd_hint:
        system += f" The current working directory is {cwd_hint}."'''
assert src.count(anchor2) == 1, "anchor2 not found/not unique - aborting"

replacement2 = '''    system = SYSTEM_PROMPT
    if cwd_hint:
        system += f" The current working directory is {cwd_hint}."
    if require_plan:
        # Mandatory planning mode, for long/complex autonomous tasks (used
        # by the background job endpoint). Claude-Code-style: plan before
        # acting, keep the plan current, verify against it before declaring
        # done - rather than improvising step by step with no durable plan.
        system += (
            " This is a long-running autonomous task. Before taking any "
            "other action, call write_todos with a full breakdown of every "
            "step needed to complete this task. As you complete each step, "
            "call write_todos again to update status. Before your final "
            "response, call read_todos and confirm every item is actually "
            "done - do not declare the task complete if any item is not "
            "reflected as done in the todo state."
        )'''

src = src.replace(anchor2, replacement2, 1)

with open(path, "w") as f:
    f.write(src)

print("patched", path)
