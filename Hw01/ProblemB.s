.data
# test data 
test0: .word 0x4141f9a7,0x423645a2 

# mask
mask0: .word 0x7F800000,0x007FFFFF,0x800000,0x8000,0x7f
# mask0  for exponent  ,fraction
mask1: .word 0x8000
mask2: .word 0xFFFF0000,0x0000FFFF

#string
# str: .string "\n"

.text
main:
    li a7,1     
    la a2,test0           # load test data address to a2
    lw a6,0(a2)           # load test data to a6
    jal ra,f32_b16_p1     # call fp32 to bf16 function 
    add a0,x0,a6          # save number to a0 wait for 
    ecall
    j exit

# function converts IEEE754 fp32 to bfloat16
f32_b16_p1:
    sw a6,0(sp)
    add t0,a6,x0          # a6 will be only for this funtion to access
    la a3,mask0           # load mask0 address to a3
    
    # exponent
    lw t6,0(a3)           # load mask 0x7F800000 to t6
    and t1,t0,t6          # let exponent save to t1
    
    # fraction
    lw t6,4(a3)           # load 0x007FFFFF to t6
    and t2,t0,t6          # let fraction save to t2
    
    # check this number if 0 or inf (exponent + fraction)
    lw t6,0(a3)           # load mask 0x7F800000 to t6
    beq t1,t6,inf_or_zero # exp == 0x7F800000
    or t3,t1,t2 
    beq t3,x0,inf_or_zero # exp == 0 && man == 0 
    
    # add integer to fraction
    lw t6,8(a3)           # load integer
    or t2,t2,t6           # add integer
    
    # round to nearest for fraction
    lw t6,12(a3)          # load the round number
    add t2,t2,t6          # add round number
    srli t5,t2,24         # shift left 24 to t5 
    beq t5,x0,no_overflow # if t5 equal to 0 move to no_overflow
    # if overflow
    lw t6,8(a3)           # load mask 0x007FFFFF
    add t1,t1,t6          # add 1 to exponent
    srli t2,t2,17         # shift t2 to left 1 integer and 7 fraction
    lw t6,16(a3)          # load mask 0x7f
    and t2,t2,t6          # let t2 only have integer
    slli t2,t2,16         # shift right 16
    # if not overflow
no_overflow:
    srli t2,t2,16         # shift t2 to left 1 integer and 7 fraction
    lw t6,16(a3)          # load mask 0x7f
    and t2,t2,t6          # let t2 only have integer
    slli t2,t2,16         # shift right 16
    #f32_b16 end function
f32_b16_p2:
    # save to a6
    srli t0,t0,31         # shift left to let t0 remain sign
    slli t0,t0,31         # shift right to let t0 sign to the right position
    or t0,t0,t1           # combine sign and exponent together
    or t0,t0,t2           # combine sign,exponent and fraction together
    add a6,t0,x0          # save t0 to a6
    ret                   # move back to main function
    
inf_or_zero:  
    srli a6,a6,16        
    slli a6,a6,16
    ret                   # move back to main function
# end of funtion  
    
exit:
    li a7,10
    ecall