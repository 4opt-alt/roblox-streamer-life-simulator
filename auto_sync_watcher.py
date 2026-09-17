import os
import sys
import time
import subprocess
import shutil

PROJECT_DIR = r"C:\Users\lyutu\.gemini\antigravity\scratch\roblox-streamer-game"
DESKTOP_RBXLX = r"C:\Users\lyutu\Desktop\StreamerGame.rbxlx"
GIT_EXE = r"C:\Users\lyutu\.tools\git\cmd\git.exe"

def get_dir_state(target_dir):
    state = {}
    for root, dirs, files in os.walk(target_dir):
        if ".git" in root or "__pycache__" in root:
            continue
        for f in files:
            p = os.path.join(root, f)
            try:
                state[p] = os.path.getmtime(p)
            except OSError:
                pass
    return state

def sync_to_github():
    print(f"[{time.strftime('%H:%M:%S')}] Detected changes! Syncing to GitHub...")
    try:
        # 1. Check if Desktop rbxlx is newer than project rbxlx
        proj_rbxlx = os.path.join(PROJECT_DIR, "StreamerGame.rbxlx")
        if os.path.exists(DESKTOP_RBXLX):
            desk_mtime = os.path.getmtime(DESKTOP_RBXLX)
            proj_mtime = os.path.getmtime(proj_rbxlx) if os.path.exists(proj_rbxlx) else 0
            if desk_mtime > proj_mtime + 1:
                shutil.copy2(DESKTOP_RBXLX, proj_rbxlx)
                print(f"[{time.strftime('%H:%M:%S')}] Copied updated StreamerGame.rbxlx from Desktop")

        # 2. Git stage
        subprocess.run([GIT_EXE, "add", "-A"], cwd=PROJECT_DIR, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # 3. Check status
        status_res = subprocess.run([GIT_EXE, "status", "--porcelain"], cwd=PROJECT_DIR, capture_output=True, text=True, check=False)
        if status_res.stdout.strip():
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
            subprocess.run([GIT_EXE, "commit", "-m", f"Auto-sync changes: {timestamp}"], cwd=PROJECT_DIR, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            push_res = subprocess.run([GIT_EXE, "push", "origin", "main"], cwd=PROJECT_DIR, capture_output=True, text=True, check=False)
            if push_res.returncode == 0:
                print(f"[{time.strftime('%H:%M:%S')}] PUSH SUCCESS: GitHub updated!")
            else:
                print(f"[{time.strftime('%H:%M:%S')}] Push notice: {push_res.stderr.strip() or 'OK'}")
        else:
            print(f"[{time.strftime('%H:%M:%S')}] No changes detected to commit.")
    except Exception as e:
        print(f"[{time.strftime('%H:%M:%S')}] Sync error: {e}")

def watch_loop():
    print(f"=== Auto-Sync Daemon Started ===")
    print(f"Monitoring: {PROJECT_DIR}")
    print(f"Monitoring: {DESKTOP_RBXLX}")
    print(f"Target: https://github.com/4opt-alt/roblox-streamer-life-simulator\n")
    
    last_project_state = get_dir_state(PROJECT_DIR)
    last_desktop_mtime = os.path.getmtime(DESKTOP_RBXLX) if os.path.exists(DESKTOP_RBXLX) else 0
    
    while True:
        try:
            time.sleep(3)
            current_project_state = get_dir_state(PROJECT_DIR)
            current_desktop_mtime = os.path.getmtime(DESKTOP_RBXLX) if os.path.exists(DESKTOP_RBXLX) else 0
            
            changed = False
            # Check desktop rbxlx
            if current_desktop_mtime > last_desktop_mtime:
                changed = True
                last_desktop_mtime = current_desktop_mtime
                
            # Check project files
            if not changed:
                if set(current_project_state.keys()) != set(last_project_state.keys()):
                    changed = True
                else:
                    for p, mtime in current_project_state.items():
                        if mtime != last_project_state.get(p):
                            changed = True
                            break
                            
            if changed:
                # Wait 2 seconds debounce for any additional writes to finish
                time.sleep(2)
                sync_to_github()
                last_project_state = get_dir_state(PROJECT_DIR)
                last_desktop_mtime = os.path.getmtime(DESKTOP_RBXLX) if os.path.exists(DESKTOP_RBXLX) else 0
        except KeyboardInterrupt:
            break
        except Exception as e:
            time.sleep(3)

if __name__ == "__main__":
    watch_loop()
