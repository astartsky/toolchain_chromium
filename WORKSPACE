# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    name = "slamdev_toolchain_chromium",
)

load(":internal_deps.bzl", "toolchain_chromium_internal_deps")

# Fetch deps needed only locally for development
toolchain_chromium_internal_deps()

load("//chromium:repositories.bzl", "chromium_register_toolchains", "toolchain_chromium_dependencies")

# Fetch our "runtime" dependencies which users need as well
toolchain_chromium_dependencies()

chromium_register_toolchains(
    name = "chromium1178",
    chromium_revision = "1178",
    sha256 = {
        "mac-arm64": "f9c151bc5e8868a1a8493a4704a5d701462f9094ef1f915417ad0919f34386cb",
        "mac": "85b29d14241b3236805e6aa458b79f3a1bdff57c45855bed553ef11d5e15d181",
        "linux": "3467146abacd8fae1f2af72f5b51635b1e4e050e67a3ab4589a8cabf6937b8b5",
    },
)

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()
