# My Agents on Dock

A macOS menu bar app that displays animated AI agent characters above your Dock. Automatically detects Claude Code team configurations and shows each agent with unique Lottie-animated robot characters.

## Features

- **9 Animated Characters** — Colorful Lottie robot animations (Black, Blue, Green, Marine, Pink, Purple, Red, White, Yellow)
- **Team Configuration** — Read `team/agents.json` to auto-detect team structure, or configure directly in Settings
- **Real-time Status** — Detects running Claude CLI processes; active agents animate 3x faster with green glow
- **Speech Bubbles** — Click any character for jokes (from free APIs) or work status; TTS voice support with 9 voice options
- **Flexible Layout** — Single row, single column, double rows, or double columns
- **Drag to Reorder** — Rearrange characters by dragging; order persists across restarts
- **Live Reload** — FSEvents watches agents.json for changes and auto-updates

## Screenshots

<!-- Add screenshots here -->

## Requirements

- macOS 14.0 (Sonoma) or later
- Claude Code CLI (for process detection)

## Installation

### Build from Source

```bash
git clone https://github.com/Jin-hoKim/my-agents-on-doc.git
cd my-agents-on-dock
swift build
.build/debug/MyAgentsOnDock
```

## Getting Started

1. **Launch the app** — Look for the 👥 icon in your menu bar
2. **Connect a project** — Click the menu bar icon → "Connect Team Project" → select your project folder containing `team/agents.json`
3. **Customize characters** — Open Settings to assign robot characters and names to each agent
4. **Watch your team** — Active agents glow green and animate faster; click them to see status

## agents.json Format

```json
{
  "leader": {
    "model": "opus",
    "description": "Nova — Team lead, planning"
  },
  "frontend": {
    "model": "sonnet",
    "description": "Sprout — Frontend developer"
  },
  "backend": {
    "model": "sonnet",
    "description": "Bolt — Backend developer"
  }
}
```

The `description` field uses "Name — Role" format. The name is extracted and displayed under each character.

## Characters

| Character | Color |
|-----------|-------|
| Black Robot | Dark gray |
| Blue Robot | Blue |
| Green Robot | Green |
| Marine Robot | Cyan |
| Pink Robot | Pink |
| Purple Robot | Purple |
| Red Robot | Red |
| White Robot | Light gray |
| Yellow Robot | Yellow |

## Settings

| Setting | Description |
|---------|-------------|
| **Character Size** | 60pt – 300pt slider |
| **Layout** | 1 Row / 1 Col / 2 Rows / 2 Cols |
| **Team Editing** | Assign characters, edit names per agent |
| **TTS Voice** | 9 voices (Yuna, Rocko, Grandma, Eddy, etc.) |
| **Voice Toggle** | Enable/disable speech on click |
| **Process Monitor** | 1–10 second polling interval |

## Tech Stack

- Swift 5.9+ / SwiftUI / AppKit (NSPanel, NSStatusItem)
- Lottie for iOS (character animations)
- AVSpeechSynthesizer (TTS)
- FSEvents (file change detection)
- Free joke APIs (icanhazdadjoke.com, JokeAPI)

## Related

- [Docklings](https://github.com/Jin-hoKim/my-agent-on-doc) — Solo mode (single AI companion on Dock)

## License

Copyright 2026 Jin-ho Kim. All rights reserved.

---

[한국어](README-ko.md)
