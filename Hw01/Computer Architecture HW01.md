---
tag : Computer Architecture
---


# Computer Architecture HW01
contributed by <[`Brian Cheng`](https://github.com/BrianCheng-TheLegend?tab=repositories)>

[Lab1: RV32I Simulator](https://hackmd.io/@sysprog/H1TpVYMdB)

## Reducing memory usage with bfloat and bfloat multiplication
The Problem is from [2023 Computer Architecture quiz1](https://hackmd.io/@sysprog/arch2023-quiz1),and it is `Problem B`, single prcision floating point valuses to corresponding [bfloat16](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format) floating-point format.

Reducing memory usage with bfloat16 is when we call a bfloat16 in memory we usually use one register but there will cause 16-bits waste with 0 and if you want to call two bfloat16 you should use two register to , so if we can combine two bfloat16 in 32-bits memory then we can get these two bfloat16 from memory  and use only one register.

The function above will include encoder and decoder, encoder is for combine two bfloat16 in 32-bits register and decoder is to seperate two bfloat16 number to two registers.

Then the bfloat16 multiplication is the function for bfloat16, it may mulitply two floating-point number and let the output number be a bfloat16.

## Solution
My problem solving idea is from bfloat16 has a leading 16 bits with it value and the other 16 bits will be 0.

Then if we want to merge two bfloat16 to one 32-bits register, we need our encoder to hold first bfloat16 at original number and shift second bfloat16 16 bits to fit the space with first bfloat16 0,next step we will or these two bfloat16 together to get merged value.

And the decoder will be with two mask `0xFFFF0000` and `0x0000FFFF` to take out two bfloat16 number and the second bfloat16 should shift 16-bits to be right position.

The Multiplication with two floating point will first,
`XOR` two floating point sign,the `exponent1+exponent2-127` will be the the exponent number

Final we deal with the fraction part, at first we get first bfloat16 and second bfloat16 fraction and add leading 1, next if the first bfloat16 number are 1 then we add second bfloat16 at a zero register,then shift right second bfloat 1-bits and if the second number of first bfloat16 are 1 then add shifted second bfloat16 to the register above, repeat the steps above till the 8-bits(1 integer and 7 fraction)is over.And if the target bfloat16 is overflow then shift right one bits and add 1 number on exponent.

![](https://hackmd.io/_uploads/ryW-RObba.png)



## Implementation
### C Code 
This is my code on [Github](https://github.com/BrianCheng-TheLegend/2023_ComputerArchitecture/blob/main/Hw01/Hw01.c)

```clike=
#include<stdio.h>

float fp32_to_bf16(float x)                 
{
    float y = x;
    int *p = (int *) &y;
    unsigned int exp = *p & 0x7F800000;
    unsigned int man = *p & 0x007FFFFF;
    if (exp == 0 && man == 0) /* zero */
        return x;
    if (exp == 0x7F800000) /* infinity or NaN */
        return x;

    /* Normalized number */
    /* round to nearest */
    float r = x;
    int *pr = (int *) &r;
    *pr &= 0xFF800000;  /* r has the same exp as x */
    r /= 0X100;
    y = x + r;

    *p &= 0xFFFF0000;

    return y;
}

// encoder : encode two bfloat number in one memory
int encoder(int *a,int *b){
    int c=0;
    c=*a+(*b>>16);
    *a=0;
    *b=0;
    return c;
}
// decoder : decode one memory number in two bfloat
void decoder(int c ,int *n1,int *n2){
    *n1=c&0xffff0000;
    *n2=(c&0x0000ffff)<<16;
}

int main(){
    // definition of num1 and transfer it to bfloat
    float num1=-12.123;
    int *np1=(int *) &num1;
    num1=fp32_to_bf16(num1);
    // definition of num2 and transfer it to bfloat
    float num2=45.568;
    int *np2=(int *) &num2;
    num2=fp32_to_bf16(num2);

    float add;
    int *p=(int *) &add;
    *p=0;
    // show num1 binary form and it's value
    printf("0x%x\n",*np1);
    printf("%f\n",num1);
    // show num2 binary form and it's value
    printf("0x%x\n",*np2);
    printf("%f\n",num2);
    // add two number together and print the binary form
    *p=encoder(np1,np2);
    decoder(*p,&num1,&num2);
    float mul_num;
    mul_num=num1*num2;
    printf("%f\n",mul_num);
    return 0;
}
```
### RISC-V Assembly Code
This is my code on [Github](https://github.com/BrianCheng-TheLegend/2023_ComputerArchitecture/blob/main/Hw01/Hw01.s)

```clike=
.data
# test data 
test0: .word 0x4141f9a7,0x423645a2 
test1: .word 0x3fa66666,0x42c63333
test2: .word 0x43e43a5e,0x42b1999a
# mask
# mask0  for exponent  ,fraction
#          ( 0         ,4         ,8       ,12    ,16  ,20        ,24        )
mask0: .word 0x7F800000,0x007FFFFF,0x800000,0x8000,0x7f,0x3F800000,0x80000000
# mask1 for round
mask1: .word 0x8000
# mask2 for decoder
mask2: .word 0xFFFF0000,0x0000FFFF

#string
str: .string "\n"

.text
main:
    li a7,1     
    la a2,test0           # load test data address to a2
    lw a6,0(a2)           # load test data to a6
    jal ra,f32_b16_p1     # call fp32 to bf16 function 
    add a5,a6,x0          # store first bfloat in a5
    
    lw a6,4(a2)           # load test data to a6
    jal ra,f32_b16_p1     # jump to float32 transform to bfloat function 
    add a4,a6,x0          # store the result to a4
    
    jal ra,encoder        # jump to encoder funtion
    add s9,s3,x0          # save s3(data after encode) to s9
    jal ra,decoder        # jump to decoder function
    jal ra,Multi_bfloat   # jump to bfloat Multiplication funcition
    
    # Output second bfloat after decoder
    li a7,2               # set a7 as float mode 
    add a0,x0,s5          # set a0 as s5 
    ecall                 # ecall
    
    jal ra,cl             # change line
    
    # Output first bfloat after decoder
    li a7,2               # set a7 as float mode  
    add a0,x0,s6          # set a0 as s6
    ecall                 # ecall
    
    jal ra,cl             # change line
    
    # Output Multiplication result
    li a7,2               # set a7 as float mode                
    add a0,x0,s3          # set a0 as s3(Multiplication results)      
    ecall                 # ecall
    
    j exit                # jump to exit this program

### function converts IEEE754 fp32 to bfloat16
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
    j f32_b16_p2
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
    ret                   # return to main
### end of funtion  
    
### encode two bfloat to one register
encoder:
    add t0,a5,x0          # load a5(first bfloat) to t0
    add t1,a4,x0          # load a4(second bfloat) to t1
    srli t1,t1,16         # shift to let second bfloat fit in one register
    or t0,t0,t1           # combine two bfloat in one register
    add s3,t0,x0          # load t0 to s3
    ret                   # return to main
    
### decode two bfloat on one register to two registers
decoder:
    add t0,s9,x0          # load s9(data encode) to t0
    la a1,mask2           # load mask2 address
    lw s2,0(a1)           # load mask 0xFFFF0000
    and t1,t0,s2          # use mask to specification bfloat 1
    lw s2,4(a1)           # load mask 0x0000FFFF
    and t2,t0,s2          # use mask to specification bfloat 2
    slli t2,t2,16         # shift to left to let bfloat peform like original float
    add s6,t1,x0          # store t1(bfloat 1) to s6
    add s5,t2,x0          # store t2(bfloat 2) to s5
    ret                   # return to main
    
### change line
cl:
    li a7,4               # set a7 as string mode 
    la a0,str             # load str to a0
    ecall                 # ecall 
    ret                   # return to main
    

### Multiplication with bfloat in one register
Multi_bfloat:
    # decoder function input is a0
    # jal ra,decoder        # load a0(two bloat number in one register) to t0
    # decoder function output is s5,s6
    add t0,s5,x0          # store s5(bfloat 2) to t0
    add t1,s6,x0          # store s6(bfloat 1) to t1
    lw t6,0(a3)           # load mask0 mask 0x7F800000
    # get exponent to t2,t3
    and t3,t0,t6          # use mask 0x7F800000 to get t0 exponent
    and t2,t1,t6          # use mask 0x7F800000 to get t1 exponent
    add t3,t3,t2          # add two exponent to t3
    lw t6,20(a3)          # load mask0 mask 0x3F800000
    sub t3,t3,t6          # sub 127 to exponent

    # get sign
    xor t2,t0,t1          # get sign and store on t2
    srli t2,t2,31         # get rid of useless data
    slli t2,t2,31         # let sign back to right position
    
    # get sign and exponent together
    or t3,t3,t2
    # set the sign and exponent to t0
    slli t0,t0,9
    srli t0,t0,9
    or t0,t3,t0

    # get fraction to t2 and t3
    lw t6,16(a3)          # load mask0 mask 0x7F
    slli t6,t6,16         # shift mask to 0x7F0000
    and t2,t0,t6          # use mask 0x7F0000 get fraction
    and t3,t1,t6          # use mask 0x7F0000 get fraction
    slli t2,t2,9          # shift left let no leading 0
    srli t2,t2,1          # shift right let leading has one 0
    lw t6,24(a3)          # load mask0 mask 0x80000000
    or t2,t2,t6           # use mask 0x80000000 to add integer
    srli t2,t2,1          # shift right to add space for overflow

    slli t3,t3,8          # shift left let no leading 0
    or t3,t3,t6           # use mask 0x80000000 to add integer
    srli t3,t3,1          # shift right to add space for overflow

    add s11,x0,x0         # set a counter and 0
    addi s10,x0,8         # set a end condition
    add t1,x0,x0          # reset t1 to 0 and let this register be result
    lw t6,24(a3)          # load mask0 mask 0x80000000

loop:
    addi s11,s11,1        # add 1 at counter every loop
    srli t6,t6,1          # shift right at 1 every loop
    
    and t4,t2,t6          # use mask to specified number at that place
    beq t4,x0,not_add     # jump if t4 equal to 0
    add t1,t1,t3          # add t3 to t1
not_add:
    srli t3,t3,1          # shift left 1 bit to t3
    bne s11,s10,loop      # if the condition not satisfy return to loop
# end of loop 
  
    # check if overflow
    lw t6,24(a3)          # load mask0 mask 0x80000000 to t6
    and t4,t1,t6          # get t1 max bit
    
    # if t4 max bit equal to 0 will not overflow
    beq t4,x0,not_overflow
    
    # if overflow
    slli t1,t1,1          # shift left 1 bits to remove integer
    lw t6,8(a3)           # load mask0 mask 0x800000
    add t0,t0,t6          # exponent add 1 if overflow
    j Mult_end            # jump to Mult_end
     
    # if not overflow
not_overflow:
    slli t1,t1,2          # shift left 2 bits to remove integer
Mult_end:
    srli t1,t1,24         # shift right to remove useless bits
    addi t1,t1,1          # add 1 little bit to check if carry
    srli t1,t1,1          # shift right to remove useless bits
    slli t1,t1,16         # shift left to let fraction be right position
    
    srli t0,t0,23         # shift right to remove useless bits
    slli t0,t0,23         # shift left to let sign and exponent be right position
    or t0,t0,t1           # combine t0 and t1 together to get bfloat

    add s3,t0,x0          # store bfloat after multiplication to  s3
    ret                   # return to main
### end of function    

exit:
    li a7,10              # set a7 as exit
    ecall                 # ecall
    
############ Check every bits
# li a7,35                # set a7 as binary mode
# add a0,t0,x0            # store print data to a0
# ecall                   # ecall
############ 
```

## Results

### **test0**
* floating 1 : 12.123 (Hexadecimal : 0x4141f9a7)
* floating 2 : 45.568 (Hexadecimal : 0x423645a2)
* Result:
![](https://hackmd.io/_uploads/Sy0GDFW-6.png)


### **test1**
* floating 1 : 1.2999999 (Hexadecimal : 0x3fa66666)
* floating 2 : 99 (Hexadecimal :0x42c63333)
* Result:
![](https://hackmd.io/_uploads/rkXsPKWbT.png)


### **test2**
* floating 1 : 456.456 (Hexadecimal : 0x43e43a5e)
* floating 2 : 88.8 (Hexadecimal : 0x42b1999a)
* Result:
![](https://hackmd.io/_uploads/ryGidt-ba.png)


## Analysis

[Ripes](https://github.com/mortbopet/Ripes) are ours simulate RISC-V processor
![](https://hackmd.io/_uploads/SkJZ5DMZa.png)
Single-Cycle RV32I Datapath 
![](https://hackmd.io/_uploads/B1IN4DMbp.png)
five-stage execution pipeline simulator
![](https://hackmd.io/_uploads/BJv8kKGbp.png)

* Instruction Fetch (IF)
    * It reads the next expected instruction into the buffer.
    
* Instruction Decode/Register Read (ID)
    * Instruction decoding, in which determines opcode and operand specifiers
    * Calculate Operand, in which calculates effective address of each source operand
    * Retch operand,fetch each operand from memory
    
* ALU Execute (EX)
    * It performs indicated operation

* Memory Access (MEM)
    * It accesses memory
    
* Write Back (WB)
    * It stores the result


![](https://hackmd.io/_uploads/SyvB6FfWa.png)


## Pipeline instructions with [my code](https://github.com/BrianCheng-TheLegend/2023_ComputerArchitecture/blob/main/Hw01/Hw01.s)
#### Risc-V Assembly
```clike=
li a7,1
```
#### Disassembled
```clike=
0:        00100893        addi x17 x0 1
```

#### Instruction Fetch (IF)
![](https://hackmd.io/_uploads/SJhU8cfZ6.png)
PC input adderss is `0x0000004`,and 
The instruction translated to RISC-V CPU will be `0x00100893`
And the I-Format instruction `addi` is as following.
We translate `0x00100893` to the instruction memory output.

| imm[11:0]    | rs1   | funct3 | rd    | opcode  |
| ------------ | ----- | ------ | ----- | ------- |
| 000000000001 | 00000 | 000    | 10001 | 0010011 |


#### Instruction Decode/Register Read (ID)
![](https://hackmd.io/_uploads/BydoL9GW6.png)
In this stage insturction will be decode.
`R1 idx = 0x00`,`R2 idx = 0x01`,`Reg out 1 = 0x00000000`,`Reg out 2 = 0x00000000`
And `immdeiate` will send to next stage.

#### ALU Execute (EX)
![](https://hackmd.io/_uploads/Bkpzw5G-T.png)
We chose `add` instruction from these four [MUX(multiplexer)](https://en.wikipedia.org/wiki/Multiplexer),and the `op1 = 0x00000000` and `op2 = 0x00000001` ,the result of this will be `Res = 0x00000001`

#### Memory Access (MEM)
![](https://hackmd.io/_uploads/rytPv5zbT.png)
The red light in Memory stage represent this stage we will not store data to memory.
#### Write Back (WB)
![](https://hackmd.io/_uploads/BJp9v5G-T.png)
In this stage we will store `0x00000001` to destination register



## Pipeline Hazard
Hazard is a situation that prevent starting the next instruction in the next clock cycle
(1) Structural hazard
 * Two or more instructions in pipeline compete for access to a single physical resource.
 * A required resource is busy
 
(2) Data hazard
 * Data dependency between instructions
 * Need to wait for previous instruction to complete its data write

(3) Control hazard
 * Flow of execution depends on previous instruction

### Structural Hazard
* Problem
     * Two or more instructions in pipeline compete for access to a single physical resource.
     * Like the picture below, we can see the regfile are used in ID and WB in clock cycles
![](https://hackmd.io/_uploads/SkPQeKfWp.png)
![](https://hackmd.io/_uploads/r1fQfYMb6.png)

    * Since each instruction can only 
        read : two operands in decode stage
        write : one value in write back stage
    * Avoid Structural hazard by having separate  ports
* Solution
    * Build RegFile with independent read and write ports
* Conclusion
    * Read and Write to registers during same clock cycle is okay

### Data Hazard
* Problem 
    * Conflict for use of a resource
    * In RISC-V pipeline with a single memory unit
        * Without memory units, instruction fetch would ahve to stall fot that cycle
        -> all other operations in pipeline would have to wait
    * The memory units are used in same Time
![](https://hackmd.io/_uploads/SkZlmtzZa.png)
* Stalls and performance
    * Stalls reduce performance
    * Compiler can arrange code to avoid hazards and stalls
#### R-type instructions
* Solution
    * Forwarding
        * Forward result as soon as it is available,even though it's not stored in RegFile yet
![](https://hackmd.io/_uploads/rkgcLKz-p.png)

#### Loads

* Load delay slot
    * If that instruction uses the resullt of the load then teh hardware will stall for ==one cycle==
* Solution
    * Code Scheduling to avoid Stalls
![](https://hackmd.io/_uploads/SybO_KzWT.png)

### Control Hazard
* Problem
    * Branch determines flow control
![](https://hackmd.io/_uploads/ByN-KtfZT.png)
    * Moving branch comparator to ID stage would add redundant hard ware and introduce new problems
    * Kill instructions after Branch if Taken
        * the instructions beween branch control instructions and labels witll be kill and wasted
![](https://hackmd.io/_uploads/S1v8YKzW6.png)
    * Solution for RISC-V : Branch Prediction
        * guess out come of the branch
![](https://hackmd.io/_uploads/S10kcYfW6.png)

## Find Hazard in my code
As the picture we can see the branch or jump funtion may cause the ==Control hazard==, so if we want to reduce hazard we should reduce the branch or jump we use
```clike=
    lw a6,0(a2)           # load test data to a6
    jal ra,f32_b16_p1     # call fp32 to bf16 function 
    add a5,a6,x0          # store first bfloat in a5
```
![](https://hackmd.io/_uploads/SkV-fcMWp.png)
* Original Execution info from my code
![](https://hackmd.io/_uploads/BJLSAKG-a.png)

* Reduce cycles with remove jump funtion
Replace `jal cl ` with
```
    li a7,4               # set a7 as string mode 
    la a0,str             # load str to a0
    ecall                 # ecall     
```
will cause the better performance in this code
* Optimized Execution info from my code
![](https://hackmd.io/_uploads/BJlOfiz-6.png)



---
## Appendix 1 : Pseudo Instruction
```=
00000000 <main>:
    0:        00100893        addi x17 x0 1
    4:        10000617        auipc x12 0x10000
    8:        ffc60613        addi x12 x12 -4
    c:        00062803        lw x16 0 x12
    10:        054000ef        jal x1 84 <f32_b16_p1>
    14:        000807b3        add x15 x16 x0
    18:        00462803        lw x16 4 x12
    1c:        048000ef        jal x1 72 <f32_b16_p1>
    20:        00080733        add x14 x16 x0
    24:        0d8000ef        jal x1 216 <encoder>
    28:        00098cb3        add x25 x19 x0
    2c:        0e8000ef        jal x1 232 <decoder>
    30:        124000ef        jal x1 292 <Multi_bfloat>
    34:        00200893        addi x17 x0 2
    38:        01500533        add x10 x0 x21
    3c:        00000073        ecall
    40:        100000ef        jal x1 256 <cl>
    44:        00200893        addi x17 x0 2
    48:        01600533        add x10 x0 x22
    4c:        00000073        ecall
    50:        0f0000ef        jal x1 240 <cl>
    54:        00200893        addi x17 x0 2
    58:        01300533        add x10 x0 x19
    5c:        00000073        ecall
    60:        1d00006f        jal x0 464 <exit>

00000064 <f32_b16_p1>:
    64:        01012023        sw x16 0 x2
    68:        000802b3        add x5 x16 x0
    6c:        10000697        auipc x13 0x10000
    70:        fac68693        addi x13 x13 -84
    74:        0006af83        lw x31 0 x13
    78:        01f2f333        and x6 x5 x31
    7c:        0046af83        lw x31 4 x13
    80:        01f2f3b3        and x7 x5 x31
    84:        0006af83        lw x31 0 x13
    88:        07f30463        beq x6 x31 104 <inf_or_zero>
    8c:        00736e33        or x28 x6 x7
    90:        060e0063        beq x28 x0 96 <inf_or_zero>
    94:        0086af83        lw x31 8 x13
    98:        01f3e3b3        or x7 x7 x31
    9c:        00c6af83        lw x31 12 x13
    a0:        01f383b3        add x7 x7 x31
    a4:        0183df13        srli x30 x7 24
    a8:        020f0063        beq x30 x0 32 <no_overflow>
    ac:        0086af83        lw x31 8 x13
    b0:        01f30333        add x6 x6 x31
    b4:        0113d393        srli x7 x7 17
    b8:        0106af83        lw x31 16 x13
    bc:        01f3f3b3        and x7 x7 x31
    c0:        01039393        slli x7 x7 16
    c4:        0140006f        jal x0 20 <f32_b16_p2>

000000c8 <no_overflow>:
    c8:        0103d393        srli x7 x7 16
    cc:        0106af83        lw x31 16 x13
    d0:        01f3f3b3        and x7 x7 x31
    d4:        01039393        slli x7 x7 16

000000d8 <f32_b16_p2>:
    d8:        01f2d293        srli x5 x5 31
    dc:        01f29293        slli x5 x5 31
    e0:        0062e2b3        or x5 x5 x6
    e4:        0072e2b3        or x5 x5 x7
    e8:        00028833        add x16 x5 x0
    ec:        00008067        jalr x0 x1 0

000000f0 <inf_or_zero>:
    f0:        01085813        srli x16 x16 16
    f4:        01081813        slli x16 x16 16
    f8:        00008067        jalr x0 x1 0

000000fc <encoder>:
    fc:        000782b3        add x5 x15 x0
    100:        00070333        add x6 x14 x0
    104:        01035313        srli x6 x6 16
    108:        0062e2b3        or x5 x5 x6
    10c:        000289b3        add x19 x5 x0
    110:        00008067        jalr x0 x1 0

00000114 <decoder>:
    114:        000c82b3        add x5 x25 x0
    118:        10000597        auipc x11 0x10000
    11c:        f2058593        addi x11 x11 -224
    120:        0005a903        lw x18 0 x11
    124:        0122f333        and x6 x5 x18
    128:        0045a903        lw x18 4 x11
    12c:        0122f3b3        and x7 x5 x18
    130:        01039393        slli x7 x7 16
    134:        00030b33        add x22 x6 x0
    138:        00038ab3        add x21 x7 x0
    13c:        00008067        jalr x0 x1 0

00000140 <cl>:
    140:        00400893        addi x17 x0 4
    144:        10000517        auipc x10 0x10000
    148:        efc50513        addi x10 x10 -260
    14c:        00000073        ecall
    150:        00008067        jalr x0 x1 0

00000154 <Multi_bfloat>:
    154:        000a82b3        add x5 x21 x0
    158:        000b0333        add x6 x22 x0
    15c:        0006af83        lw x31 0 x13
    160:        01f2fe33        and x28 x5 x31
    164:        01f373b3        and x7 x6 x31
    168:        007e0e33        add x28 x28 x7
    16c:        0146af83        lw x31 20 x13
    170:        41fe0e33        sub x28 x28 x31
    174:        0062c3b3        xor x7 x5 x6
    178:        01f3d393        srli x7 x7 31
    17c:        01f39393        slli x7 x7 31
    180:        007e6e33        or x28 x28 x7
    184:        00929293        slli x5 x5 9
    188:        0092d293        srli x5 x5 9
    18c:        005e62b3        or x5 x28 x5
    190:        0106af83        lw x31 16 x13
    194:        010f9f93        slli x31 x31 16
    198:        01f2f3b3        and x7 x5 x31
    19c:        01f37e33        and x28 x6 x31
    1a0:        00939393        slli x7 x7 9
    1a4:        0013d393        srli x7 x7 1
    1a8:        0186af83        lw x31 24 x13
    1ac:        01f3e3b3        or x7 x7 x31
    1b0:        0013d393        srli x7 x7 1
    1b4:        008e1e13        slli x28 x28 8
    1b8:        01fe6e33        or x28 x28 x31
    1bc:        001e5e13        srli x28 x28 1
    1c0:        00000db3        add x27 x0 x0
    1c4:        00800d13        addi x26 x0 8
    1c8:        00000333        add x6 x0 x0
    1cc:        0186af83        lw x31 24 x13

000001d0 <loop>:
    1d0:        001d8d93        addi x27 x27 1
    1d4:        001fdf93        srli x31 x31 1
    1d8:        01f3feb3        and x29 x7 x31
    1dc:        000e8463        beq x29 x0 8 <not_add>
    1e0:        01c30333        add x6 x6 x28

000001e4 <not_add>:
    1e4:        001e5e13        srli x28 x28 1
    1e8:        ffad94e3        bne x27 x26 -24 <loop>
    1ec:        0186af83        lw x31 24 x13
    1f0:        01f37eb3        and x29 x6 x31
    1f4:        000e8a63        beq x29 x0 20 <not_overflow>
    1f8:        00131313        slli x6 x6 1
    1fc:        0086af83        lw x31 8 x13
    200:        01f282b3        add x5 x5 x31
    204:        0080006f        jal x0 8 <Mult_end>

00000208 <not_overflow>:
    208:        00231313        slli x6 x6 2

0000020c <Mult_end>:
    20c:        01835313        srli x6 x6 24
    210:        00130313        addi x6 x6 1
    214:        00135313        srli x6 x6 1
    218:        01031313        slli x6 x6 16
    21c:        0172d293        srli x5 x5 23
    220:        01729293        slli x5 x5 23
    224:        0062e2b3        or x5 x5 x6
    228:        000289b3        add x19 x5 x0
    22c:        00008067        jalr x0 x1 0

00000230 <exit>:
    230:        00a00893        addi x17 x0 10
    234:        00000073        ecall
```

## Reference

* [CS61C RISC-V Pipeline Hazards!](https://inst.eecs.berkeley.edu/~cs61c/su20/pdfs/lectures/lec14.pdf)
* [Computer Architecture HW1](https://hackmd.io/@wanghanchi/BkM-53UWi)
* [The RISC-V Instruction Set Manual](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)
* [2023 CS61C](https://cs61c.org/fa23/) 