    #string
    str: .string "\n"
    
    ## print for RIPES
    li a7,1
    ecall
    li a7,4               # set a7 as string mode 
    la a0,str             # load str to a0
    ecall                 # ecall 
    ##