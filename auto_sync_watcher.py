import os
import sys
import time
import subprocess
import shutil
import glob
import importlib

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))

# ЦІ ДВА ШЛЯХИ БУЛИ ЗАХАРДКОДЖЕНІ на конкретне ім'я користувача Windows ("lyutu"),
# якого немає на комп'ютері жодного з реальних розробників (Illia = "illad").
# Через це build/git-виклики просто тихо падали кожного разу (FileNotFoundError,
# зловлена в except: pass) — і саме тому нові зміни від Claude ніколи не потрапляли
# в StreamerGame.rbxlx, скільки б разів файли не оновлювались у git. Тепер обидва
# шляхи обчислюються динамічно під того, хто реально запускає скрипт — працює
# однаково і в Illia, і в друга, без хардкоду чийогось конкретного імені.
DESKTOP_RBXLX = os.path.join(os.path.expanduser("~"), "Desktop", "StreamerGame.rbxlx")


def _find_git_exe():
    found = shutil.which("git")
    if found:
        return found
    local_appdata = os.environ.get("LOCALAPPDATA")
    if local_appdata:
        matches = glob.glob(os.path.join(local_appdata, "GitHubDesktop", "app-*", "resources", "app", "git", "cmd", "git.exe"))
        if matches:
            matches.sort(reverse=True)
            return matches[0]
    return None


GIT_EXE = _find_git_exe()

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

def check_and_pull_remote():
    """Checks every minute if remote has new commits pushed by friend, and pulls them."""
    if not GIT_EXE:
        print(f"[{time.strftime('%H:%M:%S')}] [ERROR] git.exe not found on this PC (checked PATH and GitHub Desktop's bundled copy). Git sync is disabled until this is fixed.")
        return
    try:
        # Fetch from remote
        fetch_res = subprocess.run(
            [GIT_EXE, "fetch", "origin", "main"],
            cwd=PROJECT_DIR,
            capture_output=True,
            text=True,
            check=False
        )

        # Check how many commits origin/main is ahead of local HEAD
        rev_res = subprocess.run(
            [GIT_EXE, "rev-list", "HEAD..origin/main", "--count"],
            cwd=PROJECT_DIR,
            capture_output=True,
            text=True,
            check=False
        )

        ahead_count = int(rev_res.stdout.strip()) if rev_res.stdout.strip().isdigit() else 0

        if ahead_count > 0:
            print(f"[{time.strftime('%H:%M:%S')}] [PULL] Detected {ahead_count} new commit(s) from friend on GitHub! Pulling...")

            # Check if there are local uncommitted changes
            status_res = subprocess.run([GIT_EXE, "status", "--porcelain"], cwd=PROJECT_DIR, capture_output=True, text=True, check=False)
            has_local = bool(status_res.stdout.strip())

            if has_local:
                timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
                subprocess.run([GIT_EXE, "add", "-A"], cwd=PROJECT_DIR, check=False)
                subprocess.run([GIT_EXE, "commit", "-m", f"Local auto-save before sync: {timestamp}"], cwd=PROJECT_DIR, check=False)

            # Pull and rebase
            pull_res = subprocess.run(
                [GIT_EXE, "pull", "--rebase", "origin", "main"],
                cwd=PROJECT_DIR,
                capture_output=True,
                text=True,
                check=False
            )

            if pull_res.returncode == 0:
                print(f"[{time.strftime('%H:%M:%S')}] [SUCCESS] Successfully pulled friend's updates!")

                # Rebuild place file and update Desktop
                # (importlib.reload is required here: this watcher is a long-running
                # process, so a plain "import build_rbxlx" only re-executes the module
                # ONCE per process lifetime. Without reload(), every rebuild after the
                # very first one silently uses the OLD in-memory code even though the
                # .py file on disk was just updated by this same pull — which is how
                # the hoverboard got reverted back into a car earlier.)
                try:
                    import build_rbxlx
                    importlib.reload(build_rbxlx)
                    build_rbxlx.create_rbxlx(auto_push=False)
                    print(f"[{time.strftime('%H:%M:%S')}] [BUILD] Rebuilt StreamerGame.rbxlx on Desktop with friend's new changes!")
                except Exception as b_err:
                    print(f"[{time.strftime('%H:%M:%S')}] Notice rebuilding place: {b_err}")

                if has_local:
                    subprocess.run([GIT_EXE, "push", "origin", "main"], cwd=PROJECT_DIR, check=False)
            else:
                print(f"[{time.strftime('%H:%M:%S')}] [NOTICE] Pull message: {pull_res.stderr.strip() or 'Rebased'}")
    except Exception as e:
        print(f"[{time.strftime('%H:%M:%S')}] Remote check error: {e}")

