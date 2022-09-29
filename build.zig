const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const version = b.version(1, 0, 0);

    const lib = b.addSharedLibrary(
        "sauron",
        "src/main.zig",
        version,
    );
    // b.lib_dir = "/lib/security";
    //lib.addLibPath("deps/RealSenseID/build/lib");
    lib.addIncludeDir("deps/RealSenseID/wrappers/c/include");
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.linkSystemLibrary("pam");
    lib.linkSystemLibrary("rsid_c");
    lib.install();
}
