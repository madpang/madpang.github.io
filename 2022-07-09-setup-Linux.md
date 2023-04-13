---
When:
- initial creation on 2022-07-09
- last update on 2023-02-26
Tags:
- #Linux, #workflow, #CLI
---



# Setting up a Linux server

## Purpose

- (primarily) provide a **data warehouse**
  - ~~for Time Machine backup of *Lily-Acrux*—the iMac, my main *terminal*~~.[^*]
  - for *Workspace4*—the crux of my multi-platform workflow (macOS, Windows, Linux), which holds *stacks* of work and research progress.
- (optionally) provide a **computation force**
  - for large-scale, long-run MATLAB simulation (w/ the ability to utilize NVIDIA CUDA power).
- (experimentally) provide a host for other web-based applications
	- e.g. Jupyter back-end (w/ appropriate Python environment)

The trigger of setting up a Linux server is the start of long-term remote-work at the end of 2021, due to the world-wide spreading of COVID-19 in[^1]. I use an iMac (27" Intel-based, 2020 model, company-own) at the office as my main *terminal*, and I use another iMac (24" Apple M1 chip based, 2021 model, private-own) as a *terminal* for work-from-home. However, keeping environments on difference devices identical is NOT an easy task[^2]. I used to rely on iCloud for data synchronization. However, there are several issues:

1. I need to backup *Lily-Acrux* (the iMac at office). Data-lost is a VERY BAD disaster in modern life. At home, I have *PD-Pices* (the iMac at home) weekly backup to *Mir*—an Airport Time Capsule (Apple’s NAS—Network Attached Storage). However, at office, there is no appropriate place for Time Machine backup. I have tested company's file server (*Lily-fs04*), but it is NOT good—there is no config. to support Time Machine, and there is even NO user control—All colleagues just use the same account for data accessing! (Some of my colleagues have experienced data lost but they just do NOT learn.)
2. All other colleagues in the company use Windows system, so I HAVE TO run Windows program (e.g. image reconstruction program), and I have to develop on Windows platform sometimes (e.g., to do simulation w/ GPU-acceleration[^3] since macOS is just outside NVIDIA’s CUDA ecosystem).
3. I prefer to edit the source code in local environment, so that I can use my customized shortcuts and enjoy the elegant graphical quality of macOS[^4]. Therefore, I need a method to **mount** the remote data drive onto the local *workspace*[^5].
4. The network speed is slow when working from home (currently, I am living in an old rented mansion, this issue just can not be resolved in short time), and it is especially slow when using VPN to connect to company’s LAN. Therefore, a traditional text-based CLI is more than an option for the work. I thought Windows is not suitable for this kind of usage (anyway, it even can NOT launch MATLAB inside the shell).
5. iCloud is personal. I do NOT want to mix my personal data w/ work files. For the same reason, I do NOT want to install an iCloud app. on the share-use Windows machine at work. iCloud has storage limit. I used to carefully utilize iCloud only on the two Macs (although one is company-own, it is dedicated for me), but it is not suitable for large data sync. (which, however, is often encounter at work, e.g. simulation investigation and experiment data processing). More importantly, iCloud is NOT reliable. On 2022-01-26, there is a whole day outages of iCloud. When it is happen, end user can DO NOTHING.

To act on those challenges, I come up with a *multi-workspaces cross-platform workflow*. The key role of this workflow is a **server** that provides a *central workspace* for (large) data exchange (e.g. stacks of working projects), and provides storage for *Lily-Acrux* backup. The server should be stable enough for all-time-on, and should let me have full control.

The requirements for full control and backup ability exclude the NAS of company. While according to my experience, neither Windows nor macOS is "stable" enough. Windows is notorious for taking action "on behalf" of the user (e..g forced auto update etc.). While I have tried just putting this central workspace on *Lily-Acrux*, there are some problems. First, the storage is not enough (only 1TB onboard); Second, mounting *WKSP2* (the workspace @*Lily-Acrux*) from other systems (e.g. Windows machine) introduces permission issue[^6]; Third, occasional log-out or restart (due to update or mere system freeze) will break the workflow. 

Accidentally, there is a spare workstation (2016 model Dell Precession 7910) in the company that I can use exclusively. It has relatively good spec. even in current standard. It features:

