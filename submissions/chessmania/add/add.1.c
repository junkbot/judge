#include <stdio.h>

int main(int argc, char **argv) {
	freopen("add.in","r",stdin);
	freopen("add.out","w",stdout);

	int a,b;
	scanf("%d %d",&a,&b);
	printf("%d\n",a+b);
	return 0;
}
