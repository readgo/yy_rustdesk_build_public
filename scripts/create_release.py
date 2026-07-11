#!/usr/bin/env python3
"""Create a GitHub Release and upload APK."""
import json, os, sys, urllib.request, urllib.error

tag = sys.argv[1]
version = sys.argv[2]
repo = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("GITHUB_REPOSITORY", "")
token = sys.argv[4] if len(sys.argv) > 4 else os.environ.get("GITHUB_TOKEN", "")

if not repo or not token:
    print("ERROR: Missing repo or token")
    sys.exit(1)

notes = (
    "YYDesk v%s Android APK\n\n"
    "### 安装\n"
    "下载 APK 后，在 Android 设备上安装即可。\n"
    "首次安装需在系统设置中允许「未知来源应用」。\n\n"
    "### 架构\n"
    "- arm64-v8a (64-bit)\n"
    "- armeabi-v7a (32-bit)"
) % version

api = "https://api.github.com/repos/%s" % repo
headers = {
    "Authorization": "token %s" % token,
    "Accept": "application/vnd.github.v3+json",
}

# 1. Create release
payload = {
    "tag_name": tag,
    "name": "YYDesk v%s" % version,
    "body": notes,
    "draft": False,
    "prerelease": False,
}

req = urllib.request.Request(
    "%s/releases" % api,
    data=json.dumps(payload).encode(),
    headers=headers,
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())
        release_id = data.get("id")
        print("Release created: ID=%s, tag=%s" % (release_id, data.get("tag_name")))
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print("Create release failed: %s %s" % (e.code, e.reason))
    print("Response: %s" % body[:300])
    if e.code == 422:
        # Tag already has a release - find and update it
        try:
            req2 = urllib.request.Request(
                "%s/releases/tags/%s" % (api, tag), headers=headers
            )
            with urllib.request.urlopen(req2, timeout=15) as resp2:
                existing = json.loads(resp2.read())
                release_id = existing.get("id")
                print("Found existing release ID=%s, updating body" % release_id)
                req3 = urllib.request.Request(
                    "%s/releases/%s" % (api, release_id),
                    data=json.dumps({"body": notes}).encode(),
                    headers=headers,
                    method="PATCH",
                )
                with urllib.request.urlopen(req3, timeout=15) as resp3:
                    print("Body updated")
        except Exception as e2:
            print("Could not find/update existing release: %s" % e2)
            release_id = None
    else:
        release_id = None
except Exception as e:
    print("Unexpected error: %s" % e)
    release_id = None

# 2. Upload APK
if release_id:
    workspace = os.environ.get("GITHUB_WORKSPACE", "")
    for base_dir in [workspace, os.path.expanduser("~")]:
        dist_dir = os.path.join(base_dir, "dist") if base_dir else ""
        if not dist_dir or not os.path.isdir(dist_dir):
            continue
        for fname in os.listdir(dist_dir):
            if not fname.endswith(".apk"):
                continue
            fpath = os.path.join(dist_dir, fname)
            size = os.path.getsize(fpath)
            print("Uploading: %s (%s bytes)" % (fname, size))
            with open(fpath, "rb") as f:
                asset_headers = dict(headers)
                asset_headers["Content-Type"] = "application/vnd.android.package-archive"
                req3 = urllib.request.Request(
                    "%s/releases/%s/assets?name=%s" % (api, release_id, fname),
                    data=f.read(),
                    headers=asset_headers,
                    method="POST",
                )
                with urllib.request.urlopen(req3, timeout=120) as resp3:
                    result = json.loads(resp3.read())
                    print("  Uploaded: %s" % result.get("name"))
else:
    print("SKIP: no release ID to upload to")
    sys.exit(1)
