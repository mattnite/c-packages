const std = @import("std");
const c = @cImport({
    @cInclude("lib6502.h");
});

pub const Vector = enum(c_uint) {
    nmi = 0xfffa,
    rst = 0xfffc,
    irq = 0xfffe,
};

pub const CallbackType = enum {
    read,
    write,
    call,
};

pub const Allocated = packed struct(c_uint) {
    registers: bool,
    memory: bool,
    callbacks: bool,
};

pub const Registers = c.M6502_Registers;
pub const Callback = c.M6502_Callback;
pub const Callbacks = c.M6502_Callbacks;
pub const Memory = c.M6502_Memory;

pub const Mpu = struct {
    impl: *c.M6502,

    /// Underlaying C library function aborts if memory allocation fails
    pub fn init(registers: ?*Registers, memory: ?*Memory, callbacks: ?*Callbacks) Mpu {
        return Mpu{
            .impl = c.M6502_new(registers, @ptrCast(memory), callbacks),
        };
    }

    pub fn deinit(mpu: *Mpu) void {
        c.M6502_delete(mpu.impl);
    }

    pub fn reset(mpu: *Mpu) void {
        c.M6502_reset(mpu.impl);
    }

    pub fn nmi(mpu: *Mpu) void {
        c.M6502_nmi(mpu.impl);
    }

    pub fn irq(mpu: *Mpu) void {
        c.M6502_irq(mpu.impl);
    }

    pub fn run(mpu: *Mpu) void {
        c.M6502_run(mpu.impl);
    }

    /// Returns the size of the instruction
    pub fn disassemble(mpu: *Mpu, addr: u16, buf: *[64]u8) !usize {
        return @intCast(c.M6502_disassemble(&mpu.impl, addr, buf));
    }

    pub fn dump(mpu: *Mpu, buf: *[64]u8) void {
        c.M6502_dump(mpu.impl, buf);
    }

    pub fn get_vector(mpu: *Mpu, vector: Vector) u16 {
        const vector_lsb = @intFromEnum(vector);
        const vector_msb = vector_lsb + 1;
        return (mpu.impl.memory[vector_msb] << 8) | mpu.impl.memory[vector_msb];
    }

    pub fn set_vector(mpu: *Mpu, vector: Vector, addr: u16) void {
        const vector_lsb = @intFromEnum(vector);
        const vector_msb = vector_lsb + 1;
        mpu.impl.memory[vector_msb] = @truncate(addr >> 8);
        mpu.impl.memory[vector_lsb] = @truncate(addr);
    }

    pub fn get_callback(mpu: *Mpu, cb_type: CallbackType, addr: u16) void {
        return switch (cb_type) {
            .read => mpu.impl.callbacks.read[addr],
            .write => mpu.impl.callbacks.write[addr],
            .call => mpu.impl.callbacks.call[addr],
        };
    }

    pub fn set_callback(mpu: *Mpu, cb_type: CallbackType, addr: u16, cb: *const Callback) void {
        switch (cb_type) {
            .read => mpu.impl.callbacks.read[addr] = cb,
            .write => mpu.impl.callbacks.write[addr] = cb,
            .call => mpu.impl.callbacks.call[addr] = cb,
        }
    }
};
