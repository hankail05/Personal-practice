#include <stdio.h>

int main()
{
	int i;
	
	i = 9384;
	
	do
	{
		printf("%d ", i);
		i /= 10;
	}
	while (i > 0);
	
	return 0;
}