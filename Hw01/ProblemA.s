.data

test1: .word 0xf1ac,0x123

.text
main:
    la t0,test1
    jal ra,clz
    jal ra,pr



# Count leading zeros
clz :
    jal ra,slo
    jal ra,co
    jr ra
    

# set leaging one
slo :
    # laod t0 as original 
    # let the left of leading 1 be 0 
    # and let the right of leading 1 be 1
    srli t1,t0,1
    or t0,t0,t1
    srli t1,t0,2
    or t0,t0,t1
    srli t1,t0,4
    or t0,t0,t1
    srli t1,t0,8
    or t0,t0,t1
    srli t1,t0,16
    or t0,t0,t1
    srli t1,t0,32
    or t0,t0,t1
    jr ra

# count ones
co :
    srli t1,t0,1
    andi t1,t1,0x5555555555555555
    sub  t0,t0,t1
    srli t1,t0,2
    andi t1,t1,0x3333333333333333
    andi t2,t0,0x3333333333333333
    add t0,t1,t2
    arli t1,t0,4
    add t1,t0,t1
    andi t0,t1,0x0f0f0f0f0f0f0f0f
    srli t1,t0,8
    add t0,t0,t1
    srli t1,t0,16
    add t0,t0,t1
    srli t1,t0,32
    add t0,t0,t1
    jr ra
    
pr:
    li a7, 1
    ecall
    jr ra