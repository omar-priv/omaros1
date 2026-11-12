# MEMORY.md — Project handoff index

- handoff-sadeem-os.md — active: Sadim OS in omar-priv/omaros1. Latest static CI Run #67 (43203309994, commit 92f89dc) passed. Current-source ISO Run #20 (43203309978, commit 92f89dc) was queued behind older Run #18 (43202062317, commit 4871d36); #18 had passed kernel and was building Buildroot at last check, but is not the reviewed image because it predates latest network/monitor changes and the QEMU boot gate. Source fixes: seatd daemon enabled and ordered S70seatd→S75-weston; network starts after S10udev; monitor interval and driver-variable expansions fixed. ISO gate now verifies structure and three consecutive QEMU boots with five runtime markers before artifact upload. Do not mark release-ready until current-source ISO, SHA-256, BUILD-REPORT.txt and actual Acer USB trial are checked.
- handoff-opencode-telegram-bridge.md — OpenCode ↔ Telegram bridge project notes.
- handoff-gmail-organizer.md — Gmail organizer project notes.
