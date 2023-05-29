---
When:
- initial creation on 2022-02-25
- last update on 2023-03-02
Tags:
- #Linux, #MATLAB, #CUDA
---

# Install MATLAB on Linux server

## The issue

Installing a software on Windows/macOS (even on a desktop ver. Ubuntu) is easy—just using the GUI and follow the dialogues. Installing a CLI software via the package management tool (e.g. `choco`,  `brew`, `apt`) is also easy in modern life. However, installing a proprietary software that is mainly designed to be used in desktop environment on a *headless* Linux server is NOT a easy story. Besides, there is further requirement that MATLAB on Linux server should be able to utilize the CUDA-enabled NVIDIA GPU.

It takes me quite a lot of time to tackle this issue. Initial attempt can be tracing back to 2021-12-13.

## Method

### Install NVIDIA driver

One of the appealing point of the Linux server *PD-Titan* (over my favorite Macs) is that it has a CUDA-enabled GPU (although a little bit old from the standard of 2023). I would like to utilize the GPU computation power to speed up my research. The easiest way to leverage CUDA is via MATLAB.

The first hurdle is to install NVIDIA driver on Linux server. This may sounds absurd for a Linux guru, but NVIDIA driver does not come pre-installed w/ Ubuntu server, and there are some pitfalls that newcomer would easily fall in.

To install the NVDIDA driver, one use the following commands:

```bash
# check the devices that need drivers (command `ubuntu-drivers` comes along with a fresh Ubuntu installation)
tangt@pd-titan:~$ ubuntu-drivers devices
== /sys/devices/pci0000:00/0000:00:03.0/0000:07:00.0 ==
modalias : pci:v000010DEd000017C2sv000010DEsd00001132bc03sc00i00 
vendor   : NVIDIA Corporation
model    : GM200 [GeForce GTX TITAN X]
driver   : nvidia-driver-470-server - distro non-free
driver   : nvidia-driver-470 - distro non-free
driver   : nvidia-driver-525 - distro non-free recommended
driver   : nvidia-driver-390 - distro non-free
driver   : nvidia-driver-515-server - distro non-free
driver   : nvidia-driver-418-server - distro non-free
driver   : nvidia-driver-450-server - distro non-free
driver   : nvidia-driver-515 - distro non-free
driver   : nvidia-driver-525-server - distro non-free
driver   : nvidia-driver-510 - distro non-free
driver   : xserver-xorg-video-nouveau - distro free builtin
# install the appropriate driver (although one can use `sudo ubuntu-drivers autoinstall`, I do not like such kind of "muddy" command)
sudo apt install nvidia-driver-525-server
```

