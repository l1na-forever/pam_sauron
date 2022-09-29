const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const version = b.version(1, 0, 0);
    const lib = b.addSharedLibrary(
        "sauron",
        "src/main.zig",
        version,
    );
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.linkSystemLibrary("pam");
    lib.install();
}
