"""Create a repository to hold the toolchains

This follows guidance here:
https://docs.bazel.build/versions/main/skylark/deploying.html#registering-toolchains
"
Note that in order to resolve toolchains in the analysis phase
Bazel needs to analyze all toolchain targets that are registered.
Bazel will not need to analyze all targets referenced by toolchain.toolchain attribute.
If in order to register toolchains you need to perform complex computation in the repository,
consider splitting the repository with toolchain targets
from the repository with <LANG>_toolchain targets.
Former will be always fetched,
and the latter will only be fetched when user actually needs to build <LANG> code.
"
The "complex computation" in our case is simply downloading large artifacts.
This guidance tells us how to avoid that: we put the toolchain targets in the alias repository
with only the toolchain attribute pointing into the platform-specific repositories.
"""

# Add more platforms as needed to mirror all the binaries
# published by the upstream project.
PLATFORMS = {
    "Mac_Arm": struct(
        os = "mac",
        filename = "mac-arm64",
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:arm64",
        ],
    ),
    "Mac": struct(
        os = "mac",
        filename = "mac",
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_64",
        ],
    ),
    "Linux_x64": struct(
        os = "linux",
        filename = "linux",
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
}

def _toolchains_repo_impl(repository_ctx):
    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """# Generated by toolchains_repo.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@slamdev_toolchain_chromium//chromium:toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.chromiuminfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@slamdev_toolchain_chromium//chromium:toolchain_type"],
    incompatible_use_toolchain_transition = True,
)
"""
    repository_ctx.file("defs.bzl", starlark_content)

    build_content = """# Generated by toolchains_repo.bzl
#
# These can be registered in the workspace file or passed to --extra_toolchains flag.
# By default all these toolchains are registered by the chromium_register_toolchains macro
# so you don't normally need to interact with these targets.

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])

"""

    for [platform, meta] in PLATFORMS.items():
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:chromium_toolchain",
    toolchain_type = "@slamdev_toolchain_chromium//chromium:toolchain_type",
)
""".format(
            platform = platform,
            name = repository_ctx.attr.name,
            user_repository_name = repository_ctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    # Base BUILD file for this repository
    repository_ctx.file("BUILD.bazel", build_content)

toolchains_repo = repository_rule(
    _toolchains_repo_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {
        "user_repository_name": attr.string(doc = "what the user chose for the base name"),
    },
)
