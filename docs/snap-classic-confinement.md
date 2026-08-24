# Snap classic confinement

BusyMark is a development tool for local Markdown and Writerside-compatible
documentation projects. A workspace can be located anywhere the user can
normally access, and the integrated Git UI supports reviewing, staging,
committing, branching, synchronizing, and inspecting history.

The Snap therefore uses classic confinement. Correct Git behavior depends on
more than access to a repository directory. BusyMark must preserve the user's
normal Git environment, including:

- `~/.gitconfig`, XDG Git configuration, conditional includes, and repository
  configuration;
- SSH and GPG agents, credential helpers, signing programs, and user keyrings;
- Git hooks, custom transports, external diff tools, and helper commands;
- documentation workspaces on paths selected by the user.

Strict interfaces cannot express arbitrary user-configured helper programs and
configuration includes. Replacing the user's Git identity inside the Snap, or
requiring duplicate per-repository configuration, would make the integrated Git
workflow behave differently from Git in the user's terminal and other IDEs.

## Store review rationale

Use this summary when requesting classic-confinement approval for the Snap:

> BusyMark is a desktop development tool for Markdown and Writerside
> documentation projects with an integrated Git client. It needs classic
> confinement to open user-selected workspaces and honor the user's existing
> Git configuration, conditional includes, credential helpers, SSH/GPG agents,
> signing tools, hooks, and custom Git transports. These are arbitrary
> user-configured development tools and cannot be represented by a fixed set of
> strict-confinement interfaces.

Classic access is used for user-initiated editor and Git operations. BusyMark
does not change the user's Git identity, does not mutate repositories in the
background, and disables interactive terminal prompts so a Git child process
cannot leave the UI hanging. Web content used for preview and visualization
runs in an ephemeral WebKit context with WebKit's subprocess sandbox enabled.
Cloud AI requests remain an explicit, user-configured feature.

Local or CI installations of an unasserted build must opt in explicitly:

```bash
sudo snap install --dangerous --classic ./busymark_*.snap
```

