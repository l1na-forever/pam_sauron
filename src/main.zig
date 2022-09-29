const std = @import("std");
const pam = @cImport({
    @cInclude("security/pam_appl.h");
    @cInclude("security/pam_modules.h");
});

export fn pam_sm_setcred(_: *pam.pam_handle, _: i32, _: i32, _: [*]const u8) i32 {
    // TODO - enroll here for PAM_ESTABLISH_CRED
    // see also pam_sm_chauthtok for when password change is requested
    // https://web.archive.org/web/20190523222819/https://fedetask.com/write-linux-pam-module/
    return pam.PAM_SUCCESS;
}

export fn pam_sm_acct_mgmt(_: *pam.pam_handle, _: i32, _: i32, _: [*]const u8) i32 {
    return pam.PAM_SUCCESS;
}

export fn pam_sm_authenticate(handle: *pam.pam_handle, _: i32, _: i32, _: [*]const u8) i32 {
    const stdout = std.io.getStdOut().writer();
    var username: [*c]const u8 = undefined;
    var pam_result: i32 = undefined;

    pam_result = pam.pam_get_user(handle, &username, null);
    if (pam_result != pam.PAM_SUCCESS) {
        stdout.print("pam_get_user failed: {}\n", .{pam_result}) catch {};
        return pam.PAM_AUTH_ERR;
    }

    stdout.print("Authenticating '{s}'\n", .{username}) catch {};
    return pam.PAM_SUCCESS;
}

// To install:
// sudo cp target/debug/libpam_realsense.so /usr/lib/security/pam_realsense.so
//
// To use (try this form of auth), add to the target pam module (e.g., sudo):
// auth sufficient pam_realsense.so

