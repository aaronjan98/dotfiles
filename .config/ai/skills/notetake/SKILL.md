# Notetake

## Purpose
Take live notes during a class, office hours, meeting, or call: the user dictates short fragments of what's being said or thought, and the agent folds each one into a specific note file directly — no "fold this in" preamble required per message. Background audio recording is managed implicitly, so a mid-conversation ask like "fold in what he just said" can pull from the actual recording instead of relying on memory.

Full technical background (scripts, where recordings live, known quirks, why recording is segmented): `Inside/Projects/notetake - live note-taking recorder.md` in the zettelkasten vault. This skill is the *session protocol* for using that tooling — read the vault note if something about the underlying mechanism needs debugging; this file is about how to behave once a notetake session starts.

## Use this when
- The user invokes `/notetake`
- The user says something like "let's take notes," "I'm starting class/office hours," or otherwise signals they're about to dictate fragments live and want them folded into a note as they go
- A notetake session is already established earlier in the conversation and the user keeps sending short fragments without re-framing each one (stay in the mode once it starts — don't ask "should I add this?" every time)

## Step 1 — Establish the target note, once
Ask which note file is being worked on, unless it's already obvious (already open/discussed this turn, or an unambiguous "today's class note" for a course already in context — e.g. the most recent `Class Notes ...` file for the course just mentioned). Don't ask again for the rest of the session once this is settled.

## Step 2 — Make sure recording is on, implicitly
Check status and start it silently if it's off — don't ask permission, don't announce it unless something's actually wrong (e.g. the mic source is dead):
```bash
~/nixos-config/scripts/notetake-record.sh status
~/nixos-config/scripts/notetake-record.sh start   # only if status says "not recording"
```
The Quickshell paperclip icon reflects this automatically within ~2s (it polls `status` itself) — no need to tell the user it started, the icon shows it.

## Step 3 — Default interpretation of short input (the core behavior)
Once the target note and recording are both established, a short, fragment-like message is an instruction to edit the note, not a question to discuss first and not something to just hold in conversation. Treat it the way a terse dictation note would be treated: locate (or create) the right spot in the file and add/correct it directly, then report back in one line what landed.

- Declarative fragments, corrections, "include X," "it's actually Y," a bare formula or claim — edit the note. Don't ask "want me to add this?" first; that's the whole point of the mode.
- A fragment that's genuinely incomplete or ambiguous (cuts off mid-thought, pronoun with no clear referent) — ask for the rest before editing, same as any other correction. Don't guess at math content.
- A real question directed at the agent ("what does this mean," "why does X happen") — answer it in chat first, the way normal tutoring works. Only add the resulting explanation to the note if it reads like something worth keeping (use judgment, same as any other note-writing call) — don't mechanically append every Q&A exchange.
- "Fold in what he/she just said" (or similar, pointing at the *recording* rather than dictating content directly) — this is the one case that reaches into the audio: run `~/nixos-config/scripts/notetake-foldin.sh`, read the transcript it prints, and fold the relevant content into the note. This is different from the default case above, where the user is directly giving you the content to add themselves.

## Step 4 — Formatting
Follow the vault's existing note conventions already in memory (tabs not spaces, no blank lines between sibling bullets, `**N.B.**` for placeholders, footnote-style citations for slides/scripts/prior notes). When an `Edit` call fails on a string match, it's almost always a tab-count mismatch — verify the actual indentation with `sed -n '<line>p' file | cat -A` before retrying, don't just guess again.

## Ending a session
Stop recording when the user signals they're done (end of class, hanging up, "that's it for today") — `~/nixos-config/scripts/notetake-record.sh stop`. Don't guess at this silently from a lull in messages; wait for an actual signal. If recordings accumulate and aren't needed anymore, offer to clean up `~/.cache/notetake/session-*` rather than doing it unprompted.
