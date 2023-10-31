.org 0
.global _start

/* newlib system calls */
.set STDOUT,1
.set SYSEXIT, 93
.set SYSWRITE, 64

.data
    # will not overflow, and will predict as false
cmp_data_1: .dword 0x0000000000000000, 0x0000000000000000
    # will not overflow, and will predict as false
cmp_data_2: .dword 0x0000000000000001, 0x0000000000000010
    # will not overflow, but will predict as true
cmp_data_3: .dword 0x0000000000000002, 0x4000000000000000
    # will overflow, and will predict as true
cmp_data_4: .dword 0x0000000000000003, 0x7FFFFFFFFFFFFFFF

nextline:    .ascii  "\n"
             .set str_next_len, .-nextline

blank:      .ascii  " "
             .set str_blank_len, .-blank



.text
# assume little endian
_start:
    addi sp, sp, -16
    
    # push four pointers of test data onto the stack
    la t0, cmp_data_1
    sw t0, 0(sp)
    la t0, cmp_data_2
    sw t0, 4(sp)
    la t0, cmp_data_3
    sw t0, 8(sp)
    la t0, cmp_data_4
    sw t0, 12(sp)
 
    addi s0, zero, 4    # s0 is the goal iteration count
    addi s1, zero, 0    # s1 is the counter
    addi s2, sp, 0      # s2 now points to cmp_data_1
main_loop:
    lw a0, 0(s2)        # a0 stores the pointer to first data in cmp_data_x
    addi a1, a0, 8      # a1 stores the pointer to second data in cmp_data_x
    jal ra, pimo

    ### print for rv32emu
    addi a1, a0, 48
    addi sp, sp, -4
    sw a1, 0(sp)
    addi a1, sp, 0
    li a7, SYSWRITE
    li a0, STDOUT
    li a2, 4
    ecall 
    addi sp,sp,4  
    ###

    # printf("\n");
    li  a7, SYSWRITE
    li  a0, 1
    la  a1, nextline
    li  a2, 1
    ecall
    
    addi s2, s2, 4      # s2 points to next cmp_data_x
    addi s1, s1, 1      # counter++
    bne s1, s0, main_loop
    
    addi sp, sp, 16
    j exit
    
    
# predict if multiplication overflow:
pimo:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    
    mv s0, a0       # s0 is address of x0
    mv s1, a1       # s1 is address of x1
    
    lw a0, 0(s0)
    lw a1, 4(s0)    # a0 a1 is now the value of x0
    jal ra, clz
    li s2, 63
    sub s2, s2, a0  # s2 is now exp_x0
    
    lw a0, 0(s1)
    lw a1, 4(s1)    # a1 a0 is now the value of x1
    jal ra, clz
    li s3, 63
    sub s3, s3, a0  # s3 is now exp_x1
 
    add s2, s2, s3
    addi s2, s2, 2  # s2 is (exp_x0 + 1) + (exp_x1 + 1)
    li t0, 64
    bge s2, t0, pimo_ret_t
    li a0, 0        # return false
    j pimo_end
pimo_ret_t:
    li a0, 1        # return true
pimo_end:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret


# count leading zeros
clz:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # a0 a1 = x

    bne a1, zero, clz_fill_ones_upper
clz_fill_ones_lower:
    srli t0, a0, 1
    or a0, a0, t0
    srli t0, a0, 2
    or a0, a0, t0
    srli t0, a0, 4
    or a0, a0, t0
    srli t0, a0, 8
    or a0, a0, t0
    srli t0, a0, 16
    or a0, a0, t0
    j clz_fill_ones_end
clz_fill_ones_upper:
    srli t1, a1, 1
    or a1, a1, t1
    srli t1, a1, 2
    or a1, a1, t1
    srli t1, a1, 4
    or a1, a1, t1
    srli t1, a1, 8
    or a1, a1, t1
    srli t1, a1, 16
    or a1, a1, t1
    li a0, 0xffffffff
clz_fill_ones_end:
    
    
    # x -= ((x >> 1) & 0x5555555555555555);
    srli t0, a0, 1
    slli t1, a1, 31
    or t0, t0, t1
    srli t1, a1, 1      # t0 t1 = x >> 1
    
    li t2, 0x55555555   # t2 is the mask
    and t0, t0, t2
    and t1, t1, t2      # t0 t1 = (x >> 1) & 0x5555555555555555
 
    sltu t3, a0, t0     # t3 is the borrow bit
    sub a0, a0, t0
    sub a1, a1, t1
    sub a1, a1, t3      # a0 a1 = x - (t0 t1)
    
    
    # x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333);
    srli t0, a0, 2
    slli t1, a1, 30
    or t0, t0, t1
    srli t1, a1, 2      # t0 t1 = x >> 2
    
    li t2, 0x33333333   # t2 is the mask
    and t0, t0, t2
    and t1, t1, t2      # t0 t1 = (x >> 2) & 0x3333333333333333
    and t4, a0, t2
    and t5, a1, t2      # t4 t5 = x & 0x3333333333333333
    
    add a0, t0, t4
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, t1, t5
    add a1, a1, t3      # a0 a1 = (t0 t1) + (t4 t5)
    
    
    # x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    srli t0, a0, 4
    slli t1, a1, 28
    or t0, t0, t1
    srli t1, a1, 4      # t0 t1 = x >> 4
    
    add t0, t0, a0
    sltu t3, t0, a0     # t3 is the carry bit
    add t1, t1, a1
    add t1, t1, t3      # t0 t1 = (x >> 4) + x
    
    li t2, 0x0f0f0f0f   # t2 is the mask
    and a0, t0, t2
    and a1, t1, t2      # a0 a1 = (t0 t1) & 0x0f0f0f0f0f0f0f0f
    
    
    # x += (x >> 8);
    srli t0, a0, 8
    slli t1, a1, 24
    or t0, t0, t1
    srli t1, a1, 8      # t0 t1 = x >> 8
    
    add a0, a0, t0
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, a1, t1
    add a1, a1, t3      # a0 a1 = x + (x >> 8)
    
    
    # x += (x >> 16);
    srli t0, a0, 16
    slli t1, a1, 16
    or t0, t0, t1
    srli t1, a1, 16     # t0 t1 = x >> 16
    
    add a0, a0, t0
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, a1, t1
    add a1, a1, t3      # a0 a1 = x + (x >> 16)
    
    
    # x += (x >> 32);
    mv t0, a1
    mv t1, zero         # t0 t1 = x >> 32
    
    add a0, a0, t0
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, a1, t1
    add a1, a1, t3      # a0 a1 = x + (x >> 32)
    
    
    # return (64 - (x & 0x7f));
    andi a0, a0, 0x7f   # a0 = (x & 0x7f)
    li t0, 64
    sub a0, t0, a0      # a0 = (64 - (x & 0x7f))
    
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

exit:
    li  a7, SYSEXIT	    
    addi a0, x0, 0
    ecall