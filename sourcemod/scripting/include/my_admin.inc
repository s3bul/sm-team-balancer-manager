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
stock int FindFlagString(const int bits, char[] flags, const int maxSize)
{
	AdminFlag array[AdminFlags_TOTAL];
	int numFlags = FlagBitsToArray(bits, array, AdminFlags_TOTAL);
	if (numFlags > maxSize)
	{
		numFlags = maxSize;
	}
	int i, int c, int numId = 0;
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
