.data 
# test data 
test0: .dword 0x5555555533333333
# mask
mask0: .word 0x55555555
mask1: .word 0x33333333
mask2: .word 0x0f0f0f0f
mask:  .word 0x7f

#string
str: .string "\n"

.text 
main:
    la a2,test0
    li a7,1
    lw a0,0(a2)
    addi a0,a0,1
    sw a2,0(a0)
    add a0,x0,x0
    lw a0,4(a2)
    ecall
    #jal ra,cl

    #li a7,1
    #lw a0,4(a2)
    #ecall

    j exit


# change line
cl:
    li a7,4
    la a0,str
    ecall
    jr ra
 
# exit funtion
exit:
    li a7,10
    ecall