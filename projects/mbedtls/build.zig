const std = @import("std");
const Build = std.Build;

pub const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },

    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },

    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },
};

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mbedtls = b.addStaticLibrary(.{
        .name = "mbedtls",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mbedtls.addIncludePath(.{ .path = "c/include" });
    mbedtls.addCSourceFiles(.{
        .files = srcs,
        .flags = &.{},
    });
    mbedtls.installHeadersDirectory(.{ .path = "c/include/mbedtls" }, "mbedtls", .{});
    mbedtls.installHeadersDirectory(.{ .path = "c/include/psa" }, "psa", .{});
    b.installArtifact(mbedtls);

    const selftest = b.addExecutable(.{
        .name = "selftest",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    selftest.defineCMacro("MBEDTLS_SELF_TEST", null);
    selftest.addCSourceFile(.{
        .file = .{ .path = "c/programs/test/selftest.c" },
        .flags = &.{},
    });
    selftest.linkLibrary(mbedtls);

    const selftest_run = b.addRunArtifact(selftest);
    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&selftest_run.step);
}

const srcs: []const []const u8 = &.{
    "c/library/x509_create.c",
    "c/library/x509_crt.c",
    "c/library/psa_crypto_client.c",
    "c/library/aes.c",
    "c/library/psa_crypto_slot_management.c",
    "c/library/bignum_mod_raw.c",
    "c/library/psa_crypto_driver_wrappers_no_static.c",
    "c/library/camellia.c",
    "c/library/constant_time.c",
    "c/library/pk_wrap.c",
    "c/library/pk.c",
    "c/library/pkcs7.c",
    "c/library/aesce.c",
    "c/library/ssl_tls13_client.c",
    "c/library/ssl_tls12_client.c",
    "c/library/psa_util.c",
    "c/library/ecdh.c",
    "c/library/ssl_tls.c",
    "c/library/x509_crl.c",
    "c/library/cipher_wrap.c",
    "c/library/chacha20.c",
    "c/library/psa_crypto_rsa.c",
    "c/library/des.c",
    "c/library/ssl_cookie.c",
    "c/library/ctr_drbg.c",
    "c/library/psa_crypto_mac.c",
    "c/library/aesni.c",
    "c/library/dhm.c",
    "c/library/ssl_cache.c",
    "c/library/ssl_ciphersuites.c",
    "c/library/ecp_curves_new.c",
    "c/library/hmac_drbg.c",
    "c/library/rsa.c",
    "c/library/ssl_ticket.c",
    "c/library/asn1parse.c",
    "c/library/mps_trace.c",
    "c/library/pkwrite.c",
    "c/library/gcm.c",
    "c/library/sha1.c",
    "c/library/ssl_client.c",
    "c/library/asn1write.c",
    "c/library/ccm.c",
    "c/library/version_features.c",
    "c/library/aria.c",
    "c/library/lms.c",
    "c/library/psa_crypto_cipher.c",
    "c/library/entropy_poll.c",
    "c/library/x509write_csr.c",
    "c/library/platform.c",
    "c/library/cmac.c",
    "c/library/bignum.c",
    "c/library/pkparse.c",
    "c/library/psa_crypto_ffdh.c",
    "c/library/ssl_msg.c",
    "c/library/debug.c",
    "c/library/ripemd160.c",
    "c/library/pkcs5.c",
    "c/library/ssl_tls13_generic.c",
    "c/library/x509write.c",
    "c/library/bignum_mod.c",
    "c/library/pem.c",
    "c/library/oid.c",
    "c/library/error.c",
    "c/library/psa_crypto_pake.c",
    "c/library/x509_csr.c",
    "c/library/psa_its_file.c",
    "c/library/psa_crypto.c",
    "c/library/rsa_alt_helpers.c",
    "c/library/ssl_debug_helpers_generated.c",
    "c/library/platform_util.c",
    "c/library/psa_crypto_se.c",
    "c/library/base64.c",
    "c/library/memory_buffer_alloc.c",
    "c/library/mps_reader.c",
    "c/library/psa_crypto_aead.c",
    "c/library/ecp.c",
    "c/library/lmots.c",
    "c/library/version.c",
    "c/library/x509.c",
    "c/library/bignum_core.c",
    "c/library/chachapoly.c",
    "c/library/ssl_tls13_keys.c",
    "c/library/sha256.c",
    "c/library/ecp_curves.c",
    "c/library/md5.c",
    "c/library/timing.c",
    "c/library/psa_crypto_ecp.c",
    "c/library/psa_crypto_storage.c",
    "c/library/poly1305.c",
    "c/library/x509write_crt.c",
    "c/library/hkdf.c",
    "c/library/sha3.c",
    "c/library/threading.c",
    "c/library/padlock.c",
    "c/library/psa_crypto_hash.c",
    "c/library/pkcs12.c",
    "c/library/entropy.c",
    "c/library/ssl_tls13_server.c",
    "c/library/ssl_tls12_server.c",
    "c/library/net_sockets.c",
    "c/library/sha512.c",
    "c/library/md.c",
    "c/library/ecjpake.c",
    "c/library/cipher.c",
    "c/library/ecdsa.c",
    "c/library/nist_kw.c",
};
