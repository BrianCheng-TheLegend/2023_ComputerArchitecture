.data
# test data 
test0: .word 0x4141f7cf,0x423645a2

# mask
mask0: .word 0x7F800000,0x007FFFFF,0xFFFF0000
mask1: .word 0xFFFF0000,0x0000FFFF

#string
str: .string "\n"

.text
main:
    li a7,1
    lw a0,0(a1)
    jal ra,fp32_2_bf16
    ecall
    
    j exit

fp32_2_bf16:
    
    
exit:
    li a7,10
    ecall