# docker-user-jail-mvp

A minimal Docker integration template that demonstrates how to run a container as root during initialisation and then permanently hand off control to an unprivileged user at runtime — with no way back.

---

## The problem

Docker containers often need to run as root for setup tasks: installing packages, creating users, adjusting file ownership on mounted volumes. But leaving the actual workload running as root is a security risk — if the application is ever compromised, an attacker has full root access inside the container and a much easier path to the host.

The naive fix — using the `USER` directive in the Dockerfile — doesn't work cleanly when the UID/GID need to match the host's file ownership (which is only known at runtime, not build time).

This project solves both problems cleanly.

---

## How it works

The container starts as root. The `entrypoint.sh` does all the setup that requires elevated privileges:

1. Creates the group with the requested GID (`PGID`)
2. Creates the user with the requested UID (`PUID`)
3. Fixes ownership of the home directory
4. Calls `exec gosu <user>:<group> <command>`

That last step is the jail. `exec` **replaces** the current process entirely — the root shell that ran the entrypoint ceases to exist. `gosu` drops privileges at the kernel level and hands control to your application. From that point forward, PID 1 is your application, running as an unprivileged user. Root is gone. There is nothing to escalate back to.

---

## Workflow

```mermaid
flowchart TD
    A["docker run -e PUID=1000 -e PGID=1000 image [cmd]"]
    A --> B["Container starts<br/>entrypoint.sh runs as root (PID 1)"]
    B --> C{"Group 'steam'<br/>exists?"}
    C -- No --> D["groupadd steam --gid $PGID"]
    C -- Yes --> E["Skip"]
    D --> F{"User 'steam'<br/>exists?"}
    E --> F
    F -- No --> G["useradd steam --uid $PUID"]
    F -- Yes --> H["Skip"]
    G --> I["chown -R steam:steam /home/steam"]
    H --> I
    I --> J["exec gosu steam:steam [cmd]"]
    J --> K["PID 1 is now [cmd]<br/>running as unprivileged user"]
    K --> L["Root process is GONE<br/>No escalation path exists"]
```

---

## The security model explained

### Why not just set `USER` in the Dockerfile?

The `USER` instruction in a Dockerfile sets a fixed user for all subsequent instructions and the final container process. It cannot react to runtime input — you cannot pass a `PUID`/`PGID` environment variable and have the `USER` instruction pick it up. You also cannot `chown` directories at runtime without root. This approach solves all of that.

### Why `gosu` instead of `su` or `sudo`?

| Tool | Behaviour | Problem |
|---|---|---|
| `sudo` | Forks a privileged helper process | Root process stays alive; `sudo` binary remains available as an attack surface |
| `su` | Also forks; uses the system's login infrastructure (user authentication, session setup, environment loading) | All that overhead exists to serve interactive logins — none of it is needed or appropriate in a container; not designed for containers, and the root parent process still lingers |
| `gosu` | `setuid` + `setgid` + `exec` in one step | No fork, no parent, no root remnant — purpose-built for this pattern |

`gosu` does exactly three things: set the GID, set the UID, exec the command. After that, it no longer exists.

### Why `exec gosu` and not just `gosu`?

Without `exec`, the shell running `entrypoint.sh` stays alive as PID 1 (as root), and `gosu` runs as a child process. The root shell is still there.

With `exec`, the shell **is replaced** by the process that `gosu` hands off to. The root shell is gone at the OS level — not just "doing nothing", but literally no longer a process.

### The PUID / PGID pattern

When you bind-mount a host directory into a container, the files are owned by a host UID/GID. If the container user has a different UID, it cannot write to those files. By accepting `PUID` and `PGID` as environment variables at runtime, the entrypoint creates the in-container user with exactly the right IDs to match host ownership — without hardcoding anything in the image.

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `PUID` | `7351` | UID to assign to the in-container user |
| `PGID` | `2431` | GID to assign to the in-container group |

---

## Usage

### Build

```bash
./docker-build.sh
# or: docker build -t user-jail-mvp:local .
```

### Run with default IDs

```bash
./docker-run.sh [command]
# or: docker run --rm user-jail-mvp:local [command]
```

### Run with custom IDs

```bash
./docker-run-other-ids.sh [command]
# or: docker run --rm -e PUID=1000 -e PGID=1000 user-jail-mvp:local [command]
```

### Verify the jail

```bash
# Check the effective user identity — should show steam's UID, never root
./docker-exec.sh
# uid=7351(steam) gid=2431(steam) groups=2431(steam)

# Open an interactive shell as the jailed user
./docker-exec-ti.sh
```

---

## Using this as a template

This repository is an **integration template**, not a base image to layer on top of blindly. The security guarantee only holds if the jail pattern in `entrypoint.sh` is preserved correctly.

The right way to use this:

1. **Copy** this repository as your starting point
2. Add your application's installation steps to the `Dockerfile` — these can run as root, that is intentional
3. Keep `entrypoint.sh` as the `ENTRYPOINT` — extend it if you need extra setup steps, but always keep `exec gosu` as the **last line**. The `exec` keyword does not start a new process — it overwrites the running shell with your application. The shell that did the setup work ceases to exist; your application takes its place. Remove `exec` and the root shell survives as a silent, forgotten parent process
4. Never add logic after the `exec gosu` line — it will never execute, and attempting to restructure it away from being the final `exec` breaks the jail

The entrypoint is the security boundary. Treat it as such.
