<div align="center">

```
███╗   ██╗██╗   ██╗██████╗ ██╗  ██╗ ██████╗ ██████╗ 
████╗  ██║╚██╗ ██╔╝██╔══██╗██║  ██║██╔═══██╗██╔══██╗
██╔██╗ ██║ ╚████╔╝ ██████╔╝███████║██║   ██║██████╔╝
██║╚██╗██║  ╚██╔╝  ██╔═══╝ ██╔══██║██║   ██║██╔══██╗
██║ ╚████║   ██║   ██║     ██║  ██║╚██████╔╝██║  ██║
╚═╝  ╚═══╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
```

### **N Y P H O R   U I   L I B R A R Y**

*A clean, minimal Roblox UI library*  
*— No plan. Just move. —*

<br>

![Lua](https://img.shields.io/badge/Lua-5.1-000B41?style=for-the-badge&logo=lua&logoColor=0088FF&labelColor=000B41)
![Roblox](https://img.shields.io/badge/Roblox-Executor-000B41?style=for-the-badge&logo=roblox&logoColor=0088FF&labelColor=000B41)
![License](https://img.shields.io/badge/License-MIT-000B41?style=for-the-badge&labelColor=000B41&color=0088FF)
![Status](https://img.shields.io/badge/Status-Stable-000B41?style=for-the-badge&labelColor=000B41&color=0088FF)

<br>

[**Installation**](#installation) ·
[**Quick Start**](#quick-start) ·
[**API Reference**](#api-reference) ·
[**Examples**](#examples) ·
[**Notes**](#important-notes) ·
[**Credits**](#credits)

</div>

<br>

---

<br>

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Nyphor is a single-file UI library inspired by the original   │
│   Nyphor server-side script. All server dependencies have       │
│   been stripped — what remains is the pretty part.              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Highlights

```
   ▸  Five fixed pages — Home, Executor, Scripts, Settings, Credits
   ▸  Smooth four-direction page transitions
   ▸  Side menu with toggle animation
   ▸  Draggable main window
   ▸  Live search filter on Scripts tab
   ▸  Pixel-particle notification system with countdown
   ▸  Material-style ripple effect on every button
   ▸  Rotating NYPHOR letters on Home page
   ▸  Singleton — duplicate calls auto-replace prior instance
```

<br>

---

<br>

## Installation

```lua
local Nyphor = loadstring(game:HttpGet("https://raw.githubusercontent.com/f01o-top/NyphorLib/refs/heads/main/Nyphor.lua"))()
```

<br>

---

<br>

## Quick Start

```lua
local Nyphor = loadstring(game:HttpGet("https://raw.githubusercontent.com/f01o-top/NyphorLib/refs/heads/main/Nyphor.lua"))()
local Players = game:GetService("Players")

local UI = Nyphor:Init({
    Welcome  = "WELCOME BACK, " .. Players.LocalPlayer.Name:upper(),
    Subtitle = "NO PLAN. JUST MOVE.",
})

UI:AddScript("Infinite Yield", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

UI:AddCredit("F01o — Owner")
UI:Notify("Loaded", "Nyphor UI ready", 3)
```

<br>

---

<br>

## Configuration

The `Init` method accepts an optional config table:

```lua
local UI = Nyphor:Init({
    Welcome  = "WELCOME TO NYPHOR, USER.",
    Subtitle = "NO PLAN. JUST MOVE.",
    Hint     = "Press NYPHOR for menu",
})
```

```
┌──────────────┬──────────┬─────────────────────────────────────────┐
│   Field      │   Type   │   Default                               │
├──────────────┼──────────┼─────────────────────────────────────────┤
│   Welcome    │  string  │  "WELCOME TO NYPHOR, [PLAYER_NAME]."    │
│   Subtitle   │  string  │  "NO PLAN. JUST MOVE."                  │
│   Hint       │  string  │  "Press NYPHOR for menu"                │
└──────────────┴──────────┴─────────────────────────────────────────┘
```

If `Welcome` is omitted, the player's name is fetched safely  
inside the library — no need to access `game.Players` yourself.

<br>

---

<br>

## API Reference

### Scripts Management

```lua
UI:AddScript(name, callback)
UI:RemoveScript(name)
UI:ClearScripts()
```

### Credits Management

```lua
UI:AddCredit(text)
```

### Notifications

```lua
UI:Notify(title, content, duration)
```

Duration is clamped to 1-5 seconds.

### Visibility Control

```lua
UI:Show()
UI:Hide()
UI:Toggle()
UI:Destroy()
```

### Executor Callback

```lua
UI:OnExecute(function(source)
    -- Custom handler for the EXECUTE button
    -- Defaults to plain loadstring if not set
end)
```

### Dynamic Text

```lua
UI:SetWelcome(text)
UI:SetSubtitle(text)
```

<br>

---

<br>

## Page Transitions

Pages slide in from a direction determined by the source/target combination:

```
                              ┌─────────┐
                              │         │
                              │  HOME   │
                              │         │
                              └────┬────┘
                                   │
                  ┌────────────────┼────────────────┐
                  │                │                │
                  ▼                ▼                ▼
            ┌─────────┐      ┌─────────┐      ┌─────────┐
            │ SCRIPTS │      │ CREDITS │      │SETTINGS │
            │         │      │         │      │         │
            └────┬────┘      └────┬────┘      └────┬────┘
                 │                │                │
                 └────────────────┼────────────────┘
                                  ▼
                            ┌─────────┐
                            │EXECUTOR │
                            │         │
                            └─────────┘
```

```
┌──────────────┬──────────────┬───────────┐
│    From      │      To      │ Direction │
├──────────────┼──────────────┼───────────┤
│   Home       │   Executor   │  Right    │
│   Home       │   Scripts    │  Down     │
│   Home       │   Settings   │  Left     │
│   Home       │   Credits    │  Up       │
│   Executor   │   Scripts    │  Down     │
│   Scripts    │   Settings   │  Right    │
│   Settings   │   Credits    │  Right    │
│   Credits    │   Home       │  Right    │
└──────────────┴──────────────┴───────────┘
```

<br>

---

<br>

## Examples

### Complete Setup

```lua
local Nyphor = loadstring(game:HttpGet("https://raw.githubusercontent.com/f01o-top/NyphorLib/refs/heads/main/Nyphor.lua"))()
local Players = game:GetService("Players")

local UI = Nyphor:Init({
    Welcome  = "WELCOME BACK, " .. Players.LocalPlayer.Name:upper(),
    Subtitle = "NO PLAN. JUST MOVE.",
})

UI:AddScript("Infinite Yield", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

UI:AddScript("Dex Explorer", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
end)

UI:AddScript("Remote Spy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()
end)

UI:AddCredit("F01o — Owner")

UI:OnExecute(function(source)
    local fn = loadstring(source)
    if fn then fn() end
end)

UI:Notify("Loaded", "All systems online.", 3)
```

### Keybind Toggle

```lua
local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        UI:Toggle()
    end
end)
```

### Dynamic Updates

```lua
task.spawn(function()
    while task.wait(60) do
        UI:Notify("Status", "Still running.", 3)
    end
end)

UI:AddScript("Late Bound", function()
    print("Added after init.")
end)
```

<br>

---

<br>

## Important Notes

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│   ALWAYS use   game:GetService("Players")                          │
│   NEVER use    game.Players                                        │
│                                                                    │
│   The dot accessor fails in environments where the DataModel       │
│   name differs (e.g. UGC catalog previews, custom DataModels).     │
│   Use the colon-call form for guaranteed compatibility.            │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### Wrong

```lua
local UI = Nyphor:Init({
    Welcome = "HI " .. game.Players.LocalPlayer.Name,
})
```

### Right

```lua
local Players = game:GetService("Players")

local UI = Nyphor:Init({
    Welcome = "HI " .. Players.LocalPlayer.Name,
})
```

### Easiest

Omit `Welcome` entirely — the library generates a default safely:

```lua
local UI = Nyphor:Init({
    Subtitle = "NO PLAN. JUST MOVE.",
})
```

<br>

---

<br>

## Compatibility

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│   The library auto-detects executor environments and chooses       │
│   the appropriate parent for the ScreenGui:                        │
│                                                                    │
│      1.  gethui()               — modern executors                 │
│      2.  syn.protect_gui()      — Synapse legacy                   │
│      3.  CoreGui                — direct fallback                  │
│      4.  PlayerGui              — non-executor environments        │
│                                                                    │
│   All service lookups are wrapped in pcall + cloneref where        │
│   available, so anti-cheat hooked environments still work.         │
│                                                                    │
│   Tested on: most UNC-compliant executors.                         │
│   May behave inconsistently on UNC-deficient executors.            │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

<br>

---

<br>

## File Structure

```
NyphorLib.lua
│
├──  Services & Singleton Check
│    └── safeGetService + cloneref + pcall fallbacks
│
├──  Util
│    ├── Dragify       — drag any frame
│    ├── Scrollify     — smooth scrolling
│    ├── Searchify     — live filter
│    └── Buttonify     — ripple + hover effects
│
├──  NotifyManager
│    ├── new()
│    ├── Show()
│    └── _createPixel()  — pixel particles
│
├──  buildUI()
│    ├── Main frame, shadows, gradient
│    ├── Pages — Home / Executor / Scripts / Settings / Credits
│    └── Side menu + Open button
│
└──  Nyphor (public methods)
     ├── Init / Destroy
     ├── AddScript / RemoveScript / ClearScripts
     ├── AddCredit
     ├── Notify
     ├── OnExecute
     ├── Show / Hide / Toggle
     └── SetWelcome / SetSubtitle
```

<br>

---

<br>

## Credits

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Original Nyphor UI Design        F01o                     │
│   UI Component System              Nyphor                   │
│   Library Conversion               F01o                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

The visual design and component patterns originate from the  
original Nyphor project. This repository repurposes only the  
client-side UI code into a reusable library, with all  
server-side and execution logic removed.

<br>

---

<br>

## License

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   MIT License — Copyright (c) 2026 f01o                     │
│                                                             │
│   Free to use, modify, merge, publish, distribute,          │
│   sublicense, and/or sell copies of this software,          │
│   provided the copyright notice is included.                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

See the [LICENSE](./LICENSE) file for the full text.

<br>

<div align="center">

```
─────────────────────────────────────────────────────
                  N O   P L A N
                 J U S T   M O V E
─────────────────────────────────────────────────────
```

</div>
