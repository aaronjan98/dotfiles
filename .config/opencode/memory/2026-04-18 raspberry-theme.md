# OpenCode Theme Session - April 18, 2026

## What was worked on
Customizing the OpenCode theme to match Ghostty terminal colors (Ferrari Red cursor, dark raspberry background).

## Key Insights

### Cursor Color Limitation
- No dedicated cursor color key exists in theme files
- `cursor_color` config exists but is not yet deployed in schema
- Main textbox cursor uses `text` color - changing it affects ALL text
- Popups use `primary` color (can be changed independently)

### Transparency Works Differently
- `"none"` makes backgrounds transparent but causes text overlap issues
- 8-digit hex (#RRGGBBAA) with alpha NOT supported
- `system` theme is the ONLY way to get true terminal-matched transparency
- Cannot be replicated in custom themes

### Raspberry Theme Created
- Primary: Ferrari Red `#FF2800` (popup accents)
- background: transparent (`"none"`)
- backgroundPanel/Element: raspberry `#2a1520`
- All orange replaced with Ferrari Red

## Decisions
- Keep solid colors for panel backgrounds (transparency caused overlap issues)
- Main window stays transparent
- Wait for `cursor_color` config to be deployed for permanent cursor fix

## Open Questions
- Will cursor_color ever work? Need to check schema updates periodically

## Next Steps
- Check periodically if cursor_color config works in new opencode versions
- External editor workaround (Ctrl+x e) temporarily turns cursor red but resets on Ctrl+p