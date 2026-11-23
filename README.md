# AuraNotes — Ultra-Modern AppFlowy Desktop Workspace

> **Powered by AuraStudio Corporation • Pritam**  
> Built upon the **AppFlowy Core Architecture** with the signature **Aura Studio Obsidian Velvet** frontend.

---

## ⚡ Overview

**AuraNotes** is a high-performance, private, 100% offline-first desktop knowledge workspace designed as an alternative to Notion. Engineered with native C++ DirectX 11 hardware acceleration and Windows Acrylic/Mica blur, it delivers instantaneous responsiveness, zero webview bloat, and zero tracking.

---

## ✨ Features & Capabilities

### 1. 📝 AppFlowy Block-Based Document Editor & DSA Studio
- **Algorithm Dry-Run Logic Trace Block:**
  - Visual dry-run block specifically built for **Sliding Window**, **Two-Pointers**, and **Binary Search**.
  - Interactive **Visual Array & Window Strip**: Displays array elements with dynamic pointer tags (`L`, `R`, `M` / Window span) tracking each iteration.
  - Step Playback scrubber (`◀ Prev`, `Next ▶`) with automatic animated walkthrough (`Auto Play`).
  - Pre-built templates for Binary Search, Two Pointers, and Sliding Window.
  - Pro Tip: *"Benefit: Algorithms ratna nahi padega; dry-run table se logic crystal clear yaad rahega."*
- **Rich Interactive Blocks:** Headings (H1, H2, H3), Paragraphs, Todo Checklists, Code Blocks with Dark IDE syntax & 1-click copy, Mac traffic lights, Quotes, Callout banners, Dividers, and Embedded Tables.
- **1-Click Theme Switch:** Seamless toggle between Obsidian Dark Mode and Crisp Developer Light Mode in the window caption.
- **Reliable Document & Block Deletion:**
  - Delete document directly from the editor top bar with confirmation dialog.
  - Right-click (`onSecondaryTapUp`) desktop context menu on sidebar items.
  - Direct 1-click trash button on hover gutter for atomic block deletion.
- **Cover Gradients & Developer Icons:** Personalize documents with Electric Cyan, Aura Violet, Sunset Amber, or Emerald covers.

### 2. 📋 AppFlowy Kanban Board
- **Agile Workflow Columns:** To Do, In Progress, In Review, Done (plus custom column creation).
- **Interactive Task Cards:** Priority badges (High, Medium, Low), due dates, checklist progress counters, and quick move controls.

### 3. 📊 Database Grid & Table View
- **Structured Database Rows:** Task name, status pills, priority pills, category, assignee avatar, and timestamps.
- **Instant Search & Filter:** Filter by status or search across records in real-time.

### 4. ✨ Aura AI Studio Assistant
- **100% Local & Offline Intelligence:**
  - **Summarize Document:** Generates concise executive summaries.
  - **Extract Action Items:** Pulls todo checklists directly from document text.
  - **Brainstorm Ideas:** Strategic suggestions for engineering and architecture.
  - **Polish Writing:** Professional, concise, and creative text refinement.

### 5. 🔍 Command Palette & Keyboard Shortcuts (`Ctrl + K`)
- Instant fuzzy search across all notes, blocks, and kanban cards.
- **Shortcuts:**
  - `Ctrl + K`: Open Command Palette
  - `Ctrl + N`: New Document
  - `Ctrl + 1`: Document Editor View
  - `Ctrl + 2`: Kanban Board View
  - `Ctrl + 3`: Database Grid View
  - `Ctrl + 4`: Aura AI Studio View

---

## 📦 How to Send to a Friend (Install & Uninstall Feature)

The application includes a complete Windows installer and uninstaller suite so you can send it to your friend with zero setup hassle:

### 🚀 Sending to a Friend:
1. Locate the packaged ZIP archive:
   ```
   AuraNotes\dist\AuraNotes-Windows-Portable.zip
   ```
2. Send this `.zip` file (only ~12.6 MB) to your friend via **WhatsApp, Discord, Google Drive, or Telegram**.

### 💻 Friend's Installation Options:
- **Option A (Instant Portable):** Friend unzips the folder and double-clicks `auranotes.exe` to run immediately with zero installation!
- **Option B (Full Windows Install):** Friend double-clicks **`Install-AuraNotes.bat`**:
  - Automatically installs to `%LocalAppData%\Programs\AuraNotes`.
  - Creates **Desktop Shortcut** with custom glowing icon.
  - Creates **Start Menu Shortcut**.
  - Registers in **Windows Settings / Control Panel (Add or Remove Programs)**.
  - Registers right-click **"Edit in AuraNotes"** context menu on `.md` and `.note` files.

### 🗑️ Clean Uninstallation:
- Friend can double-click **`Uninstall-AuraNotes.bat`** at any time, or click **Uninstall** directly inside Windows **Installed Apps**.
- It cleanly removes all shortcuts, registry keys, and program files.

---

## 🛠️ Quick Launch Batch Files (Workspace Root)
- `launch-auranotes.bat`: Launches the desktop app directly.
- `install-auranotes.bat`: Runs the installer on your system.
- `uninstall-auranotes.bat`: Cleanly uninstalls the app.

---

**© 2026 AuraStudio Corporation. All rights reserved.**
