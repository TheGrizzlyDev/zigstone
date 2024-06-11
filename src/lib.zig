const std = @import("std");
const c = @cImport({
    @cInclude("capstone/capstone.h");
});

const Arch = enum {
    x86_64,
};

const DisassemblerIter = struct {};

const Disassembler = struct {
    const Self = @This();
    addr: u64,
    code: []const u8,
    allocator: std.mem.Allocator,
    handle: c.csh,

    fn init(
        allocator: std.mem.Allocator,
        arch: Arch,
        addr: u64,
        code: []const u8,
    ) !*Self {
        var self = try allocator.create(Self);
        self.addr = addr;
        self.code = code;
        _ = arch;

        // setup needs to wrap the actual allocator
        const setup = std.mem.zeroes(c.cs_opt_mem);

        _ = c.cs_option(0, c.CS_OPT_MEM, @intFromPtr(&setup));
        // allocates, so we need to initialize the global mem management
        _ = c.cs_open(c.CS_ARCH_X86, c.CS_MODE_32, &self.handle);
        return self;
    }

    fn nextAlloc(self: *Self) !?*c.cs_insn {
        const ins = try self.allocator.create(c.cs_insn);
        if (self.next(ins)) {
            return ins;
        }
        // TODO: deallocate ins
        return null;
    }

    fn next(self: *Self, ins: *c.cs_insn) bool {
        return c.cs_disasm_iter(self.handle, @ptrCast(&self.code.ptr), self.code.len, &self.addr, ins);
    }
};

test "ok" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const disassembler = try Disassembler.init(allocator, .x86_64, 0x1000, "\x90\x91\x92");

    _ = disassembler;
    // while (try disassembler.nextAlloc()) |ins| {
    //     // defer ins.deinit();
    //     std.debug.print("ins: {any}", .{ins});
    // }

    // try std.testing.expect(false);
}
