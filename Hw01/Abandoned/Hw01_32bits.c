#include <stdint.h>
#include <stdio.h>
uint16_t count_leading_zeros(uint32_t x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x55555555 );
    x = ((x >> 2) & 0x3333333) + (x & 0x3333333 /* Fill this! */);
    x = ((x >> 4) + x) & 0x0f0f0f;
    x += (x >> 8);
    x += (x >> 16);

    return (32 - (x & 0x3f));
}

void change(int *a,int *b){
    int c;
    c=*a;
    *a=*b;
    *b=c;
}

int main(){
    int len=13;
    int a[13]={1000,900,800,700,2,3,5,600,500,400,300,200,100};
    int times=0;
    for(int i=0;i<len;i++){
        for(int j=i;j<len;j++){
            if(a[i]>a[j]){
                change(&(a[i]),&(a[j]));
                times++;
            }
        }
    }

    for(int i=0;i<len;i++){
        printf("%d\n",a[i]);
    }
    printf("change %d times\n",times);

    return 0;
}