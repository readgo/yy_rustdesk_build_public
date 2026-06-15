#!/usr/bin/env python3
"""Patch magnum-opus build.rs to also search include/opus/ for headers.

vcpkg may install opus headers flat in include/ but magnum-opus's opus_ffi.h
includes <opus/opus_multistream.h> which expects include/opus/ subdirectory.

Run this after cargo fetch, before cargo build.
"""
import os, glob

# Find magnum-opus checkout in cargo git cache
magnum_dirs = glob.glob(
    os.path.expanduser("~/.cargo/git/checkouts/magnum-opus-*/5cd2bf9")
)
if not magnum_dirs:
    print("magnum-opus checkout not found (will be fetched by cargo)")
    exit(0)

build_rs = os.path.join(magnum_dirs[0], "build.rs")
if not os.path.exists(build_rs):
    print(f"build.rs not found at {build_rs}")
    exit(0)

with open(build_rs) as f:
    content = f.read()

if "all_include_paths" in content:
    print("Already patched")
    exit(0)

# The code to replace (note: { is on next line in actual file):
#     for dir in include_paths {
#         b = b.clang_arg(format!("-I{}", dir.display()));
#     }
old_block = 'for dir in include_paths {\n        b = b.clang_arg(format!("-I{}", dir.display()));\n    }'

new_block = """let mut all_include_paths = include_paths.clone();
            for dir in &include_paths {
                all_include_paths.push(dir.join("opus"));
            }
            for dir in all_include_paths {
                b = b.clang_arg(format!("-I{}", dir.display()));
            }"""

if old_block not in content:
    print(f"Pattern not found in build.rs")
    print(f"Looking for: {repr(old_block[:60])}...")
    # Show lines around 'for dir' for debugging
    for i, line in enumerate(content.split('\n')):
        if 'for dir' in line and 'include' in line:
            print(f"  Line {i+1}: {line!r}")
            # Show next line too
            lines = content.split('\n')
            if i+1 < len(lines):
                print(f"  Line {i+2}: {lines[i+1]!r}")
    exit(1)

content = content.replace(old_block, new_block)
with open(build_rs, 'w') as f:
    f.write(content)
print(f"Patched magnum-opus build.rs ({magnum_dirs[0]})")
