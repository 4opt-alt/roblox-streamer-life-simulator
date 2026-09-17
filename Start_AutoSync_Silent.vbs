Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\lyutu\.gemini\antigravity\scratch\roblox-streamer-game"
WshShell.Run "pythonw.exe auto_sync_watcher.py", 0, False
