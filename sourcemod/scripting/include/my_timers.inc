#if defined _my_timers_included
	#endinput
#endif
#define _my_timers_included

#include <timers>

/**
* Kill timer and set INVALID_HANDLE to handle
*
* @param timer				Timer Handle to kill.
*
* @return					True when handle is close, false when handle is INVALID_HANDLE
*/
stock bool:CloseTimer(&Handle:timer)
{
	if(timer == INVALID_HANDLE)
	{
		return false;
	}
	
	KillTimer(timer);
	timer = INVALID_HANDLE;
	
	return true;
}
