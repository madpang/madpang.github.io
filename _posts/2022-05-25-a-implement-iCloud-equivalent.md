---
author: TPP
initial creation: 2022-05-25
last modification: 2022-05-27
TODO: there is a need to handle stacks on W4:@Lily-Titan
---

# Poorman's "iCloud" implementation

## Issues of iCloud

- UNRELIABLE → see 2022-01-26 crash.
- Unable to utilize *Time Machine* → letting Time Machine to spit files into the iCloud managed directories would only create chaos across multiple devices.
- Unsuitable for **Git** → iCloud would occasionally delete files (and only leave some `.icloud` stub files) when "it" considers that file is of NOT frequent use, and this would just trigger the monitoring of Git.

## Purpose

- Workspace synchronization—this is what exactly iCloud do, but I want a more controllable way.
- Workspace backup, to hold my ass.

## Method

### Arsenal of automation

1. **PowerShell**
2. **Shortcuts.app** (macOS)
3. **bash/zsh**
4. **AppleScript** (macOS)
5. **Wolfram Script** → there is license constrain, the last resort or just for fast prototyping

### Considerations

1. After THIS implementation, `W1:@iCloud` would generally be deprecated, and would be only for temporary use.
2. It is only necessary to sync between `W2:@Lily-Acrux` and `W3:@PD-Pisces`, to facilitate work-from-home.
3. While `W4:@Lily-Titan` takes a special role as the central Git repositories, it holds project-base *stacks*, and *archives*. There will be large chunks of raw data stored there, and is not supposed to sync between other workspaces. The backup of `W4:` will be carried out separately (using Linux utilities).
4. *Render unto **Git** the things that are Git's, and unto **rsync** the things that are rsync's*.
5. Relative symbolic links FROM the managed folder (and pointing to git repo.) could be synced by `rsync`. → config `core.symlinks = false` in Git repo. to see links as it is, instead of tracing the original file.
6. Bidirectional sync is necessary for `W2:@Lily-Acrux` ←→ `W3:@PD-Pisces`. The `--delete` option and double execution of `rsync` are necessary. Since no *central* "repo" exists in-between (it is like working tree to working tree git merge—which is actually forbidden in Git), one must be CAUTION[^1] about the order of "pull/push" operation (and I realized that iCloud must have adopted the *frequent* sync strategy to handle this issue).
7. Take care of *File-Sharing* (e.g. via `SMB`) → `rync` runs orders more efficiently via `SSH` than crossing mounted `SMB`.

[^1]: Skip the `--delete` option is an easy way to keep all incremental changes, and make the two workspaces mirror each other. It is exactly when decremental change is made that special caution must be taken.

#### Folders to by synced

- `01-Lily`: my main work folder
- `02-PhD`: my research folder
- `03-Zettelkasten` : my notes collection
- `04-resource`: document, unsorted material (e.g. external MATLAB packages), etc.
- `05-archive`: things that would be gradually fade out

#### Folders to be managed by Git

- `Git-Repo`: contains various project repositories, e.g. `dotfiles` is moved into this folder

#### Folders need special treat

- `**/stack`: contains stacks of investigation → should go to `W4:@Lily-Titan`

==MARK== Here is an example,

``` bash
rsync -azv --exclude={'data/**','media/**','result/**'} Lily-Titan:~/Workspace4/01-Lily/stack/2022-02-08-attenuation-estimation ~/Workspace3/01-Lily/stack/
```

#### Folders not to be synced

- `private`: private doc/projects, on PD-Pisces
- `tmp`: for temporary data exchange

### Implementation

See `Wi:/04-resource/macOS-Shortcuts/Sync-WKSP.shortcut`

## Discussion

### Authentication issue

In the current setting, one can NOT ssh into `PD-Pisces` w/o password (server-side not configured). However, Shortcuts.app provides a utility "Run script over SSH" which accepts pre-entered password for connection. In this way, command can be always initiated from `PD-Pisces`, which has free access to `Lily-Acrux`.

### Notification issue

After synchronization completes, there should be some mechanism to notify the success, one may still rely on the SSH.

## Reference

1. 2022-03-21-b-rsync.md

## Appendix

### Using `tree` to explore folder structure

One learns the usage by seeing the example—`tree -dlN -L 2` 

``` sh
╭ env: N/A | tianhantang@LILY-TITAN:~ | git: N/A
λ > tree -dl -L 2
.
├── Documents
│   └── MATLAB
├── Downloads
├── snap
│   └── powershell
└── Workspace4 -> /data/Workspace4
    ├── font
    ├── Lily
    ├── MATLAB
    ├── PhD
    └── tmp

11 directories
╰ log: 2022-05-24 11:10:03 +09:00 | stat: ✓
```

- option `-d`: list directories only → this is important to avoid clutter.
- option `-l`: follow symbolic link → see "Workspace4" in the above result.
- option `-N`: Print non-printable characters as is → useful for printing Unicode characters.
- option `-L [num]` controls the max depth of directory tree → important to balance between details and chaos.