- 2x Intel® Xeon™ E5-2687W v3 CPU, each w/ 3.10GHz clock frequency, 10C20T.
- 1x Nvidia GeForce GTX TITAN X graphic card, w/ 12GB memory (Maxwell architecture).
- 256 GB RAM
- 8TB+ SSD

This device (named as ~~*Lily-Titan*~~ *PD-Titan*[^**]) is ideal for a server, and when talking about server, Linux just naturally comes into my mind. Although I do not have previous experience w/ Linux world, I have been a Unix (macOS) user for 9 years. I am familiar w/ basic CLI technique, and I am willing to learn and try.

[^1]: before the setup of virtual workspace, I have put huge effort to improve work-from-home environment, w/ new layout adjustment, purchasing new working desk and working chair (for both TPP and XBB).
[^2]: the routine task includes data sync and config. sync (e.g. shell profile, shortcuts, theme, etc.)
[^3]: the most common scenario is directly utilizing CUDA-enabled GPU via MATLAB™.
[^4]: other Windows-using colleagues just relying on VPN+RDP or Splashtop to work on the remote machine. I tried, but tougher w/ the issue 3, the experience is NOT satisfying.
[^5]: there will be a dedicated post to address this issue.
[^6]: I created a share-only account to access *WKSP2* form other systems to avoid potential data leak, since *Lily-Acrux* inevitably contains some private data (e.g. my PhD project, and it is linked w/ my Apple ID). So I frequently encounter the issue that I have to explicitly grant write access to process launched from other platforms.
[^*]: update on 2023--02-26: after the collapse of Lily MedTech Inc. at the end Jan. 2023, there is no need for TimeMachine backup on a SMB server hosted on a Linux server. 
[^**]: update on 2023-02-26: the workstation is given to me for personal use by CTO Takashi Azuma, upon the dismiss of Lily MedTech Inc.

## Method

### Install the Linux server

I choose to try the latest *Ubuntu Server 22.04.2 LTS* ver.

