#if defined _my_admin_included
	#endinput
#endif
#define _my_admin_included

#include <admin>

/**
 * Converts a bit string to a string of flag characters.
 *
 * @param bits			Bit string containing the flags.
 * @param flags			Output array to write a string of flag characters.
 * @param maxSize		Maximum size of the string array.
 * @return				Number of flag characters written.
 */
stock FindFlagString(const bits, String:flags[], maxSize)
{
	new AdminFlag:array[AdminFlags_TOTAL];
	new numFlags = FlagBitsToArray(bits, array, AdminFlags_TOTAL);
	if (numFlags > maxSize)
	{
		numFlags = maxSize;
	}
	new i, c, numId = 0;
	for (i = 0; i < numFlags; ++i)
	{
		if(FindFlagChar(array[i], c))
		{
			flags[numId++] = c;
		}
	}
	for (i = numId; i < maxSize; ++i)
	{
		flags[i] = '\0';
	}
	return numId;
}
