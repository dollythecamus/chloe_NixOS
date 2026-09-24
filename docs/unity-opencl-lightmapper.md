# Unity GPU light baking fails: OpenCL ICD loader missing from the system

Status: **applied.** `hardware/nvidia.nix` carries
`hardware.graphics.extraPackages = [ pkgs.ocl-icd ]` (commit `c76adf0`) and
`nixos-rebuild build --flake ~/nixos#chloe-laptop` exits 0. The `switch` is the operator's step;
the end-to-end bake is not verified yet. The durable explanation of the mechanism lives in
`~/wiki/concepts/nixos-gpu-and-opencl.md` — this file is the diagnosis record.

Affected: Unity 6000.6.0f1 (installed via Unity Hub 3.19.1, nixpkgs `unityhub` FHS wrapper),
project `~/projects/UnityXR_3DMuseu`, canonical scene `Assets/Museu/Scenes/MuseuNew.unity`.
Host: NixOS 26.05 `chloe-laptop`, NVIDIA RTX 3050 6GB Laptop (GA107, `hardware.nvidia.open = true`),
driver 595.71.05.

## Symptom

`~/projects/UnityXR_3DMuseu/Logs/Editor.log` (2026-09-21, lines 3285-3288):

```
[BakePipeline::Driver] Extracted OOTS snapshot with 189 instances, 101 geometries, 90 meshes, 67 materials, 1 transmission textures, 25 lights, 0 cookies in 80.82ms.
-- Listing OpenCL platforms(s) --
-- Listing OpenCL device(s) --
Light baking could not be started because no valid OpenCL device could be found.
```

Unity enumerated **zero** OpenCL platforms and **zero** devices.

## Root cause

The Progressive **GPU** lightmapper backend is the prebuilt binary
`~/Unity/Hub/Editor/6000.6.0f1/Editor/Data/Tools/libRadeonRays.so`. It has a hard dynamic
dependency on the Khronos OpenCL **ICD loader**:

```
$ ldd .../Editor/Data/Tools/libRadeonRays.so
        libOpenCL.so.1 => not found        <-- nothing provides this anywhere on the system
        libstdc++.so.6 => not found        <-- resolved inside the sandbox, not a problem
```

`libOpenCL.so.1` is **not the NVIDIA driver**. It is the vendor-neutral loader, shipped on NixOS
only by `pkgs.ocl-icd`. On this host no package installs it: `environment.systemPackages` and
`hardware.graphics.extraPackages` both lack it, `ldconfig -p | grep -i opencl` returns nothing,
and `/run/opengl-driver/lib/` contains only `libnvidia-opencl.so*` (the vendor **ICD**, which the
loader is supposed to dlopen — not the loader itself).

Everything on the *vendor* side is already correct — this is not a driver, PATH, or
`hardware.nvidia.open` problem:

- `/run/opengl-driver/etc/OpenCL/vendors/nvidia.icd` exists and contains the absolute path
  `/nix/store/zcy6y082nkq77g9cr0q0ji58732jw5p8-nvidia-x11-595.71.05/lib/libnvidia-opencl.so.1`.
- That vendor ICD is functional: `clinfo` reports `Platform #0: NVIDIA CUDA`,
  `Device #0: NVIDIA GeForce RTX 3050 6GB Laptop GPU`, `OpenCL C 1.2`, `cl_khr_3d_image_writes`,
  compute capability 8.6, driver 595.71.05.
- nixpkgs' `ocl-icd` is built with `--enable-custom-vendordir=/run/opengl-driver/etc/OpenCL/vendors`
  (`pkgs/by-name/oc/ocl-icd/package.nix:30`), i.e. its default vendor search path is already the
  populated NixOS path. No `OCL_ICD_VENDORS` / `OPENCL_VENDOR_PATH` is needed once the loader exists.

**Single missing artifact: the ICD loader.** Confirmed by supplying only that one library, inside
the very FHS sandbox Unity runs in, with no other change:

```
$ LD_LIBRARY_PATH=<ocl-icd>/lib unityhub-fhs-env bash -c 'clinfo -l'
Platform #0: NVIDIA CUDA
 `-- Device #0: NVIDIA GeForce RTX 3050 6GB Laptop GPU
```

## Change applied

`/home/chloe/nixos/hardware/nvidia.nix`, inside the existing `hardware.graphics` attrset:

```nix
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.ocl-icd ];   # OpenCL ICD loader for Unity's GPU lightmapper
  };
