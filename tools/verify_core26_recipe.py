"""Verify the effective Snap recipe and metadata extracted from its artifact."""

import argparse
from pathlib import Path

import yaml


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("expanded", type=Path)
    parser.add_argument("metadata", type=Path)
    args = parser.parse_args()
    expanded, metadata = [
        yaml.safe_load(path.read_text(encoding="utf-8"))
        for path in (args.expanded, args.metadata)
    ]
    for document in (expanded, metadata):
        require(document["name"] == "busymark", "Expected the shipping BusyMark snap")
        require(document["base"] == "core26", "Expected the core26 base")
        require(document["confinement"] == "strict", "Expected strict confinement")
        app = document["apps"]["busymark"]
        require(app["command"] == "busymark", "Expected the shipping executable")
        require({"audio-playback", "gsettings"}.issubset(app["plugs"]),
                "Missing playback or GSettings interface")
        require(app["command-chain"] == [
            "snap/command-chain/gpu-2604-wrapper", "snap/command-chain/desktop-launch",
        ], "Unexpected desktop launch chain")
        for plug, provider in (("gnome-core26", "gnome-core26"), ("gpu-2604", "mesa-2604")):
            configuration = document["plugs"][plug]
            require(configuration["interface"] == "content"
                    and configuration["default-provider"] == provider,
                    f"Unexpected provider of the {plug} content plug")
    require(expanded["version"] == metadata["version"], "Snap version differs from recipe")
    require(expanded["platforms"] == {"amd64": {"build-on": ["amd64"], "build-for": ["amd64"]}},
            "Unexpected build platform")
    require(expanded["layout"]["/usr/libexec/glycin-loaders"]["bind"] ==
            "$SNAP/gnome-platform/usr/libexec/glycin-loaders", "Missing Glycin loader layout")
    require("gnome-core26-sdk" in expanded["parts"]["gnome/sdk"]["build-snaps"],
            "Expected the core26 GNOME build SDK")
    require("gnome-core26-sdk" in expanded["parts"]["gnome/cleanup"]["override-prime"],
            "Missing GNOME library cleanup")
    require("mesa-2604" in expanded["parts"]["gnome/gpu/cleanup"]["override-prime"],
            "Missing graphics library cleanup")


if __name__ == "__main__":
    main()