1. Get the ISO image from the official site.
2. Prepare a bootable USB stick from the image by following the [tutorial](https://ubuntu.com/tutorials/create-a-usb-stick-on-macos#1-overview). (The macOS utility [balenaEtcher](https://www.balena.io/etcher/) is utilized).
3. Install the Linux server, by inserting the prepared bootable USB[^9] onto the workstation. Choose to reboot from the USB (press F2/F10/F12 after power-on depending on different manufactory, to enter to the BIOS), then follow the installation procedure. NOTE, the server ver. of Ubuntu will automatically install OpenSSH utility[^7]. I also choose to install [PowerShell](https://docs.microsoft.com/en-us/powershell/) additionally.

### Configure the Linux server (minimal)

1. Setup SSH key authentication, executing from the client from where one would like to login, via the command `cat ~/.ssh/tth_key.pub | ssh tangt@192.168.52.51 "cat >> ~/.ssh/authorized_keys"`[^8].
2. Update relevant info. of `~/.ssh/config` on the client side and check whether password-less login is workable.
3. Change the timezone accordingly (e.g. `sudo timedatectl set-timezone Asia/Tokyo`).

### Setup data-warehouse on the server

1. Setup the physical disk storage and configure software **RAID** (see note `2022-05-07-a-Linux-disk-setup`).
2. Setup SMB server,  to host central workspace and Time Machine backup.
3. Create appropriate symbolic link for *Workspace4*.
4. Configure bare Git repositories on *Workspace4*.
5. Install the CIFS (Common Internet File System) utilities to mount shared drive from macOS/Windows.

To make the shared drive detectable from macOS (Time Machine Preference panel), one needs to first install [Avahi](http://avahi.org/) (by `sudo apt install avahi-daemon`) to allow domain name resolve (bi-directionally) like `lily-titan.local` (before the installation, `ping lily-titan.local` does NOT resolve name). It starts automatically after installation[^10], and one can check the status w/ `service avahi-daemon status`.

The setup SMB server, first install [samba](https://www.samba.org):

```bash
# check whether samba is installed
apt list --installed samba
# install samba
sudo apt install samba
```

After successful installation one can confirm with the following command:

```bash
tangt@pd-titan:~$ whereis samba
samba: /usr/sbin/samba /usr/lib/x86_64-linux-gnu/samba /etc/samba /usr/share/samba /usr/share/man/man8/samba.8.gz /usr/share/man/man7/samba.7.gz
```

Then, configure samba by following [1]. One need to create a directory for share (in my case, I specify `/mnt/data/Workspace4`). Add the following code block to `/etc/samba/smb.conf`:

```bash
[WKSP4]
	comment = Samba on Ubuntu
	path = /mnt/data/Workspace4
	read only = no
	browsable = yes
```

After the configuration, start the service and update firewall rule to allow the traffic of SMB:

```bash
# restart the service
sudo service smbd restart
# update firewall
sudo ufw allow samba
```

Finally, one need to setup the login account for SMB. When adding samba login user w/ `sudo smbpasswd -a [username]`, it will prompt a dialogue requiring password setting (although it can use different password from the system login password, I choose the same one).

One more thing, if one need to mount shared drive (of macOS/Windows) ONTO the linux system, one must install CIFS utilities, by `sudo apt install cifs-utils`. After successful installation, one can use the following command for the network drive mounting:

```bash
# an example of mount a macOS shared drive onto the linux server
sudo mount -t cifs -o user=lpa //PD-Pisces.local/Workspace3 ~/Workspace3
```

NOTE, to setup a shared drive on macOS, see note `2023-03-01-a-setup-SharedDrive-macOS`.

### Customize CLI workflow (optional)

1. Set the tab size of nano editor by `echo "set tabsize 4" > ~/.nanorc`.
2. Tailor `tmux` (see my git repo. of `dotfiles`.
3. Install custom `PowerShell` profile (see my git repo. of `dotfiles`.
4. Install network tools `sudo apt install net-tools` (which provides `ifconfig`).

[^7]: If using Ubuntu desktop ver., one has to manually install OpenSSH via `sudo apt install openssh-server`.
[^8]: When using Ubuntu desktop ver.,  `.ssh` folder does not exist by default, so one has to command more elaborately by replacing the command in double quote by `mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys`.
[^9]: To reuse the USB as normal portable storage, follow the instruction of note `2022-03-13-d-USB-Drive`.
[^10]: Ubuntu desktop ver. usually comes w/ Avahi pre-installed.

## Result

A workflow consisting of the following features are constructed.

- Time Machine, for *Lily-Acrux*
- Workspace4 sharing, w/ RAID 10
- Mount other shared drive onto the server
- Customized `tmux` + `pwsh` based CLI

## Discussion

I have spent quit a lot of effort during Nov. to Dec. of 2021 to setup the Linux server (my first attempt). It was working fine all the way. Besides serving as a file server, I also configured MATLAB w/ GPU computation ability supported by CUDA (however, it turns out that it is rarely utilized since newer resource is available for real work). I have also tried VNC based remote interaction, as well as X11 forwarding (however, neither of them has been actively utilized for real work). After an update of Ubuntu on 2022-07-08, I encountered system crashes upon SMB access, although it is recovered (by accident, after a manual Time Machine backup on 2022-07-09), I find the package management is out of control (mainly due to tweaking NVIDIA driver) and I confirmed that MATLAB GPU computation no longer work. Therefore, I decided it is a chance to re-work the configuration of the server, gain some bonus functionality (RAID), and remove some unnecessary functionality (CUDA). After some focused work during the week 7/11–15, it is now works like a charm, again.

At the end of Feb. 2023, after restoring the Dell workstation (now as a private-use resource), I reinstalled the system, and configured MATLAB computation w/ CUDA. Now, the driver issue is NOT a problem for me, and the related technic doc can be found in note `2023-02-28-a-MATLAB-on-Linux-setup`.

## Reference

1. [Install and Configure samba](https://ubuntu.com/tutorials/install-and-configure-samba#1-overview)

## Appendix

### Tips for working in Command Line

In my workflow, I usually needs to work on all macOS, Windows and Linux platform, in the CLI environment (via SSH), there are some needs to check those info. such as file size, folder size, disk usage etc., that are taken as granted on a GUI environment. This section contains tips on using relevant CLI-tools:
- use `lscpu` to check CPU info. on Linux
- use `lspci` to check PCIe device info. (`lspci | grep VGA` extracts the GPU info.)
- use `du -sh [folder_name]` to estimates the size of folders (option `-s` stands for *summary*—display only a total for each argument, option `-h` stands for *human-readable*)
- use `df -T` to show the disk usage along with each block's filesystem type (e.g., `xfs`, `ext2`, `ext3`, `btrfs`, etc.)

