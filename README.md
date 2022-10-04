pam_sauron 🌋🔒🪞
==
The provided [PAM module](https://www.redhat.com/sysadmin/pluggable-authentication-modules-pam) can be used to introduce facial authentication as a PAM mode of authentication by making use of an Intel RealSense depth-sensing camera.


https://user-images.githubusercontent.com/61861965/193917430-f35d8108-5ca9-4187-b869-2566104063be.mp4




Requirements
==
* A Linux system using [PAM](https://github.com/linux-pam/linux-pam/)
* An Intel RealSense F4XX-series depth-sensing camera (such as the [RealSense F455](https://www.intel.com/content/www/us/en/products/sku/212561/intel-realsense-id-solution-f455/specifications.html))
    * TXXX-series RealSense solutions are incompatible, as they offload facial recognition to the host
    * Camera should be running firmware `F450_4.0.0.37`
* The [Intel RealSenseID library](https://github.com/IntelRealSense/RealSenseID)
* [Zig 0.9+ ⚡](https://ziglang.org/download/)

Caveats
==
**Treat this package as a neat toy intended for machines with low physical security requirements.**

* This does **not** (presently) prompt for any user input before initiating the facial authentication request. Without additional factors, this could introduce a security hole where `pam_sauron` is invoked to gain privileged access without human confirmation. 
* This does **not** presently make use of the RealSense library's [Secure Communication mode](https://github.com/IntelRealSense/RealSenseID#secure-communication), where a depth sensing device is paired to the host via public/private keys. That means that an attacker could trivially replace a `pam_sauron` user's depth sensing camera (or edit the existing camera's on-device facial pattern database/update enrollment) to gain privileged access. 

Intel RealSense Installation
==
Step 1: Install RealSense ID library 
--
Clone this repository and initialize its submodules. The RealSense library is provided as a submodule, checked out at tag `v0.21.0`:

```sh
git clone https://github.com/l1na-forever/pam_sauron.git
cd pam_sauron
git submodule update --init 
```

Next, build the library. A Makefile target `rsid` is provided for convenience:

```sh
make rsid
```

Finally, copy the library `librsid_c.so` to a location on your library path (the RealSense library does not provide an install target):

```sh
sudo install -m 755 deps/RealSenseID/build/lib/librsid_c.so /usr/lib/librsid_c.so
```

Step 2: Prepare camera
--
The depth-sensing camera must be updated to a firmware version compatible with the particular version of the RSID library being used. In pam_sauron's case, the `v0.21.0` release (firmware version `F450_4.0.0.37`) is used. If you've already been using your camera for facial authentication, you can skip this step. If the sample applications built in the submodule's directory already appear to function, you can skip this step.

Using the built `deps/RealSenseID/tools/bin/rsid-fw-update` executable, bring your camera up to date to the latest firmware (downloaded from the [RealSense releases page](https://github.com/IntelRealSense/RealSenseID/releases). Each update must be applied step-by-step (rather than flashing directly to the newest version). If the firmware file won't apply, try the opposite SKU variant (SKU1/SKU2). For example, to upgrade a retail F455 camera of SKU1 variety to compatible firmware:

```sh
cd deps/RealSenseID/build
sudo bin/rsid-fw-update --port /dev/ttyACM0 --force-version --file ~/Downloads/F450_2.8.0.7_SIGNED.bin
sudo bin/rsid-fw-update --port /dev/ttyACM0 --force-version --file ~/Downloads/F450_3.1.0.29_SKU1_SIGNED.bin
sudo bin/rsid-fw-update --port /dev/ttyACM0 --force-version --file ~/Downloads/F450_4.0.0.37_SKU1_SIGNED.bin
```

You should be able to connect to the camera using the `bin/rsid-cli` tool after firmware flashing completes.

Step 3: Enroll a user
--
Once the camera's firmware is in sync with the RSID library, enroll your face using the CLI tool:

```sh
cd deps/RealSenseID/build
sudo bin/rsid-cli /dev/ttyACM0
```

Enter `e` to begin enrollment. The enrolled user id must match your Linux username exactly (e.g., match the output of `whoami`). Afterwards, enter `a` to verify enrollment was successful. Use `q` to quit the CLI tool. Faceprints are stored on the device itself.

pam_sauron Installation
==
Step 1: Install pam_sauron
--
From this repository's root, build and install the PAM module:

```sh
make
sudo make install 
```

Step 2: Add pam_sauron to PAM configuration
--
Once the PAM module has been installed, it can be used as would any other PAM-based authentication mechanism. Read more on [the PAM configuration file](https://www.redhat.com/sysadmin/pam-configuration-file), and take a look at `man pam`. 

As an example, to add facial authentication as an acceptable authentication for (just) `sudo`, you might update `/etc/pam.d/sudo`:

```
#%PAM-1.0
# Attempt to authenticate via RealSense ID first
auth            sufficient      pam_sauron.so

auth            include         system-auth
account         include         system-auth
session         include         system-auth
```

The "`sufficient`" directive indicates that facial authentication alone will authenticate the user for `sudo`, but allows the authentication flow to continue to other mechanisms (entering your password) if facial authentication fails. For example, given the above configuration, a facial authentication failure may produce the following output and prompt:

```
$ sudo whoami
Authenticating via RSID...
Authentication failed
Password: 
```

Whereas a successful facial authentication would produce output similar to:

```
$ sudo whoami
Authenticating via RSID...
Authenticated 'lina'!
root
```

Troubleshooting
==
My recommendation is to make sure everything seems to be working right with the RealSense samples/tools first. If the samples/tools aren't working, your camera's firmware is likely not flashed to the version corresponding to the library (see above instructions). Oh, also, the module is hardcoded to `/dev/ttyACM0`; if your device happens to *not* be on `/dev/ttyACM0`, fork the package and update `pam_sauron.zig` (or cut me a feature request :^).

Still, this is niche enough you can probably just cut me an issue. No promises on wrangling RealSense issues, though.

FAQ
==
Q: Can pam_sauron detect masks?
--
Yep:



https://user-images.githubusercontent.com/61861965/193917403-51155dcd-2166-485a-bf9b-0fa37a9d9034.mp4



License
==
Copyright © 2022 Lina

Permission to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software (the "Software"), subject to the following conditions:

The persons making use of this "Software" must furnish the nearest cat with gentle pats, provided this is acceptable to both parties (the "person" and the "cat"). Otherwise, water a plant 🪴
