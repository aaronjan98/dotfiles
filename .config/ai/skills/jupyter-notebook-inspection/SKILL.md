# Jupyter Notebook Inspection

## Purpose
Inspect a Jupyter notebook workspace to find notebooks, code, outputs, and explanations relevant to the current task.

## Use this when
- A project contains Jupyter notebooks
- Relevant information may be spread across subdirectories
- The task involves coursework, experiments, computations, or notebook-based analysis

## Inputs
- notebook root directory
- current question or topic
- optional lab, assignment, or filename hints

## Search behavior
- Search recursively through subdirectories
- Use directory names, notebook names, and notebook contents to locate relevant material
- Distinguish between assignment notebooks and supporting lab notebooks when possible
- Start broad, then narrow to the most relevant notebooks

## Output
Return:
1. the notebook paths most relevant to the task
2. what each relevant notebook appears to contain
3. key cells, concepts, computations, or outputs worth reviewing
4. any uncertainty when notebook purpose is not obvious

## Rules
- Do not assume notebook purpose from filename alone if content can be inspected
- Prefer giving a ranked shortlist instead of dumping every notebook
- Note when the directory would benefit from a local CONTEXT.md
