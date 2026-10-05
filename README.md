# 🧹 ɢᴛᴀᴠ ᴄʟᴇᴀɴᴇʀ - ʀᴏᴄᴋѕᴛᴀʀ ᴛᴏᴏʟᴋɪᴛ
[![GitHub repo](https://img.shields.io/badge/github-BunnyHoper-blue?style=for-the-badge&logo=github)](https://github.com/BunnyHoper)
[![Runtime](https://img.shields.io/badge/Runtime-PowerShell%205.1+-5391FE?style=for-the-badge&logo=gnometerminal&logoColor=white)](https://learn.microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6?style=for-the-badge&logo=windows11&logoColor=white)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/ver-1.0.0-red?style=for-the-badge)](https://github.com/BunnyHoper/gtav-cleaner)
[![Donate](https://img.shields.io/badge/Support%20Me-paypal.me/AritzGonzalez7-yellowgreen?style=for-the-badge&logo=paypal)](https://paypal.me/AritzGonzalez7)

> **Wipe Rockstar Games clean (fast & easy).** Uninstall the launcher, Social Club and Easy Anti-Cheat, hunt down every leftover they scatter around Windows, and kill every launcher in one click — plus a one-click GTA Online solo-session trick.

---

## ✨ ɪɴᴛʀᴏᴅᴜᴄᴛɪᴏɴ

Stop hunting leftovers by hand (it's a waste of time). Uninstalling Rockstar's launcher leaves services, drivers, scheduled tasks, registry keys and folders all over your PC. **gtav-cleaner** is a menu-driven PowerShell toolkit that finds them, shows you exactly what it found **before** touching anything, and only deletes after you confirm.

---

## 🛠️ ᴄᴏʀᴇ ᴄᴀᴘᴀʙɪʟɪᴛɪᴇѕ

*   **Full Uninstall:** Stops processes and services, removes scheduled tasks, runs the official silent uninstallers, then deletes install folders and registry keys (Rockstar Launcher, Social Club, Easy Anti-Cheat).
*   **Trace Scanner:** Separate scans for **Windows** (Prefetch, BAM/DAM run-history, Event Log report), **Rockstar** (files, registry, shortcuts, firewall, hosts), **ReShade** (injector DLLs, shaders/presets, config) and **BattlEye** (service, drivers, folder).
*   **Kick Diagnostic:** Reports common non-cheat causes of BattlEye kicks — Secure Boot, Windows Test Mode, Hyper-V, unsigned drivers.
*   **Launcher Killer:** Stops every Rockstar / Steam / Epic Games / BattlEye process and service. Nothing is deleted — safe to relaunch anytime.
*   **Safe by Design:** Checklist before every action, `Y/N` or typed `DELETE` confirmation, registry backup to your Desktop, and a full log file. Heuristic hits and Event Log entries are **reported only, never auto-deleted**.
*   **Solo Session:** Freezes GTA Online for 10 seconds with a live progress screen, then resumes it and brings the game back to focus — drops you into a solo public lobby.

---

## 📂 ᴀʀᴄʜɪᴛᴇᴄᴛᴜʀᴇ -- ʀᴏᴏᴛ

| Folder/File | Type | Action |
| :--- | :---: | :--- |
| `start-cleaner.bat` | **Launcher** | Opens the cleaner menu. Asks for **administrator** rights on its own. |
| `rockstar-cleaner.ps1` | **Core** | The cleaner: uninstall, trace scanner, launcher killer, logging. |
| `start-solo-session.bat` | **Launcher** | Runs the solo-session trick while GTA V is open. |
| `solo-session.ps1` | **Core** | Suspends `GTA5_Enhanced` for 10 s, resumes it and refocuses the game window. |

---

## ⚙️ ǫᴜɪᴄᴋ ѕᴛᴀʀᴛ ɢᴜɪᴅᴇ

1.  **Download:** Clone the repo or grab it as a ZIP (**Code → Download ZIP**) and extract it anywhere.
    ```bash
    git clone https://github.com/BunnyHoper/gtav-cleaner
    ```

2.  **Run the cleaner:** Double-click `start-cleaner.bat` and accept the administrator prompt (UAC), then pick an option:
    ```
    1. Uninstall Rockstar Games Services
    2. Remove Traces
    3. Stop Launcher Services (Rockstar / Steam / Epic Games)
    0. Exit
    ```

3.  **Review & confirm:** Every option shows a checklist first. Nothing is removed until you answer `Y` or type `DELETE`.

4.  **Restart:** Reboot your PC after uninstalling or removing traces. The log and registry backup are saved to your Desktop (`RockstarCleanup_*`).

5.  **Solo session (optional):** With GTA Online running, double-click `start-solo-session.bat` and wait for the 10-second countdown.

---

## ⚠️ ʙᴇꜰᴏʀᴇ ʏᴏᴜ ʀᴜɴ ɪᴛ

| Note | Detail |
| :--- | :--- |
| **Admin rights** | Uninstall and trace removal touch `HKLM`, services and drivers. `start-cleaner.bat` relaunches itself as admin — say **Yes** to the prompt. |
| **Uninstall is permanent** | Option 1 removes the launcher, Social Club and Easy Anti-Cheat. Games that need them will have to reinstall them. |
| **Solo session** | Only targets the Enhanced edition (`GTA5_Enhanced`). The game freezes for 10 s — that's expected. |

---

## 🤝 ᴄᴏɴᴛʀɪʙᴜᴛɪᴏɴ ᴀɴᴅ ѕᴜᴘᴘᴏʀᴛ

Contributions are welcome. If something is missed by the scanner or a launcher update breaks a step:

1.  Fork the repository.
2.  Create a feature branch.
3.  Commit your improvements.
4.  Open a **Pull Request**.

---

## 📜 ʟɪᴄᴇɴѕᴇ

Feel free to do any u want with my scripts. God bless.

***
*Built with ❤️ by Bunny.*
