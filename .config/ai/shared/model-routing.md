# Model Routing

This file defines the default routing policy for choosing between local and cloud models.

## Core rule
Use the most reliable model/backend that fits the task.

At this time, cloud Claude is the normal working backend.

Local backends are considered experimental and are kept available only for future use or limited testing.

## Default policy
- Prefer cloud models by default
- Do not route to local models automatically in normal workflow
- Only use local models when explicitly requested by the user

## Why cloud is the default
In this system, local backends are currently not reliable enough for normal agentic work.

They may be slower than expected or perform poorly in:
- interactive sessions
- tool-using workflows
- filesystem-aware agent tasks
- long-context reasoning

Because of this, local backends should not be selected automatically.

## Local backends
Local models remain wired up for:
- future experimentation
- backend testing
- narrow one-off analysis if explicitly requested

But they are not part of the normal default workflow.

## Cloud backends
Prefer cloud models when:
- doing normal interactive work
- reasoning across files or repos
- performing edits
- following project control files
- working in longer sessions
- reliability matters

## Script-first rule
For bulk filesystem operations such as:
- rename
- move
- delete
- bulk rewrite
- repetitive transformations

do not directly mutate files first.

Instead:
1. analyze the rule
2. generate a deterministic script
3. support dry-run mode
4. review expected changes
5. only execute after confirmation

## Manual override
The user may explicitly force:
- local
- cloud

Explicit user override beats default routing.
