const std = @import("std");
const c = @cImport({
    @cInclude("security/pam_appl.h");
    @cInclude("security/pam_modules.h");
    @cInclude("rsid_c/rsid_client.h");
    @cInclude("rsid_c/rsid_status.h");
});

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

var pam_user: ?[*:0]const u8 = null;
var authenticated: bool = false;

// Unused by this module
export fn pam_sm_setcred(_: *c.pam_handle, _: i32, _: i32, _: [*]const u8) i32 {
    return c.PAM_SUCCESS;
}

// Unused by this module
export fn pam_sm_acct_mgmt(_: *c.pam_handle, _: i32, _: i32, _: [*]const u8) i32 {
    return c.PAM_SUCCESS;
}

// Callback for authenticating a user
export fn pam_sm_authenticate(handle: *c.pam_handle, _: i32, _: i32, _: [*]const u8) i32 {
    // Retrieve username (or prompt for one)
    if (c.pam_get_user(handle, &pam_user, null) != c.PAM_SUCCESS) {
        return c.PAM_AUTH_ERR;
    }
    stdout.print("Authenticating via RSID...\n", .{}) catch {};

    // Silence RSID Library
    c.rsid_set_log_clbk(rsid_log, c.RSID_LogLevel_Off, 0);

    // Open authenticator serial connection
    const serial_config: c.rsid_serial_config = .{ .port = "/dev/ttyACM0" };
    const authenticator: *c.rsid_authenticator = c.rsid_create_authenticator() orelse return c.PAM_AUTH_ERR;
    if (c.rsid_connect(authenticator, &serial_config) != c.RSID_Ok) {
        stderr.print("Unable to initialize RSID\n", .{}) catch {};
        return c.PAM_AUTH_ERR;
    }
    defer {
        c.rsid_destroy_authenticator(authenticator);
    }

    // Create authentication request
    const auth_args: c.rsid_auth_args = .{
        .result_clbk = rsid_result_cb,
        .hint_clbk = rsid_hint_cb,
        .face_detected_clbk = null,
        .ctx = null,
    };
    if (c.rsid_authenticate(authenticator, &auth_args) != c.RSID_Ok) {
        stderr.print("Unable to authenticate with RSID\n", .{}) catch {};
        return c.PAM_AUTH_ERR;
    }

    // The result callback method simply sets the "authenticated" flag,
    // after comparing usernames.
    if (authenticated) {
        stdout.print("Authenticated '{s}'!\n", .{pam_user}) catch {};
        return c.PAM_SUCCESS;
    } else {
        return c.PAM_AUTH_ERR;
    }
}

fn rsid_result_cb(status: c.rsid_auth_status, user: ?[*:0]const u8, _: ?*anyopaque) callconv(.C) void {
    // If we have a successful authentication, check the given username against
    // the pam-provided username. sliceTo to convert sentinel-terminated
    // pointer to a fat slice.
    if (status == c.RSID_Auth_Success and std.mem.eql(u8, std.mem.sliceTo(user.?, 0), std.mem.sliceTo(pam_user.?, 0))) {
        authenticated = true;
    } else {
        stderr.print("Authentication failed\n", .{}) catch {};
    }
}

fn rsid_hint_cb(hint: c.rsid_auth_status, _: ?*anyopaque) callconv(.C) void {
    stdout.print("Authentication hint: {s}\n", .{c.rsid_auth_status_str(hint)}) catch {};
}

fn rsid_log(_: c.rsid_log_level, _: [*c]const u8) callconv(.C) void {}
