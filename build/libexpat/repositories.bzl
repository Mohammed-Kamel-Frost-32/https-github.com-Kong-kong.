"""A module defining the third party dependency OpenResty"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@kong_bindings//:variables.bzl", "KONG_VAR")

def libexpat_repositories():
    """Defines the libexpat repository"""

    version = KONG_VAR["LIBEXPAT"]
    tag = "R_" + version.replace(".", "_")

    maybe(
        http_archive,
        name = "libexpat",
        url = "https://github.com/libexpat/libexpat/releases/download/" + tag + "/expat-" + version + ".tar.gz",
        sha256 = "d4cf38d26e21a56654ffe4acd9cd5481164619626802328506a2869afab29ab3",
        strip_prefix = "expat-" + version,
        build_file = "//build/libexpat:BUILD.libexpat.bazel",
    )
