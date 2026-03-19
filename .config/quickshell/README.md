# Quickshell Configuration

This directory contains a modular, multi-theme (multi-"rice") setup for Quickshell on Hyprland.

The system is designed to:
- Support multiple visual themes ("rices")
- Allow instant switching between them
- Keep each rice fully self-contained
- Maintain a consistent architecture across all themes

---

## 📁 Directory Structure

```mathematica
~/.config/quickshell/
├── README.md
├── shell.qml -> rices/limerence/shell.qml
├── rices/
│   ├── current -> rices/limerence
│   ├── limerence/
│   └── schoolgrid/

```

### Key Concepts

- `rices/`
  - Contains all available themes
  - Each rice is a **fully independent Quickshell configuration**

- `rices/current`
  - A **symlink** pointing to the active rice
  - This is the *single source of truth* for which theme is active

- `shell.qml` (root)
  - Symlink to the active rice’s `shell.qml`
  - Quickshell loads this file on startup

---

## 🔁 How Rice Switching Works

Instead of modifying configuration files directly, this setup uses **symlinks** to switch themes.

### Active Rice Resolution

```mathematica
Quickshell → ~/.config/quickshell/shell.qml
→ symlink → rices/current/shell.qml
→ symlink → rices/<theme>/shell.qml

````

---

### 🧠 Why this design?

- No need to reload configs or edit files
- Clean separation between themes
- Easy to add/remove rices
- Prevents config drift between themes
- Enables future automation (scripts, UI selector, etc.)

---

## 🔄 Switching Rices

To switch themes:

```bash
ln -sfn ~/.config/quickshell/rices/<new-rice> ~/.config/quickshell/rices/current
````

Then reload Quickshell:

```bash
qs -r
```

---

### Example

```bash
ln -sfn ~/.config/quickshell/rices/schoolgrid ~/.config/quickshell/rices/current
qs -r
```

---

## 🎨 Current Status

- Active rice: **`limerence`**
- Other rice(s):

  - `schoolgrid` (in progress / alternate concept)

---

## 🧱 Rice Structure (Standard)

Each rice follows the same internal layout:

```mathematica
rice-name/
├── shell.qml
├── config/
│   └── Appearance.qml
├── components/
│   ├── frame/
│   ├── widgets/
│   ├── services/
│   ├── state/
│   └── effects/
└── assets/
```

### Responsibilities

- `shell.qml`

  - Entry point for the rice
  - Instantiates UI per monitor

- `config/`

  - Centralized styling + sizing (theme tokens)

- `components/frame/`

  - Window layout (TopBar, LeftBar, overlays)

- `components/widgets/`

  - UI elements (icons, popups, indicators)

- `components/services/`

  - System integrations (WiFi, volume, battery, etc.)

- `components/state/`

  - Shared UI state (workspace memory, navigation)

- `assets/`

  - Icons, images, and other static resources

---

## 🧩 Design Philosophy

This setup follows a few core principles:

### 1. Separation of Concerns

* Layout, styling, logic, and system integration are all separated
* Makes the system easier to extend and debug

### 2. Theme Isolation

* Each rice is self-contained
* No cross-theme dependencies

### 3. Declarative UI Composition

* UI is built from reusable QML components
* Each component has a single responsibility

### 4. Centralized Styling

* All sizing and colors live in `Appearance.qml`
* Enables global changes (like scaling) from one place

---

## 📚 Documentation

Each rice may include its own detailed documentation.

For the current rice (`limerence`), see:

```
rices/limerence/docs/
```

This includes:

* Architecture overview
* Window/layer model
* Workspace system
* Widget/service breakdown
* Theming and scaling

---

## 🚧 Future Improvements

* Scripted rice switching
* UI-based theme selector
* Shared base components across rices
* Improved consistency between rices

---

## 🧪 Debugging Tips

Run Quickshell with debug logs:

```bash
qs -p ~/.config/quickshell/shell.qml -d
```

---

## ✅ Summary

- This is a **multi-rice Quickshell system**
- Uses **symlinks for instant theme switching**
- Each rice is **fully modular and isolated**
- The current active theme is **limerence**

