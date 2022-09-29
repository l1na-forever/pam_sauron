const std = @import("std");
const zb = std.build;

pub fn build(b: *zb.Builder) !void {
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary(
        "pam_sauron",
        "src/pam_sauron.zig",
        .unversioned,
    );
    lib.addIncludeDir("deps/RealSenseID/wrappers/c/include");
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.linkSystemLibrary("pam");
    lib.linkSystemLibrary("rsid_c");

    const lib_install = try b.allocator.create(PamSauronInstallStep);
    lib_install.* = .{
        .builder = b,
        .step = zb.Step.init(.custom, "install pam_sauron.so", b.allocator, PamSauronInstallStep.make),
        .pam_sauron = lib,
    };
    lib_install.step.dependOn(&lib.step);
    b.getInstallStep().dependOn(&lib_install.step);
}

// Largely borrowed from:
// https://github.com/ifreund/rundird/blob/trunk/build.zig#L51-L63
// See: https://github.com/ziglang/zig/issues/2231
const PamSauronInstallStep = struct {
    builder: *zb.Builder,
    step: zb.Step,
    pam_sauron: *zb.LibExeObjStep,

    fn make(step: *zb.Step) !void {
        const self = @fieldParentPtr(PamSauronInstallStep, "step", step);
        const b = self.builder;

        const full_dest_path = b.getInstallPath(.{ .custom = "lib/security" }, "pam_sauron.so");
        try b.updateFile(self.pam_sauron.getOutputSource().getPath(b), full_dest_path);
    }
};
