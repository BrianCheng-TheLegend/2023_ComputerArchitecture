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

// // The bfloat multiplication still not implement 
// void bfloat_multiplication(int *num){
//     printf("0x%x\n",*num);
//     int mask[]={0x1,0xff,0x7f};
//     int fra=0,exp=0,sig=0;
//     int bn1=0,bn2=0;
//     // fraction
//     bn2 = *num & mask[2];
//     bn2 |= 0x100;
//     mask[2] <<=16;
//     bn1 = *num & mask[2];
//     bn1 >>= 16;
//     bn1 |= 0x100;
//     for(int i=0;i<8;i++){
//         if((bn1 && 1)){
//             fra+=bn2;
//         }
//         bn1>>1;
//         bn2<<1;
//     }
//     // if((fra & 0x8000)>>16)
//     //     fra >>= 9;
//     // else 
//     //     fra >>=8;
//     printf("%x\n",fra);
//     // exponent
//     mask[1] <<= 7;
//     bn2 = *num & mask[1];
//     mask[1] <<= 16;
//     bn1 = *num & mask[1];
//     bn1 >>= 23;
//     bn2 >>= 7;
//     exp=bn1+bn2-127;
//     printf("%x\n",exp);

//     // sign
//     bn1 = 0;
//     bn2 = 0;
//     mask[0] <<= 15;
//     bn2= *num & mask[0];
//     bn2 <<= 16;
//     mask[0] <<= 16;
//     bn1 = *num & mask[0];
//     bn1 ^= bn2;
//     sig=bn1;
//     *num = sig | (fra << 15) | (exp << 22);
// }


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
    // // show num1 binary form and it's value
    // printf("0x%x\n",*np1);
    // printf("%f\n",num1);
    // // show num2 binary form and it's value
    // printf("0x%x\n",*np2);
    // printf("%f\n",num2);
    // add two number together and print the binary form
    *p=encoder(np1,np2);

    bfloat_multiplication(p);
    // printf()
    printf("0x%x\n",*p);
    // // check if num1 and num2 are 0
    // printf("0x%x\n",*np1);
    // printf("0x%x\n",*np2);
    // decode these two nuber to np1 and np2
    // decoder(add,np1,np2);
    // // check if num1 and num2 are expect number
    // printf("0x%x\n",*np1);
    // printf("%f\n",num1);
    // printf("0x%x\n",*np2);
    // printf("%f\n",num2);

    return 0;
}