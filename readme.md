# Running native code on Hue Bridge 2.X

Once rooted, the OpenWrt-based Hue Bridge 2.X can run external binaries compiled for it. 

**Note** if anything goes wrong, it should be possible to undo any damage with a factory reset.

## Prerequisites
* Root bridge using the [pin2pwn method](http://colinoflynn.com/2016/07/getting-root-on-philips-hue-bridge-2-0/)
* Create an ssh key pair for dropbear on dev machine and manually copy public key onto Bridge over serial terminal, followed by a command to install it. Store private key locally in ~/.ssh/id_rsa_hue
  ```bash
  echo "PUBLIC KEY CONTENTS" > /root/key
  ssh-factory-key -r /root/key
  ```
* Create links for shared libraries if they will be used
* Ensure `opkg` is available on Bridge. Use instructions below to install if missing (later firmware removes binary)
* Docker must be installed on dev machine

## Building and executing custom C binary
```bash
./build
```

If successful, this will 
* download the appropriate Docker image with the OpenWrt SDK installed
* copy source and cross compile into package
* copy built package to working directory and across to Bridge via scp
* install package onto Bridge

Then via ssh using root or new user account, the binary can be executed directly on the Bridge, it will be in the PATH.

## Additional instructions

### Restore Opkg removed in new firmware
It is likely necessary to set up missing library links before the copied binary will execute.

#### Prerequisites
* `squashfs` (install on a Mac using `brew install squashfs`)

* Download https://archive.openwrt.org/chaos_calmer/15.05.1/ar71xx/generic/openwrt-15.05.1-ar71xx-generic-root.squashfs
* Extract filesystem 
  ```bash
  unsquashfs openwrt-15.05.1-ar71xx-generic-root.squashfs
  ```
* Modify squashfs-root/etc/opkg.conf to remove check signature option.  
  This seems necessary since the Hue build of OpenWrt is custom and won't have matching build signatures.
  ```diff
  - option check_signature 1
  ```
* Copy binary and configuration to Bridge
  ```bash
  scp -i ~/.ssh/id_rsa_hue squashfs-root/bin/opkg root@Philips-hue.local:/bin
  scp -i ~/.ssh/id_rsa_hue squashfs-root/etc/opkg.conf root@Philips-hue.local:/etc/opkg.conf
  scp -i ~/.ssh/id_rsa_hue squashfs-root/etc/opkg/distfeeds.conf root@Philips-hue.local:/etc/opkg/distfeeds.conf
  ```

The opkg command will now be available on the Bridge

```bash
opkg update
```


### Setup limited user account
It is always a good idea to avoid using the root account as soon as possible on a system. Sudo can also be installed to provide privileged access when needed.

On the bridge, 
* Install user management packages
  ```bash
  opkg install sudo shadow-groupadd shadow-useradd
  ```
* Create group and user and home directory. This will end with a prompt for a new password
  ```bash
  USERNAME=<your own username>
  groupadd --system sudo
  useradd -s /bin/ash -G sudo $USERNAME
  mkdir /home/$USERNAME
  chown $USERNAME /home/$USERNAME
  passwd $USERNAME
  ```
* Configure sudo. Using vi, uncomment the sudo group line
  ```bash
  visudo
  ```
  ```diff
  - # %sudo ALL=(ALL) ALL
  + %sudo ALL=(ALL) ALL
  ```

It should now be possible to log in over SSH using the new username and password.

### Create links for shared libraries
Some library files are not found with the same names expected by a standard OpenWrt Chaos Calmer 15.05.1 build. This prevents most packages (and in fact opkg itself) from executing. However, it appears the libraries are included with the system.

Thanks to the instructions found on [blog.andreibanaru.ro](https://blog.andreibanaru.ro/2018/03/27/philips-hue-2-1-enabling-wifi/) for this step. It is extended here to include all shared libraries.

* SSH into the Bridge and run the following commands
  ```bash
  cd /lib
  ln -s libm-1.0.14.so libm.so.0
  ln -s libuClibc-1.0.14.so libc.so.0
  ln -s libutil-1.0.14.so libutil.so.0
  ln -s libdl-1.0.14.so libdl.so.0
  ln -s libcrypt-1.0.14.so libcrypt.so.0
  ln -s libpthread-1.0.14.so libpthread.so.0
  ln -s librt-1.0.14.so librt.so.0
  ln -s libuClibc-1.0.14.so libuClibc.so.0
  ```


## References
https://github.com/Tristan79/HUEHack

https://blog.andreibanaru.ro/2018/03/27/philips-hue-2-1-enabling-wifi/

http://colinoflynn.com/2016/07/getting-root-on-philips-hue-bridge-2-0/

https://github.com/Rocka84/pushing-hue

https://www.gargoyle-router.com/old-openwrt-coding.html

https://openwrt.org/docs/guide-developer/obtain.firmware.sdk

https://openwrt.org/docs/guide-developer/packages
