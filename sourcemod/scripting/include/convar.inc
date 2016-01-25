/**
* public OnConfigsExecuted() {
* 	for(new i=0; i<eCvars; ++i) {
* 		UpdateConVarValue(g_ConVars[i]);
* 	}
* }
* public OnConVarChange(Handle:conVar, const String:oldValue[], const String:newValue[]) {
* 	for(new i=0; i<eCvars; ++i) {
* 		if(conVar == g_ConVars[i][ConVarHandle]) {
* 			UpdateConVarValue(g_ConVars[i]);
* 			break;
* 		}
* 	}
* }
*/
#if defined _convar_included
	#endinput
#endif
#define _convar_included

enum ValueType {
	ValueType_Int = 0,
	ValueType_Bool,
	ValueType_Float,
	ValueType_Flag
};

enum ConVar {
	Handle:ConVarHandle,		// Handle of the convar.
	ValueType:ConVarType,	// Type of value. (int, bool, float)
	any:LastConVarValue,
	any:PrevConVarValue,		// Previous value.
	any:ConVarValue			// The value.
};

stock AddConVar(newCon[ConVar], ValueType:type, ConVarChanged:callback, Handle:conVarHandle) {
	newCon[ConVarHandle] = conVarHandle;
	newCon[ConVarType] = type;

	if(conVarHandle != INVALID_HANDLE) {
		SetConVarDefault(newCon);
		HookConVarChange(conVarHandle, callback);
	}
}

stock AddConVarNoHook(newCon[ConVar], ValueType:type, Handle:conVarHandle) {
	newCon[ConVarHandle] = conVarHandle;
	newCon[ConVarType] = type;

	if(conVarHandle != INVALID_HANDLE) {
		SetConVarDefault(newCon);
	}
}

stock SetConVarDefault(setCon[ConVar]) {
	decl String:defCon[32];
	GetConVarDefault(setCon[ConVarHandle], defCon, 32);
	switch(setCon[ConVarType]) {
		case ValueType_Int:		setCon[ConVarValue] = setCon[PrevConVarValue] = setCon[LastConVarValue] = StringToInt(defCon);
		case ValueType_Bool:		setCon[ConVarValue] = setCon[PrevConVarValue] = setCon[LastConVarValue] = bool:StringToInt(defCon);
		case ValueType_Float:	setCon[ConVarValue] = setCon[PrevConVarValue] = setCon[LastConVarValue] = StringToFloat(defCon);
		case ValueType_Flag:		setCon[ConVarValue] = setCon[PrevConVarValue] = setCon[LastConVarValue] = ReadFlagString(defCon);
	}
}

stock UpdateConVarValue(upCon[ConVar]) {
	upCon[PrevConVarValue] = upCon[ConVarValue];
	switch(upCon[ConVarType]) {
		case ValueType_Int:		upCon[ConVarValue] = GetConVarInt(upCon[ConVarHandle]);
		case ValueType_Bool:		upCon[ConVarValue] = GetConVarBool(upCon[ConVarHandle]);
		case ValueType_Float:	upCon[ConVarValue] = GetConVarFloat(upCon[ConVarHandle]);
		case ValueType_Flag: {
			decl String:flagCon[32];
			GetConVarString(upCon[ConVarHandle], flagCon, 32);
			upCon[ConVarValue] = ReadFlagString(flagCon);
		}
	}
}

stock SetConVarValue(setCon[ConVar], {_,bool,Float}:conVarValue, bool:replicate=false, bool:notify=false) {
	setCon[PrevConVarValue] = setCon[ConVarValue];
	switch(setCon[ConVarType]) {
		case ValueType_Int:		SetConVarInt(setCon[ConVarHandle], _:conVarValue, replicate, notify);
		case ValueType_Bool:		SetConVarBool(setCon[ConVarHandle], bool:conVarValue, replicate, notify);
		case ValueType_Float:	SetConVarFloat(setCon[ConVarHandle], Float:conVarValue, replicate, notify);
		case ValueType_Flag: {
			decl String:flagCon[32];
			FindFlagString(_:conVarValue, flagCon, 32);
			SetConVarString(setCon[ConVarHandle], flagCon, replicate, notify);
		}
	}
	setCon[ConVarValue] = conVarValue;
}

stock bool:IsConVarValueChanged(isCon[ConVar]) {
	return bool:(isCon[PrevConVarValue] != isCon[ConVarValue]);
}

stock CheckToggleConVarValue(cheCon[ConVar]) {
	if(cheCon[PrevConVarValue] && !cheCon[ConVarValue]) {
		return -1;
	}
	else if(!cheCon[PrevConVarValue] && cheCon[ConVarValue]) {
		return 1;
	}
	return 0;
}
