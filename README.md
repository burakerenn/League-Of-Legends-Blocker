# LoL Blocker

A simple PowerShell script that stops League of Legends from being downloaded, installed or launched on Windows.

I made this for myself while dealing with a gaming addiction. If you're in the same spot, I hope it helps you too.

> Deciding to quit isn't weakness. It's usually the hardest step.

## How it works

![How it works](docs/how-it-works.svg)

The script sets up two shields:

1. **hosts file:** Blocks Riot and League websites and the servers the game downloads from. The installer can't download and you can't log in.
2. **Watchdog:** Starts silently in the background every time the computer boots. It kills any program with `League` or `Riot` in its name (installer, Riot Client, the game itself) within 3 seconds. It runs as the SYSTEM account, so it's not easy to kill from Task Manager.

Nothing gets deleted. The script only blocks.

## Install

1. Download this repo: **Code → Download ZIP**, then extract it to a folder.
2. Double-click `block.bat`.
3. Click **Yes** when it asks for admin permission.

If you see "Done. League of Legends is now blocked.", you're all set.

If Windows shows a "Windows protected your PC" warning, click **More info → Run anyway**.

## Uninstall

Double-click `unblock.bat` to fully remove the block. It's annoying on purpose:

- It makes you wait **10 minutes** first. Cravings usually pass within that time.
- Then it asks you to type a long sentence **exactly**.

**Tip:** After installing, delete `unblock.bat` and `unblock.ps1`, or give them to someone you trust.

## Let's be honest: limitations

- Someone who knows computers well can get around this. The goal isn't an unbreakable wall. It's to put **enough friction** between the urge and the game.
- A VPN, a different DNS or another computer will get around it.
- It only works on Windows. It doesn't block mobile games like *Wild Rift*.
- The watchdog kills **every** program with "League" or "Riot" in its name. Other Riot games (Valorant, etc.) are affected too.

For a stronger block, have someone you trust change your computer's admin password. Then removing the block gets really hard.

## You're not alone

A program alone might not be enough. These help too:

- **Talk to a professional.** Many countries have free addiction helplines that also cover gaming. In Turkey, call **Yeşilay at 115** (free).
- Tell a friend. Having someone who checks in on you makes a big difference.
- Fill the gap the game leaves with something else: exercise, walks, people you can spend time with.
- Notice your triggers. Do you want to play when you're bored, stressed or up late at night?

---

Good luck. GG, but this time make sure you're the one who wins.
