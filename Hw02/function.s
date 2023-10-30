    #string
    str: .string "\n"
    
    ## print for RIPES
    li a7,1
    ecall
    li a7,4               # set a7 as string mode 
    la a0,str             # load str to a0
    ecall                 # ecall 
    ##

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