/**
 * Przed dołączeniem tego pliku do pluginu należy ustalić ilość i "nazwy" cvarów, przy pomocy enum o nazwie "eCvars", np.
 * enum eCvars {
 * 	ECEnabled,
 * 	ECLimit
 * }
 * 
 * W pluginie musi się znaleźć metoda
 * public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
 * 	for(int i=0,iCvars=view_as<int>(eCvars); i<iCvars; ++i) {
 * 		eCvars cvarId = view_as<eCvars>(i);
 * 		if(convar == PluginCvar(cvarId).handle) {
 * 			PluginCvar(cvarId).SetPrev(oldValue);
 * 			break;
 * 		}
 * 	}
 * }
 */
#define MAX_CVAR_LENGTH 128

ConVar g_ConVars[eCvars];
char g_ConVarsLastValue[eCvars][MAX_CVAR_LENGTH];
char g_ConVarsPrevValue[eCvars][MAX_CVAR_LENGTH];

methodmap PluginCvar {
	public PluginCvar(eCvars cvarindex) {
		return view_as<PluginCvar>(cvarindex);
	}
	property eCvars index {
		public get() {
			return view_as<eCvars>(this);
		}
	}
	property ConVar handle {
		public get() {
			return g_ConVars[this.index];
		}
		public set(ConVar cvarhandle) {
			g_ConVars[this.index] = cvarhandle;
			g_ConVars[this.index].GetDefault(g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH);
			g_ConVars[this.index].GetDefault(g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH);
			g_ConVars[this.index].AddChangeHook(OnConVarChange);
		}
	}
	property bool BoolLast {
		public get() {
			return view_as<bool>(StringToInt(g_ConVarsLastValue[this.index]));
		}
		public set(bool value) {
			IntToString(view_as<int>(value), g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property int IntLast {
		public get() {
			return StringToInt(g_ConVarsLastValue[this.index]);
		}
		public set(int value) {
			IntToString(value, g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property float FloatLast {
		public get() {
			return StringToFloat(g_ConVarsLastValue[this.index]);
		}
		public set(float value) {
			FloatToString(value, g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property int FlagLast {
		public get() {
			return ReadFlagString(g_ConVarsLastValue[this.index]);
		}
		public set(int value) {
			FindFlagString(value, g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property bool BoolPrev {
		public get() {
			return view_as<bool>(StringToInt(g_ConVarsPrevValue[this.index]));
		}
		public set(bool value) {
			IntToString(view_as<int>(value), g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property int IntPrev {
		public get() {
			return StringToInt(g_ConVarsPrevValue[this.index]);
		}
		public set(int value) {
			IntToString(value, g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property float FloatPrev {
		public get() {
			return StringToFloat(g_ConVarsPrevValue[this.index]);
		}
		public set(float value) {
			FloatToString(value, g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	property int FlagPrev {
		public get() {
			return ReadFlagString(g_ConVarsPrevValue[this.index]);
		}
		public set(int value) {
			FindFlagString(value, g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH);
		}
	}
	public int GetLast(char[] value, const int len) {
		return strcopy(value, len, g_ConVarsLastValue[this.index]);
	}
	public int SetLast(const char[] value) {
		return strcopy(g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH, value);
	}
	public int GetPrev(char[] value, const int len) {
		return strcopy(value, len, g_ConVarsPrevValue[this.index]);
	}
	public int SetPrev(const char[] value) {
		return strcopy(g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH, value);
	}
	public bool IsChanged() {
		return (this.handle.BoolValue != this.BoolPrev || this.handle.IntValue != this.IntPrev || FloatCompare(this.handle.FloatValue, this.FloatPrev) != 0 || this.handle.Flags != this.FlagPrev);
	}
	public int CheckToggle() {
		return view_as<int>(this.handle.BoolValue) - view_as<int>(this.BoolPrev);
	}
}