NOTE, the default GPU driver (for NVIDIA GPU) that comes w/ a fresh installation of Ubuntu server is [nouveau](https://nouveau.freedesktop.org), which may interfere w/ the "official" NVIDIA driver. Therefore, one needs to disable it (see [1]):

```bash
# check the status of the nouveau module
lsmod | grep nouveau
# add the config to block nouveau
echo 'blacklist nouveau' | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
echo 'options nouveau modeset=0' | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
# update initramfs images
update-initramfs -u
# reboot
sudo shutdown -r now
```

After the reboot, check whether the NVIDIA driver is working properly:

```bash
# confirm the success of installation (NOTE, `nvidia-smi` command only be available after the installation)
tangt@pd-titan:~$ nvidia-smi
Thu Mar  2 11:06:22 2023       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 470.161.03   Driver Version: 470.161.03   CUDA Version: 11.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  Off  | 00000000:07:00.0 Off |                  N/A |
| 17%   55C    P0    66W / 250W |      0MiB / 12210MiB |      1%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+

# optionally, using either one of the following commands to check the actual active driver
sudo lshw -c display
lsmod | grep nvidia
```

### Install X Forwarding tools (optional)

Although, X Forwarding is NOT necessary for using MATLAB on Linux server (which usually runs in CLI environment), it provides additional convenience at some scenarios.

The related tools can be installed by `sudo apt install x11-apps`, which provides utilities such as `xclock`, `xeyes` for easy test. When using `ssh [-X | -Y] pd-titan.local` to log onto the server, running `xclock ` will result a X11 window of clock app launching on the *guest* machine (in my case, the macOS). Further more, by properly configure the `~/.ssh/config` file on the guest, one do not need to specify options, such as `-X` (see another dedicated note).

### Install VNC (optional)

Actually in my original plan, VNC is NOT necessary for the workflow. However, the **activation** process of MATLAB on a headless server just driven me crazy. Finally, I have to resort the VNC solution to provide a GUI environment for the *online activation dialogue of MATLAB*.

I followed [2] to setup the VNC:

```bash
# install Xfce—the open-source desktop environment for Linux
sudo apt install xfce4 xfce4-goodies
# insatll the VNC server
sudo apt install tightvncserver
```

Then, configure the VNC server:

```bash
# run the following for the first time will be prompted for password setup
vncserver
# Output: (I chose to use the same as the system login password)
You will require a password to access your desktops.

Password:
Verify:

# Output
Would you like to enter a view-only password (y/n)? n
xauth:  file /home/sammy/.Xauthority does not exist

New 'X' desktop is your_hostname:1

Creating default startup script /home/sammy/.vnc/xstartup
Starting applications specified in /home/sammy/.vnc/xstartup
Log file is /home/sammy/.vnc/your_hostname:1.log
```

The initialization would launch a default server instance on ==port 5901== (called the *display port*). Then configure the VNC server:

```bash
# close the instance launched by the initialization
vncserver -kill :1
# create a xstartup file and add approprite instructions
# - tell VNC’s GUI framework to read the server user’s .Xresources file
# -- .Xresources is where a user can make changes to certain settings of the graphical desktop, like terminal colors, cursor themes, and font rendering.
# - tells the server to launch Xfce
tangt@pd-titan:~/tmp$ cat << EOF | tee -a ~/.vnc/xstartup
> #!/bin/bash
> xrdb $HOME/.Xresources
> startxfce4 &
> EOF
# make it executable
chmod +x ~/.vnc/xstartup
```

After all those setup, one can launch the VNC server. NOTE, the tutorial [2] recommends one to use ssh tunneling to access the VNC, for example:

```bash
# use ssh port forwarding to tunneling the VNC port to localhost:59000
tpp@PD-Pisces ~ % ssh -L 59000:localhost:5901 tangt@pd-titan.local    
# launch the VNC server at the Linux server
tangt@pd-titan:~$ vncserver -localhost

New 'X' desktop is pd-titan:1

Starting applications specified in /home/tangt/.vnc/xstartup
Log file is /home/tangt/.vnc/pd-titan:1.log
```

Finally, one can access the server in a GUI environment by using a VNC viewer. In the case of macOS, one can utilize the built-in viewer, accessed from "Finder.app > Go > Connect to Server".

![](./assets/connect-to-server.png)(connet to server)

![](./assets/VNC-viewer-macOS.png)(macOS built-in VNC viewer)

![](./assets/VNC-desktop-on-server.png)(VNC desktop on server)

### Install MATLAB

NOTE, if VNC is installed in advance, one can just use the *normal* GUI-based MATLAB installer. However, this note documents the hard-core process of installing MATLAB on a headless server.

To install the MATLAB on Linux server from the CLI environment, one needs to obtain the ISO (optical disc image) file of MATLAB[^1]. Then mount the ISO image by:
```bash
# NOTE, one needs to first create the directory /media/matlab
sudo mount -t iso9660 -o loop ~/tmp/R2021b_Update_5_Linux.iso /media/matlab
```

Then execute the installation script (see [3, 4]:
```bash
# first, copy the file /media/matlab/installer_input.txt to user's directory, since the ISO directory is read-only
cp /media/matlab/installer_input.txt ~/tmp/
# fill in appropriate fileds of installer_input.txt
nano installer_input.txt
# execute the installer
/media/matlab/install -inputFile ~/tmp/installer_input.txt
```

NOTE, do NOT use `sudo` to call the MATLAB installer, since **the root user does NOT have a *display* variable set up** [7], which would cause trouble (eventually, one will encounter a scenario where a X window is necessary). Although, by not using `sudo` one will encounter permission issue of writing to `/usr/local`, one can walk-around by `sudo chown [username:usergroup] /usr/local/MATLAB/R2021b` to grant permission.

After successful installation, one needs to *activate* MATLAB, which is another hurdle. Although, there is tutorial about this issue [5, 6], I have tried (w/ license file `license.lic` downloaded from my MathWorks account center):
```bash
# attempt for "silent" activation
/media/matlab/activate_matlab.sh -propertiesFile ~/tmp/activate.ini
# Output:
Silent activation succeeded.
```

Regardless the sign of "success", when I execute `/usr/local/MATLAB/R2021b/bin/matlab`, I am stuck w/ 
```bash
# Output:
---------------------------------------------------------------------------
Error: Activation cannot proceed. You may either:
1. Set an X11 display, and restart the activation process
2. Use the silent activation feature
3. Activate using the license center
---------------------------------------------------------------------------
```

In an earlier trail of 2021-12-14, the interactive activation dialogue window prompted out through X forwarding, when calling `matlab`, but it is not true for this time. Finally, I decided to resort to the VNC solution.

The last step, I created a symbolic link `sudo ln -sv /usr/local/bin/matlab /usr/local/MATLAB/R2021b/bin/matlab`, and then addressed the permission issue by `sudo chown --no-dereference [symlink]` (NOTE, the option makes the ownership of the symbolic link be changed, rather than the pointed target).

[^1]: the ISO file is not available for student license user, so I obtained it using company's account (although, I used my own license).

## Appendix

If something go south, one can always delete the NVIDIA driver by:
```bash
sudo apt remove nvidia-driver-525-server
```

NOTE, there is an unresolved issue of using X Forwarding on macOS w/ MATLAB installed on a remote server [8], just leave it as it is at this moment.

To update MATLAB on Linux server, refer to [9], but the best approach is to resort to VNC.

NOTE, the options `-nosplash`, `-nodesktop`, `-bach` are helpful for MATLAB in remote server.

BE CAREFUL, that when X Forwarding is established during the SSH session, it will render the ability of detaching a session using `tmux` unusable. In this case, one can NOT successfully logout from the remote session before the MATLAB process finishes.

## Reference

1. [Ubuntu 20.04 LTS : Install NVIDIA Driver : Server World](https://www.server-world.info/en/note?os=Ubuntu_20.04&p=nvidia&f=1)
2. [How to Install and Configure VNC on Ubuntu 22.04  | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-22-04)
3. [How to install Matlab without GUI](http://installfights.blogspot.com/2016/11/how-to-install-matlab-without-gui.html)
4. [Install Noninteractively- MATLAB & Simulink](https://www.mathworks.com/help/install/ug/install-noninteractively-silent-installation.html)
5. [What is the format for the Activate.ini text file? – PerkinElmer](https://informatics-support.perkinelmer.com/hc/en-us/articles/4408239551252-What-is-the-format-for-the-Activate-ini-text-file-)
6. [How do I activate MATLAB or other MathWorks Products? - MATLAB Answers - MATLAB Central](https://www.mathworks.com/matlabcentral/answers/99457-how-do-i-activate-matlab-or-other-mathworks-products)
7. [Why do I receive "terminate called after throwing an instance of '(anonymous namespace)::DisplayError' what(): N... - MATLAB Answers - MATLAB Central](https://www.mathworks.com/matlabcentral/answers/527179-why-do-i-receive-terminate-called-after-throwing-an-instance-of-anonymous-namespace-displayerro#answer_433899)
8. [M1 black background · Issue #31 · XQuartz/XQuartz · GitHub](https://github.com/XQuartz/XQuartz/issues/31)
9. [Update MathWorks Software on Offline Computer- MATLAB & Simulink](https://www.mathworks.com/help/install/ug/update-mathworks-software-on-offline-machine.html)
