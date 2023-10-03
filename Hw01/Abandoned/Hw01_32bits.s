.data 
# test data
array0: .word 0x1,0x2,0x4,0x10,0x8,
test0: .word 0x01
# mask
mask0: .word 0x55555555
mask1: .word 0x33333333
mask2: .word 0x0f0f0f0f
mask:  .word 0x3f
    
#string
str: .string "\n"

.text 
main:
    # load a2 as test data
    la a2,test0
    lw a2,0(a2)
     
    #li a7,1
    #lw a0,0(a1)
    #ecall
    
    #jal ra,cl
    jal ra,slo
    
    li a7,1
    add a0,a2,x0
    ecall
    
    j exit

# set leading one for 32 bits
slo:
    # load test data to t2
    add t2,a2,x0
    
    srli t3,t2,1 # x |= (x >> 1);
    or t2,t2,t3
    srli t3,t2,2 # x |= (x >> 2);
    or t2,t2,t3
    srli t3,t2,4 # x |= (x >> 4);
    or t2,t2,t3
    srli t3,t2,8 # x |= (x >> 8);
    or t2,t2,t3
    srli t3,t2,16 # x |= (x >> 16);
    or t2,t2,t3
    
    # load t0 as mask address
    la t0,mask0
    
    # x-=((x>>1) & 0x55555555);
    lw t1,0(t0)     # load t1 as mask0
    srli t3,t2,1    # set t3 as temporary
    and t3,t3,t1
    sub t2,t2,t3
    
    # x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
    lw t1,4(t0)     # load t1 as mask1
    srli t3,t2,2
    and t3,t3,t1
    and t2,t2,t1
    add t2,t2,t3
    
    # x = ((x >> 4) + x) & 0x0f0f0f0f;
    lw t1,8(t0)    # load t1 as mask2
    srli t3,t2,4
    add t2,t2,t3
    and t2,t2,t1
    
    # x += (x >> 8);
    srli t3,t2,8
    add t2,t2,t3
    
    # x += (x >> 16);
    srli t3,t2,16
    add t2,t2,t3
    
    # x=(32 - (x & 0x3f));
    #lw t1,12(t0)
    #and t2,t2,t1
    #sub t2,t2,x0
    #addi t2,t2,32
    
    # return 
    add a2,t2,x0
    jr ra

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