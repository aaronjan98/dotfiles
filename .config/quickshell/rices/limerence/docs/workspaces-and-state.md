# Workspaces and State Model

One of the most distinctive parts of this shell is the workspace navigation model.

It is not just a row of workspaces. It is a two-dimensional model:

- **domains** on the left bar
- **slots** on the top bar

This creates a grid-like mental model where the focused workspace is understood as:

- current domain
- current slot within that domain

## Workspace numbering model

The known logic works like this:

- workspace IDs `1` through `9`
  - belong to domain `1`
  - slot equals workspace ID directly
- workspace IDs `11` through `19`
  - belong to domain `1?` No: in the current logic, `11` is interpreted as domain `1` only if the ID is <= 9; otherwise domain is `Math.floor(id / 10)`
  - therefore `11` belongs to domain `1`? No, with `Math.floor(11 / 10)`, domain becomes `1`
  - this means domain values are effectively determined by the tens digit for IDs greater than `9`
- more generally:
  - if `id <= 9`, domain is `1`
  - otherwise domain is `Math.floor(id / 10)`
- slot is:
  - `id` directly when `id <= 9`
  - otherwise `id % 10`

This means the navigation model is intentionally designed around workspace IDs that can encode both domain and slot.

## TopBar workspace island

The centered island in `TopBar.qml` renders slot navigation.

### What it represents

- the current slot within the current domain
- occupancy of other slots in the same domain

### Core behavior

- reads the focused workspace from Hyprland
- derives:
  - `wsId`
  - `domain`
  - `slot`
- builds a horizontal `DotTrack`
  - each item corresponds to one slot
  - the active slot becomes the pill-like expanded item
  - occupied inactive slots appear with different opacity than empty ones

### Slot count behavior

The slot island does not always show a fixed number.

It computes how many slots to show based on:

- a minimum baseline
- the current slot
- the highest slot in the current domain that has windows

This lets the UI stay compact while still expanding as needed.

## LeftBar domain island

The centered island in `LeftBar.qml` renders domain navigation.

### What it represents

- the current domain
- which domains have windows in them

### Core behavior

- derives current domain from focused workspace
- builds a vertical `DotTrack`
- computes domain occupancy by scanning known workspaces and counting toplevel presence

### Domain count behavior

Like the slot island, the domain island also scales its visible count.

It considers:

- a minimum number of visible domains
- the currently focused domain
- the highest domain that contains windows

## `DotTrack.qml`

`DotTrack` is the reusable primitive that both islands rely on.

### What it does

- renders a 1D track of dots along either axis
- expands the active index into a pill-shaped extent
- keeps gaps visually constant while sizes change
- emits click events for individual indices

### Why it is reusable

Its behavior is abstract enough to support:

- horizontal slot tracks
- vertical domain tracks
- potentially other stepped indicators in the future

## `WorkspaceDot.qml`

This appears to be a simpler dot primitive.

### Known role

- renders a single dot
- exposes `active`, `occupied`, and `dotSize`
- visually dims when active so the pill can act as the stronger active marker

This file likely represents an earlier or simpler abstraction than the fully assembled `DotTrack` pill model, or it may still be used in some contexts.

## State files

### `NavState.qml`

Known purpose:

- stores previous navigation context
- includes at least:
  - `prevSlot`
  - `prevDomain`

This is useful for:

- directional animations
- navigation-aware behavior
- future transitions that need to know where the user came from

### `DomainMemory.qml`

Known purpose:

- remember the last slot used for each domain
- persist or reconstruct a domain → slot memory mapping
- ensure that entering a domain returns to the last meaningful slot instead of always defaulting blindly

### Why `DomainMemory` matters

When clicking a domain dot, the shell can:

- look up the last slot that domain used
- jump to the corresponding workspace

This makes the 2D workspace model feel spatial and persistent.

## Workspace click behavior

### Clicking a slot in `TopBar`

- determine target slot number
- map it to a workspace ID in the current domain
- store last slot for the current domain
- ensure the domain is marked visited
- dispatch Hyprland workspace change

### Clicking a domain in `LeftBar`

- determine target domain number
- mark the domain visited
- look up its remembered last slot
- map domain + remembered slot to a workspace ID
- dispatch Hyprland workspace change

## Why this model is strong

This workspace system has several advantages:

- it scales better than a single long strip of workspaces
- it creates a spatial mental model
- it remembers where you were inside each domain
- it keeps the UI compact while still expressive

## Modification guidance

If you want to change workspace behavior, think in these layers:

- **visual layout of the dots/pill**
  - `DotTrack.qml`
  - `WorkspaceDot.qml`
- **how many are shown**
  - `TopBar.qml`
  - `LeftBar.qml`
- **how IDs map to domain/slot**
  - `TopBar.qml`
  - `LeftBar.qml`
  - possibly `DomainMemory.qml`
- **remembered navigation state**
  - `DomainMemory.qml`
  - `NavState.qml`