```

One correction to the snippet as originally drafted above: the module's formals were
`{config, inputs, ...}` with **no `pkgs` in scope**, so `with pkgs;` would have failed
evaluation. The applied change adds `pkgs` to the formals and uses `[ pkgs.ocl-icd ]`.

Why this is sufficient, and why no `unityhub` override change is needed:

1. `nixos/modules/hardware/graphics.nix:10-13` builds
   `driversEnv = pkgs.buildEnv { paths = [ cfg.package ] ++ cfg.extraPackages; }` and line 134
   symlinks `/run/opengl-driver` to it. `buildEnv` merges each package's `lib/` and `etc/`
   subtrees, so the loader lands at `/run/opengl-driver/lib/libOpenCL.so.1` alongside the
   already-present `etc/OpenCL/vendors/nvidia.icd`.
2. The Unity editor does not run unsandboxed — it runs inside `unityhub-fhs-env`, a bubblewrap
   sandbox. That sandbox hardcodes `/run/opengl-driver/lib` into its `/etc/ld.so.conf` and
   regenerates the search cache at every start
   (`pkgs/build-support/build-fhsenv-bubblewrap/container-init.cc:10-22,36`). Verified inside the
   live sandbox: `/etc/ld.so.conf` lists `/run/opengl-driver/lib`, and `ldconfig -p` there already
   resolves `libnvidia-opencl.so.1` from that directory. `/run` and `/run/opengl-driver` are
   bind-mounted into the sandbox (verified).
3. Therefore the editor's `libRadeonRays.so` resolves `libOpenCL.so.1` from
   `/run/opengl-driver/lib` with **no** changes to `home/programs/unity.nix` and no environment
   variables — including when Unity Hub is launched from the desktop icon.

Switched with `sudo nixos-rebuild switch --flake /home/chloe/nixos#chloe-laptop` (needs the
operator's password; not runnable unattended from a Hermes session). 32-bit support is not
needed — the editor is x86-64 only, so `hardware.graphics.extraPackages32` /
`pkgsi686Linux.ocl-icd` is unnecessary.

### Alternative (equivalent, scoped to Unity instead of system-wide)

Extend the existing override in `/home/chloe/nixos/home/programs/unity.nix` to put the loader in
the sandbox's `/usr/lib`:

```nix
((unityhub.override { extraLibs = p: [ p.ncurses6 p.unzip p.ocl-icd ]; })
```

`extraLibs` feeds `multiPkgs`; `pkgsi686Linux.ocl-icd` evaluates (`ocl-icd-2.3.4`), so the
multiarch build is safe. Strictly unnecessary if `hardware.graphics.extraPackages` is used.

## Temporary workaround without a rebuild (superseded by the applied change)

Kept as a record of how the missing library was isolated, and as a way to test before the switch.
The launcher wrapper appends the outer `LD_LIBRARY_PATH` to
`/usr/lib64:/usr/lib`, and that variable survives bubblewrap into the sandbox, where
`libRadeonRays.so` then resolves `libOpenCL.so.1`.

```bash
# Close Unity Hub and the editor first — resolution happens at process start.
LD_LIBRARY_PATH="$(nix build --no-link --print-out-paths nixpkgs#ocl-icd)/lib" unityhub
# today's literal path (already in the store, no build step):
LD_LIBRARY_PATH=/nix/store/lrflc73bmaz9z2wqyfxdb9d3510y2zv6-ocl-icd-2.3.4/lib unityhub
```

Caveats: the hardcoded store path goes stale on nixpkgs updates; a Hub started from the desktop
icon does not inherit the variable; the editor must already have the variable at startup —
it cannot be injected into a running editor.

## Fallback that needs no OpenCL at all

Lighting window → **Scene** tab → **Lightmapper** → **Progressive CPU**. Works on CPU only.
For this scene (189 instances / 101 geometries / 90 meshes / 67 materials / 25 lights, lightmap
atlas 1024, 40 texels/unit, 512 samples, 2 bounces) expect a long bake on this 12GB laptop, but it
is the only path that works with zero system changes.

## Secondary finding (unrelated to OpenCL, worth fixing)

`MuseuNew.unity` references an external LightingSettings asset by GUID
`94018a98b1adf3db09deec6e44887083`, and no file in the repo carries that GUID — the reference is
dangling. The effective lightmapper setting is therefore the scene-inline
`LightmapSettings.m_LightmapEditorSettings.m_BakeBackend: 2` (Progressive GPU), and the Lighting
window will write changes into the scene rather than into a shared LightingSettings asset.
(`LightingData.asset` itself is present and referenced correctly.)

## Things to watch after the fix

The GPU bake may still fail for memory reasons unrelated to OpenCL: `clinfo` reports
global memory 5.66 GiB and **max single allocation 1.42 GiB** on this 6GB laptop GPU. If the bake
log reports allocation failures or Vulkan/OpenCL out-of-memory, lower the lightmap atlas size or
resolution, or fall back to Progressive CPU.

## Verification commands

```bash
# after the rebuild — host sees the loader next to the vendor ICD
ls -l /run/opengl-driver/lib/libOpenCL.so.1
clinfo | head -5                       # Platform #0: NVIDIA CUDA

# inside the Unity sandbox — the dependency that was missing now resolves
<nixos>/…/unityhub-fhs-env bash -c 'ldd ~/Unity/Hub/Editor/6000.6.0f1/Editor/Data/Tools/libRadeonRays.so | grep -i opencl'
# expect: libOpenCL.so.1 => /run/opengl-driver/lib/libOpenCL.so.1

# end to end — the error line must be gone from the bake log
grep -n "no valid OpenCL device" ~/projects/UnityXR_3DMuseu/Logs/Editor.log
```
