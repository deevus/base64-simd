const std = @import("std");
const builtin = @import("builtin");

pub fn generateConfig() !void {
    var file = try std.fs.cwd().createFile("deps/base64/lib/config.h", .{});
    defer file.close();

    // var buf_writer = std.io.BufferedWriter(64, file.writer());
    var stream = file.writer();

    switch (builtin.cpu.arch) {
        .x86_64 => {
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .avx512f)) {
                _ = try stream.write("#define HAVE_AVX512 1\n");
            } else {
                _ = try stream.write("#define HAVE_AVX512 0\n");
            }
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .avx2)) {
                _ = try stream.write("#define HAVE_AVX2   1\n");
            } else {
                _ = try stream.write("#define HAVE_AVX2   0\n");
            }
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .ssse3)) {
                _ = try stream.write("#define HAVE_SSSE3  1\n");
            } else {
                _ = try stream.write("#define HAVE_SSSE3  0\n");
            }
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .sse4_1)) {
                _ = try stream.write("#define HAVE_SSE41  1\n");
            } else {
                _ = try stream.write("#define HAVE_SSE41  0\n");
            }
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .sse4_2)) {
                _ = try stream.write("#define HAVE_SSE42  1\n");
            } else {
                _ = try stream.write("#define HAVE_SSE42  0\n");
            }
            if (std.Target.x86.featureSetHas(builtin.cpu.features, .avx2)) {
                _ = try stream.write("#define HAVE_AVX    1\n");
            } else {
                _ = try stream.write("#define HAVE_AVX    0\n");
            }
        },
        .arm => {
            if (std.Target.arm.featureSetHas(builtin.cpu.features, .neon)) {
                stream.write("#define HAVE_NEON32 1\n");
                stream.write("#define HAVE_NEON64 1\n");
            } else {
                stream.write("#define HAVE_NEON32 0\n");
                stream.write("#define HAVE_NEON64 0\n");
            }
        },
        else => {},
    }
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    generateConfig() catch @panic("generate config failed");

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Reference: https://github.com/kristoff-it/redis/blob/zig/build.zig
    const lib64 = b.addStaticLibrary(.{
        .name = "libbase64",
        .target = target,
        .optimize = optimize,
    });
    lib64.linkLibC();
    lib64.addCSourceFiles(&.{
        "deps/base64/lib/arch/avx512/codec.c",
        "deps/base64/lib/arch/avx2/codec.c",
        "deps/base64/lib/arch/generic/codec.c",
        "deps/base64/lib/arch/neon32/codec.c",
        "deps/base64/lib/arch/neon64/codec.c",
        "deps/base64/lib/arch/ssse3/codec.c",
        "deps/base64/lib/arch/sse41/codec.c",
        "deps/base64/lib/arch/sse42/codec.c",
        "deps/base64/lib/arch/avx/codec.c",
        "deps/base64/lib/lib.c",
        "deps/base64/lib/codec_choose.c",
        "deps/base64/lib/tables/tables.c",
    }, &.{
        "-std=c99",
        "-O3",
        "-Wall",
        "-Wextra",
        "-pedantic",
    });
    lib64.addIncludePath("deps/base64/lib");

    const lib = b.addStaticLibrary(.{
        .name = "base64",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.addIncludePath("deps/base64/include");
    lib.linkLibrary(lib64);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.linkLibC();
    main_tests.addIncludePath("deps/base64/include");
    main_tests.linkLibrary(lib64);

    const run_main_tests = b.addRunArtifact(main_tests);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