def sync_to_github():
    print(f"[{time.strftime('%H:%M:%S')}] [PUSH] Detected local changes! Syncing to GitHub...")
    try:
        proj_rbxlx = os.path.join(PROJECT_DIR, "StreamerGame.rbxlx")
        if os.path.exists(DESKTOP_RBXLX):
            desk_mtime = os.path.getmtime(DESKTOP_RBXLX)
            proj_mtime = os.path.getmtime(proj_rbxlx) if os.path.exists(proj_rbxlx) else 0
            if desk_mtime > proj_mtime + 1:
                shutil.copy2(DESKTOP_RBXLX, proj_rbxlx)
                print(f"[{time.strftime('%H:%M:%S')}] Copied updated StreamerGame.rbxlx from Desktop")
            else:
                try:
                    import build_rbxlx
                    importlib.reload(build_rbxlx)  # see comment above — avoids stale rebuilds
                    build_rbxlx.create_rbxlx(auto_push=False)
                except Exception as b_err:
                    print(f"[{time.strftime('%H:%M:%S')}] Notice rebuilding place: {b_err}")
        else:
            # Немає копії на Робочому столі — все одно перебудовуємо з поточного коду,
            # інакше зміни в .py/.luau ніколи не потраплять у сам StreamerGame.rbxlx.
            try:
                import build_rbxlx
                importlib.reload(build_rbxlx)
                build_rbxlx.create_rbxlx(auto_push=False)
            except Exception as b_err:
                print(f"[{time.strftime('%H:%M:%S')}] Notice rebuilding place: {b_err}")

        if not GIT_EXE:
            print(f"[{time.strftime('%H:%M:%S')}] [ERROR] git.exe not found — rebuilt the place file locally, but can't commit/push. Fix git path to sync with GitHub.")
            return

        subprocess.run([GIT_EXE, "add", "-A"], cwd=PROJECT_DIR, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        status_res = subprocess.run([GIT_EXE, "status", "--porcelain"], cwd=PROJECT_DIR, capture_output=True, text=True, check=False)
        if status_res.stdout.strip():
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
            subprocess.run([GIT_EXE, "commit", "-m", f"Auto-sync changes: {timestamp}"], cwd=PROJECT_DIR, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # Pull rebase before push to make sure we don't conflict with friend
            subprocess.run([GIT_EXE, "pull", "--rebase", "origin", "main"], cwd=PROJECT_DIR, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            push_res = subprocess.run([GIT_EXE, "push", "origin", "main"], cwd=PROJECT_DIR, capture_output=True, text=True, check=False)
            if push_res.returncode == 0:
                print(f"[{time.strftime('%H:%M:%S')}] [SUCCESS] GitHub updated with local changes!")
            else:
                print(f"[{time.strftime('%H:%M:%S')}] Push notice: {push_res.stderr.strip() or 'OK'}")
    except Exception as e:
        print(f"[{time.strftime('%H:%M:%S')}] Sync error: {e}")

def watch_loop():
    print("=== Two-Way Auto-Sync Daemon Started ===")
    print(f"Local Directory: {PROJECT_DIR}")
    print(f"Desktop Place: {DESKTOP_RBXLX}")
    print(f"git.exe: {GIT_EXE or 'NOT FOUND — sync with GitHub is disabled!'}")
    print("Remote Repo: https://github.com/4opt-alt/roblox-streamer-life-simulator")
    print("Remote Check Interval: Every 60 seconds (checks for friend's commits)")
    print("Local Check Interval: Every 3 seconds\n")

    last_project_state = get_dir_state(PROJECT_DIR)
    last_desktop_mtime = os.path.getmtime(DESKTOP_RBXLX) if os.path.exists(DESKTOP_RBXLX) else 0
    last_remote_check_time = time.time()

    # Run initial check on start
    check_and_pull_remote()

    while True:
        try:
            time.sleep(3)
            now = time.time()

            # Check remote repository every 60 seconds
            if now - last_remote_check_time >= 60:
                last_remote_check_time = now
                check_and_pull_remote()
                last_project_state = get_dir_state(PROJECT_DIR)
                last_desktop_mtime = os.path.getmtime(DESKTOP_RBXLX) if os.path.exists(DESKTOP_RBXLX) else 0

            # Check local files for changes
            current_project_state = get_dir_state(PROJECT_DIR)
            current_desktop_mtime = os.path.getmtime(DESKTOP_RBXLX) if os.path.exists(DESKTOP_RBXLX) else 0

            changed = False
            if current_desktop_mtime > last_desktop_mtime:
                changed = True
                last_desktop_mtime = current_desktop_mtime

            if not changed:
                if set(current_project_state.keys()) != set(last_project_state.keys()):
                    changed = True
                else:
                    for p, mtime in current_project_state.items():
                        if mtime != last_project_state.get(p):
                            changed = True
                            break

            if changed:
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
