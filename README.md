# VS Code Server Toolchain Workaround

Starting with VS Code release 1.86, the minimum requirements for the build toolchain of the remote server were raised. The prebuilt servers distributed by VS Code are compatible with Linux distributions based on glibc 2.28 or later.

This toolkit provides a workaround for whose setup does not meet these requirements and you are unable to upgrade the Linux distribution but still want to update VS Code. It ensembles glibc, libstdc++ and patchelf.

Since the directory tree of vscode-server changed from a update, the original patch shell cannot be funcational anymore. However, the original repository is achcieved (https://github.com/npurson/vscode-server-toolchain-workaround), therefore this fork provides the up-to-date patch solution.

## Usage

The following steps have to be executed each time VS Code is updated.

1. Update the VS Code on local.
2. Connect to the remote server and await the download’s completion until the error regarding unsatisfied prerequisites is encountered.
3. Execute the `run.sh` script and check.

## Architecture suitability

The releases after v0.1 is only suitable for systems with x86-64 architecture, those systems on other architectures please try codes archived as v0.1 release. 

## Prerequisites for VS Code

kernel >= 4.18, glibc >=2.28, libstdc++ >= 3.4.25 (gcc 8.1.0), Python 2.6 or 2.7, tar

## References

1. https://code.visualstudio.com/docs/remote/linux#_remote-host-container-wsl-linux-prerequisites
2. https://code.visualstudio.com/docs/remote/faq#_can-i-run-vs-code-server-on-older-linux-distributions
3. https://github.com/npurson/vscode-server-toolchain-workaround

## Workings

### 1. Bypassing the requirements check of VS Code

The following excerpt is from `~/.vscode-server/cli/servers/Stable-$COMMIT_ID/server/bin/helpers/check-requirements.sh`:

```bash
if [ -f "/tmp/vscode-skip-server-requirements-check" ]; then
        echo "!!! WARNING: Skipping server pre-requisite check !!!"
        echo "!!! Server stability is not guaranteed. Proceed at your own risk. !!!"
        exit 0
fi
```

while the `$COMMIT_ID`  is a long string composed of numbers and letters, representing the version number of the program you installed. An example, `~/.vscode-server/cli/servers/Stable-f220831ea2d946c0dcb0f3eaa480eb435a2c1260/server/bin/helpers/check-requirements.sh` as a full address.

Hence, creating the file `/tmp/vscode-skip-server-requirements-check` can skip the requirements check.

### 2. Upgrading glibc and libstdc++ for VS Code

Utilize PatchELF to modify the dynamic linker and RPATH of ELF executables.

Note: The loading priority of the dynamic linker is as follows:

1. RPATH within the ELF
2. LD_LIBRARY_PATH environment variables
3. RUNPATH within the ELF
4. Cache in /etc/ld.so.cache
5. /lib and /usr/lib

### 3. Cheking if the server program can get valid dynamic linkers

The server program is located at

```bash
~/.vscode-server/cli/servers/Stable-$COMMIT_ID/server/node
```

Use `ldd` command to determine wheter the program is well-equiped with new dynamic linkers, as:

```bash
cd ~/.vscode-server/cli/servers/Stable-$COMMIT_ID/server
ldd node
```

If the command retures similar to belows, than you can enjoy your remote coding with vscode:

```bash
[userxxx@hostxxx]$ ldd node
	linux-vdso.so.1 =>  (0x00007ffe78b9d000)
	libdl.so.2 => /path_to_this_repo/glibc-2.30/lib/libdl.so.2 (0x00007faf9b3eb000)
	libstdc++.so.6 => /path_to_this_repo/gcc-10.3.0/lib64/libstdc++.so.6 (0x00007faf9b01c000)
	libm.so.6 => /path_to_this_repo/glibc-2.30/lib/libm.so.6 (0x00007faf9acdd000)
	libgcc_s.so.1 => /path_to_this_repo/gcc-10.3.0/lib64/libgcc_s.so.1 (0x00007faf9aac5000)
	libpthread.so.0 => /path_to_this_repo/glibc-2.30/lib/libpthread.so.0 (0x00007faf9a8a4000)
	libc.so.6 => /path_to_this_repo/glibc-2.30/lib/libc.so.6 (0x00007faf9a4e7000)
	/path_to_this_repo/glibc-2.30/lib/ld-linux-x86-64.so.2 => /lib64/ld-linux-x86-64.so.2 (0x000055b207558000)
```

#### 3.1 Fix symbolic links

On some cases, the symbolic links would be missing and you probablely gets a return likes:

```bash
[userxxx@hostxxx]$ ldd node
./node_t: error while loading shared libraries: /path_to_this_repo/glibc-2.30/lib/libdl.so.2: file too short
```

Charecterized as a `file too short` notice. In this case you need to run the fix program on two directories to fix the symbolic links:

```bash
cd /path_to_this_repo/glibc-2.30/lib
bash /path_to_this_repo/fix.sh
cd /path_to_this_repo/gcc-10.3.0/lib64
bash /path_to_this_repo/fix.sh
```

After that you can re-execute the bash scripts of step 3 to apply the fixes.
