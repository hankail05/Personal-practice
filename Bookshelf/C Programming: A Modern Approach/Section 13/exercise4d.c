#include <stdio.h>
#include <string.h>

int read_line(char str[], int n);

int main(void)
{
	char s[10];
	
	read_line(s, 10);
	
	printf("%s", s);
	
	return 0;
}

int read_line(char str[], int n)
{
	int ch, i = 0;
	
	while ((ch = getchar()) != '\n')
		if (i < n)
			str[i++] = ch;
	str[i] = '\0';
	return i;
}