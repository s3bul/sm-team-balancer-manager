#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

#include <my_admin>

#define PLUGIN_VERSION "1.0.0"

#define DEBUG_PLUGIN

#define int(%1) view_as<int>(%1)
#define view(%1,%2) view_as<%1>(%2)
#define MAX_CVAR_LENGTH 128

public Plugin myinfo = {
	name				= "Team Balancer Manager",
	author			= "Sebul",
	description	= "Balans drużyn",
	version			= PLUGIN_VERSION,
	url				= "http://www.CsDonald.pl"
};

enum eCvars {
	ECEnabled,
	ECMaxSize,
	ECMaxDiff,
	ECMaxCond,
	ECMaxScore,
	ECMaxStreak,
	ECSwitchAfter,
	ECSwitchFreq,
	ECSwitchMin,
	ECTypeTransfer,
	ECTypePoints,
	ECMultiWins,
	ECMultiRowWins,
	ECMultiMVP,
	ECMultiKills,
	ECMultiAssists,
	ECMultiDeaths,
	ECMultiScore,
	ECImmunitySwitch,
	ECImmunityJoin,
	ECImmunityFlags,
	ECPlayerFreq,
	ECPlayerTime,
	ECLimitJoin,
	ECLimitAfter,
	ECLimitMin,
	ECLimitAdmins,
	ECAutoTeamBalance,
	ECLimitTeams
};

ConVar g_ConVars[eCvars];
char g_ConVarsLastValue[eCvars][MAX_CVAR_LENGTH];
char g_ConVarsPrevValue[eCvars][MAX_CVAR_LENGTH];

methodmap PluginCvar {
	public PluginCvar(eCvars cvarindex) {
		return view(PluginCvar, cvarindex);
	}
	property eCvars index {
		public get() {
			return view(eCvars, this);
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
			return view(bool, StringToInt(g_ConVarsLastValue[this.index]));
		}
		public set(bool value) {
			IntToString(int(value), g_ConVarsLastValue[this.index], MAX_CVAR_LENGTH);
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
			return view(bool, StringToInt(g_ConVarsPrevValue[this.index]));
		}
		public set(bool value) {
			IntToString(int(value), g_ConVarsPrevValue[this.index], MAX_CVAR_LENGTH);
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
		return int(this.handle.BoolValue) - int(this.BoolPrev);
	}
}

enum eTeamData {
	ETValidTargets[MAXPLAYERS],
	ETNumTargets,
	ETWins,
	ETRowWins,
	ETSize,
	ETBotSize,
	ETAdminSize,
	ETCond,
	ETKills,
	ETAssists,
	ETDeaths,
	ETScore,
	ETMVP,
	Float:ETKDRatio,
	Float:ETSumKDRatio,
	Float:ETPoints
};

int g_Teams[CS_TEAM_CT+1][eTeamData];

enum ePlayerData {
	EPKills,
	EPAssists,
	EPDeaths,
	EPScore,
	EPMVP,
	Float:EPKDRatio,
	Float:EPBlockTransfer,
	EPTeam,
	bool:EPIsBot,
	bool:EPIsConnected,
	bool:EPIsAdmin,
	Handle:EPPanelTimer
};

int g_Players[MAXPLAYERS+1][ePlayerData];

enum eValues {
	EngineVersion:eVersion,
	bool:bEventsHooked,
	bool:bMaxSizeTeam,
	iRoundNumber,
	iLastSwitchRound,
	iTeamWinner,
	iTeamLoser
};

int g_Wart[eValues];
#if defined DEBUG_PLUGIN
char g_PathDebug[PLATFORM_MAX_PATH];
#endif

public void OnPluginStart() {
	LoadTranslations("tbm.phrases");

	CreateConVar("sm_tbm_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	PluginCvar(ECEnabled).handle = CreateConVar("sm_tbm_enabled", "1", "0: Plugin OFF; 1: ON", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	PluginCvar(ECMaxSize).handle = CreateConVar("sm_tbm_max_size", "0", "x: Maksymalna liczba członków w drużynie; 0: Ustal automatycznie", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECMaxDiff).handle = CreateConVar("sm_tbm_max_diff", "2", "x: Maksymalna różnica w liczbie członków w drużynie", FCVAR_PLUGIN, true, 1.0);
	PluginCvar(ECMaxCond).handle = CreateConVar("sm_tbm_max_cond", "3", "x: Im więcej tym plugin będzie rzadziej reagował", FCVAR_PLUGIN, true, 2.0, true, 8.0);
	PluginCvar(ECMaxScore).handle = CreateConVar("sm_tbm_max_score", "2", "x: Maksymalna dozwolona różnica w wyniku gry", FCVAR_PLUGIN, true, 1.0);
	PluginCvar(ECMaxStreak).handle = CreateConVar("sm_tbm_max_streak", "2", "x: Maksymalna dowzolona ilość wygranych rund z rzędu", FCVAR_PLUGIN, true, 1.0);
	PluginCvar(ECSwitchAfter).handle = CreateConVar("sm_tbm_switch_after", "2", "x: Liczba rund po których zaczyna się transferowanie", FCVAR_PLUGIN, true, 1.0);
	PluginCvar(ECSwitchFreq).handle = CreateConVar("sm_tbm_switch_freq", "2", "x: Co ile rund ma przerzucać graczy", FCVAR_PLUGIN, true, 1.0);
	PluginCvar(ECSwitchMin).handle = CreateConVar("sm_tbm_switch_min", "3", "x: Minimalna liczba graczy na mapie, kiedy zaczyna się transferowanie", FCVAR_PLUGIN, true, 2.0);
	PluginCvar(ECTypeTransfer).handle = CreateConVar("sm_tbm_type_transfer", "1", "x: Im więcej tym plugin będzie agresywniej reagował", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	PluginCvar(ECTypePoints).handle = CreateConVar("sm_tbm_type_points", "0", "0: Tylko fragi; 1: Fragi i asysty; 2: Fragi i punkty; 3: Fragi, asysty i punkty; 4: Tylko punkty; Tylko CS:GO", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	PluginCvar(ECMultiWins).handle = CreateConVar("sm_tbm_multi_wins", "2", "x: Przez ile mnożyć punkty wygranych rund", FCVAR_PLUGIN, true, 0.5, true, 10.0);
	PluginCvar(ECMultiRowWins).handle = CreateConVar("sm_tbm_multi_row_wins", "1", "x: Przez ile mnożyć punkty wygranych rund z rzędu", FCVAR_PLUGIN, true, 0.5, true, 10.0);
	PluginCvar(ECMultiMVP).handle = CreateConVar("sm_tbm_multi_mvp", "0.0", "x >= 0: Jak bardzo zwiększać KD graczy za uzyskane gwiazdki mvp; -1: Brak bonusu za mvp; Tylko CS:GO", FCVAR_PLUGIN, true, -1.0);
	PluginCvar(ECMultiKills).handle = CreateConVar("sm_tbm_multi_kills", "0.0", "x > 0: Przez ile mnożyć fragi graczy przy liczeniu KD; 0: Standardowo", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECMultiAssists).handle = CreateConVar("sm_tbm_multi_assists", "0.0", "x > 0: Przez ile mnożyć asysty graczy przy liczeniu KD; 0: Standardowo; Tylko CS:GO", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECMultiDeaths).handle = CreateConVar("sm_tbm_multi_deaths", "0.0", "x > 0: Przez ile mnożyć śmierci graczy przy liczeniu KD; 0: Standardowo", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECMultiScore).handle = CreateConVar("sm_tbm_multi_score", "0.0", "x > 0: Przez ile mnożyć punkty graczy przy liczeniu KD; 0: Standardowo; Tylko CS:GO", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECImmunitySwitch).handle = CreateConVar("sm_tbm_immunity_switch", "0", "1: Admini będą pomijani w działaniach TBM", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	PluginCvar(ECImmunityJoin).handle = CreateConVar("sm_tbm_immunity_join", "0", "1: Admini będą pomijani przy dołączaniu do drużyn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	PluginCvar(ECImmunityFlags).handle = CreateConVar("sm_tbm_immunity_flags", "", "x: Jakie flagi musi posiadać admin aby mieć immunitet; blank: Obojętnie jaka flaga", FCVAR_PLUGIN);
	PluginCvar(ECPlayerFreq).handle = CreateConVar("sm_tbm_player_freq", "200", "x: Co ile sekund może przerzucać tego samego gracza", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECPlayerTime).handle = CreateConVar("sm_tbm_player_time", "120", "x: Po ilu sekundach po wejściu na serwer gracz może być przenoszony", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECLimitJoin).handle = CreateConVar("sm_tbm_limit_join", "1", "1: Ograniczaj dołączanie do drużyn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	PluginCvar(ECLimitAfter).handle = CreateConVar("sm_tbm_limit_after", "0", "x: Po ilu rundach ograniczać dołączanie", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECLimitMin).handle = CreateConVar("sm_tbm_limit_min", "1", "x: Minimalna liczba graczy, kiedy zaczyna się ograniczanie dołączania", FCVAR_PLUGIN, true, 0.0);
	PluginCvar(ECLimitAdmins).handle = CreateConVar("sm_tbm_limit_admins", "-1", "x >= 0: Wyłączaj przerzucanie graczy gdy na serwerze jest więcej adminów od wartości tego cvara; -1: Brak sprawdzania ilości adminów", FCVAR_PLUGIN, true, -1.0);
	PluginCvar(ECAutoTeamBalance).handle = FindConVar("mp_autoteambalance");
	PluginCvar(ECLimitTeams).handle = FindConVar("mp_limitteams");

	AutoExecConfig(true, "sm_tbm");

	AddCommandListener(CommandJoinTeam, "jointeam");

	g_Wart[eVersion] = GetEngineVersion();
}

public void OnMapStart() {
	ClearGame();
#if defined DEBUG_PLUGIN
	BuildPath(Path_SM, g_PathDebug, PLATFORM_MAX_PATH, "logs/sm_tbm/");
	if(!DirExists(g_PathDebug)) {
		CreateDirectory(g_PathDebug, FPERM_U_READ + FPERM_U_WRITE + FPERM_U_EXEC + FPERM_G_READ + FPERM_G_WRITE + FPERM_G_EXEC);
	}
	char sTmp[64];
	FormatTime(sTmp, 64, "debug_%Y%m%d.log");
	StrCat(g_PathDebug, PLATFORM_MAX_PATH, sTmp);
#endif
}

public void OnConfigsExecuted() {
	if(PluginCvar(ECEnabled).handle.BoolValue == true) {
		if(g_Wart[bEventsHooked] == false) HookEventsForPlugin();
		if(PluginCvar(ECAutoTeamBalance).handle.BoolValue == true) {
			PluginCvar(ECAutoTeamBalance).BoolLast = PluginCvar(ECAutoTeamBalance).handle.BoolValue;
			PluginCvar(ECAutoTeamBalance).handle.BoolValue = false;
		}
		if(PluginCvar(ECLimitTeams).handle.IntValue > 0) {
			PluginCvar(ECLimitTeams).IntLast = PluginCvar(ECLimitTeams).handle.IntValue;
			PluginCvar(ECLimitTeams).handle.IntValue = PluginCvar(ECMaxDiff).handle.IntValue;
		}
	}
	else {
		if(g_Wart[bEventsHooked] == true) UnhookEventsForPlugin();
		PluginCvar(ECAutoTeamBalance).handle.BoolValue = PluginCvar(ECAutoTeamBalance).BoolLast;
		PluginCvar(ECLimitTeams).handle.IntValue = PluginCvar(ECLimitTeams).IntLast;
	}

	ClearGame();
}

void HookEventsForPlugin() {
	HookEvent("player_team", EventPlayerTeam);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("round_prestart", EventRoundPreStartPre, EventHookMode_Pre);
	g_Wart[bEventsHooked] = true;
}

void UnhookEventsForPlugin() {
	UnhookEvent("player_team", EventPlayerTeam);
	UnhookEvent("player_death", EventPlayerDeath);
	UnhookEvent("round_end", EventRoundEnd);
	UnhookEvent("round_prestart", EventRoundPreStartPre, EventHookMode_Pre);
	g_Wart[bEventsHooked] = false;
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	if(convar == PluginCvar(ECEnabled).handle) {
		new check = PluginCvar(ECEnabled).CheckToggle();
		if(check == 1) {
			if(g_Wart[bEventsHooked] == false) HookEventsForPlugin();
			if(PluginCvar(ECAutoTeamBalance).handle.BoolValue == true) {
				PluginCvar(ECAutoTeamBalance).BoolLast = PluginCvar(ECAutoTeamBalance).handle.BoolValue;
				PluginCvar(ECAutoTeamBalance).handle.BoolValue = false;
			}
			if(PluginCvar(ECLimitTeams).handle.IntValue > 0) {
				PluginCvar(ECLimitTeams).IntLast = PluginCvar(ECLimitTeams).handle.IntValue;
				PluginCvar(ECLimitTeams).handle.IntValue = PluginCvar(ECMaxDiff).handle.IntValue;
			}
		}
		else if(check == -1) {
			if(g_Wart[bEventsHooked] == true) UnhookEventsForPlugin();
			PluginCvar(ECAutoTeamBalance).handle.BoolValue = PluginCvar(ECAutoTeamBalance).BoolLast;
			PluginCvar(ECLimitTeams).handle.IntValue = PluginCvar(ECLimitTeams).IntLast;
		}
	}
	else if(convar == PluginCvar(ECAutoTeamBalance).handle) {
		if(PluginCvar(ECAutoTeamBalance).CheckToggle() == 1) {
			PluginCvar(ECAutoTeamBalance).handle.BoolValue = false;
		}
	}
	else if(convar == PluginCvar(ECLimitTeams).handle) {
		if(PluginCvar(ECLimitTeams).handle.IntValue != PluginCvar(ECMaxDiff).handle.IntValue) {
			PluginCvar(ECLimitTeams).handle.IntValue = PluginCvar(ECMaxDiff).handle.IntValue;
		}
	}
}

public OnClientDisconnect_Post(client) {
	g_Players[client][EPTeam] = CS_TEAM_NONE;
	g_Players[client][EPIsBot] = false;
	g_Players[client][EPIsConnected] = false;
	g_Players[client][EPIsAdmin] = false;
	g_Players[client][EPPanelTimer] = INVALID_HANDLE;
}

public OnClientPutInServer(client) {
	g_Players[client][EPTeam] = CS_TEAM_NONE;
	g_Players[client][EPBlockTransfer] = GetEngineTime() + Float:g_ConVars[ECPlayerTime][ConVarValue];
	g_Players[client][EPIsBot] = IsFakeClient(client);
	g_Players[client][EPIsConnected] = true;
	new AdminId:adminId = GetUserAdmin(client);
	g_Players[client][EPIsAdmin] = bool:(adminId != INVALID_ADMIN_ID && GetAdminFlag(adminId, Admin_Generic));
}

public Action:CommandJoinTeam(client, const String:command[], argc) {
	if(!g_ConVars[ECEnabled][ConVarValue] || !g_ConVars[ECLimitJoin][ConVarValue])
		return Plugin_Continue;

	if(g_Players[client][EPIsBot])
		return Plugin_Continue;

	if(g_ConVars[ECImmunityJoin][ConVarValue] && (GetUserFlagBits(client) & g_ConVars[ECImmunityFlags][ConVarValue]))
		return Plugin_Continue;

	if(g_ConVars[ECLimitAfter][ConVarValue] > 0) {
		if(g_Wart[iRoundNumber] <= g_ConVars[ECLimitAfter][ConVarValue])
			return Plugin_Continue;
	}

	GetCountPlayersInTeams();
	if(g_Teams[CS_TEAM_T][ETSize]+g_Teams[CS_TEAM_CT][ETSize] < g_ConVars[ECLimitMin][ConVarValue])
		return Plugin_Continue;

	decl String:text[32];
	if(GetCmdArgString(text, sizeof(text)) < 1)
		return Plugin_Continue;

	new startidx = 0;
	if(text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	new iNewTeam = StringToInt(text[startidx]);
	new iOldTeam = g_Players[client][EPTeam];

	if(iNewTeam == iOldTeam) {
		TBMPrintToChat(client, "%t", "Join the same team");
		TBMShowTeamPanel(client);
		return Plugin_Handled;
	}

	if(iNewTeam < CS_TEAM_T)
		return Plugin_Continue;

	if(Float:g_Players[client][EPBlockTransfer] > GetEngineTime() && iOldTeam >= CS_TEAM_T) {
		TBMPrintToChat(client, "%t", "Stay team");
		TBMShowTeamPanel(client);
		return Plugin_Handled;
	}

	if(g_ConVars[ECMaxSize][ConVarValue] > 0) {
		if(g_Teams[iNewTeam][ETSize] >= g_ConVars[ECMaxSize][ConVarValue]) {
			TBMPrintToChat(client, "%t", "Max size join");
			TBMShowTeamPanel(client);
			return Plugin_Handled;
		}
	}
	else if(g_Teams[iNewTeam][ETSize] >= MaxClients / 2 + IntMax(g_ConVars[ECMaxDiff][ConVarValue], 1)) {
		TBMPrintToChat(client, "%t", "Max size join");
		TBMShowTeamPanel(client);
		return Plugin_Handled;
	}

	new iOpTeam = (iNewTeam == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
	if(g_Teams[iNewTeam][ETSize]-g_Teams[iOpTeam][ETSize] >= g_ConVars[ECMaxDiff][ConVarValue]) {
		TBMPrintToChat(client, "%t", "Max diff join");
		TBMShowTeamPanel(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

TBMShowTeamPanel(client) {
	if(g_Players[client][EPPanelTimer] != INVALID_HANDLE) CloseTimer(g_Players[client][EPPanelTimer]);
	g_Players[client][EPPanelTimer] = CreateTimer(0.8, ShowTeamPanel, GetClientSerial(client));
}

public Action:ShowTeamPanel(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	if(!client || !g_Players[client][EPIsConnected] || g_Players[client][EPIsBot] || !IsClientInGame(client))
		return;

	CloseTimer(g_Players[client][EPPanelTimer]);
	ShowVGUIPanel(client, "team");
}

public EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_Players[client][EPTeam] = GetEventInt(event, "team");
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && g_Players[client][EPIsConnected] && IsClientInGame(client)) g_Players[client][EPDeaths] = GetClientDeaths(client);
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker && g_Players[attacker][EPIsConnected] && IsClientInGame(attacker)) g_Players[attacker][EPKills] = GetClientFrags(attacker);
	if(g_Wart[eVersion] == Engine_CSGO) {
		new assister = GetClientOfUserId(GetEventInt(event, "assister"));
		if(assister && g_Players[assister][EPIsConnected] && IsClientInGame(assister)) g_Players[assister][EPAssists] = CS_GetClientAssists(assister);
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetEventInt(event, "reason") >= 15) {
		ClearGame();
		return;
	}

	new iWinner = GetEventInt(event, "winner");
	new iLooser = (iWinner == CS_TEAM_T) ? CS_TEAM_CT : (iWinner == CS_TEAM_CT) ? CS_TEAM_T : CS_TEAM_NONE;

	++g_Wart[iRoundNumber];

	if(iWinner > CS_TEAM_CT)
		return;

	if(g_Teams[iWinner][ETRowWins] < 1) {
		g_Teams[iLooser][ETRowWins] = 0;
		g_Teams[iWinner][ETRowWins] = 1;
	}
	else {
		++g_Teams[iWinner][ETRowWins];
	}
}

public EventRoundPreStartPre(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!g_ConVars[ECEnabled][ConVarValue])
		return;

	GetCountPlayersInTeams();
	GetKDInTeams();
	g_Teams[CS_TEAM_T][ETWins] = CS_GetTeamScore(CS_TEAM_T);
	g_Teams[CS_TEAM_CT][ETWins] = CS_GetTeamScore(CS_TEAM_CT);
	g_Teams[CS_TEAM_T][ETPoints] = Float:g_Teams[CS_TEAM_T][ETSumKDRatio] + (g_Teams[CS_TEAM_T][ETWins] * Float:g_ConVars[ECMultiWins][ConVarValue]) + (g_Teams[CS_TEAM_T][ETRowWins] * Float:g_ConVars[ECMultiRowWins][ConVarValue]);
	g_Teams[CS_TEAM_CT][ETPoints] = Float:g_Teams[CS_TEAM_CT][ETSumKDRatio] + (g_Teams[CS_TEAM_CT][ETWins] * Float:g_ConVars[ECMultiWins][ConVarValue]) + (g_Teams[CS_TEAM_CT][ETRowWins] * Float:g_ConVars[ECMultiRowWins][ConVarValue]);
	TeamConditions();
#if defined DEBUG_PLUGIN
	LogToFile(g_PathDebug, "Połączeni gracze: %i (max: %i)", GetClientCount(), MaxClients);
	LogToFile(g_PathDebug, "Wielkość drużyn: TT - %i(%i), CT - %i(%i)", g_Teams[CS_TEAM_T][ETSize], g_Teams[CS_TEAM_T][ETBotSize], g_Teams[CS_TEAM_CT][ETSize], g_Teams[CS_TEAM_CT][ETBotSize]);
	LogToFile(g_PathDebug, "Admini: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETAdminSize], g_Teams[CS_TEAM_CT][ETAdminSize]);
	LogToFile(g_PathDebug, "Suma zabić drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETKills], g_Teams[CS_TEAM_CT][ETKills]);
	LogToFile(g_PathDebug, "Suma śmierci drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETDeaths], g_Teams[CS_TEAM_CT][ETDeaths]);
	if(g_Wart[eVersion] == Engine_CSGO) {
		LogToFile(g_PathDebug, "Suma asyst drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETAssists], g_Teams[CS_TEAM_CT][ETAssists]);
		LogToFile(g_PathDebug, "Suma punktów drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETScore], g_Teams[CS_TEAM_CT][ETScore]);
		LogToFile(g_PathDebug, "Suma MVP drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETMVP], g_Teams[CS_TEAM_CT][ETMVP]);
	}
	LogToFile(g_PathDebug, "KD drużyn: TT - %.3f, CT - %.3f", Float:g_Teams[CS_TEAM_T][ETKDRatio], Float:g_Teams[CS_TEAM_CT][ETKDRatio]);
	LogToFile(g_PathDebug, "Suma KD drużyn: TT - %.3f, CT - %.3f", Float:g_Teams[CS_TEAM_T][ETSumKDRatio], Float:g_Teams[CS_TEAM_CT][ETSumKDRatio]);
	LogToFile(g_PathDebug, "Punkty drużyn: TT - %.3f, CT - %.3f", Float:g_Teams[CS_TEAM_T][ETPoints], Float:g_Teams[CS_TEAM_CT][ETPoints]);
	LogToFile(g_PathDebug, "Wygrane drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETWins], g_Teams[CS_TEAM_CT][ETWins]);
	if(g_Teams[CS_TEAM_T][ETRowWins] || g_Teams[CS_TEAM_CT][ETRowWins]) {
		LogToFile(g_PathDebug, "Ostatnie %i rund/y zostały wygrane przez %s", g_Teams[CS_TEAM_T][ETRowWins] > 0 ? g_Teams[CS_TEAM_T][ETRowWins] : g_Teams[CS_TEAM_CT][ETRowWins], g_Teams[CS_TEAM_T][ETRowWins] > 0 ? "TT" : "CT");
	}
	LogToFile(g_PathDebug, "Punkty przewagi drużyn: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETCond], g_Teams[CS_TEAM_CT][ETCond]);
	switch(g_Wart[iTeamWinner]) {
		case CS_TEAM_T: LogToFile(g_PathDebug, "Drużyna wygrywająca to TT");
		case CS_TEAM_CT: LogToFile(g_PathDebug, "Drużyna wygrywająca to CT");
		default: LogToFile(g_PathDebug, "Drużyny są zbalansowane");
	}
	LogToFile(g_PathDebug, "================================================");
#endif

	if(!g_Wart[bMaxSizeTeam]) {
		if(g_Wart[iRoundNumber] < g_ConVars[ECSwitchAfter][ConVarValue])
			return;

		if(g_Wart[iRoundNumber]-g_Wart[iLastSwitchRound] < g_ConVars[ECSwitchFreq][ConVarValue])
			return;

		if(g_Teams[CS_TEAM_T][ETSize]+g_Teams[CS_TEAM_CT][ETSize] < g_ConVars[ECSwitchMin][ConVarValue])
			return;
	}

	GetValidTargets(CS_TEAM_T);
	GetValidTargets(CS_TEAM_CT);

	TBMPrintToChatAll("%t", "TBM Info");

	if(g_Wart[iTeamWinner]) {
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== TRANSFER ===");
		LogToFile(g_PathDebug, "Ilość graczy do transferu: TT - %i, CT - %i", g_Teams[CS_TEAM_T][ETNumTargets], g_Teams[CS_TEAM_CT][ETNumTargets]);
#endif
		if(g_Wart[bMaxSizeTeam]) {
#if defined DEBUG_PLUGIN
			LogToFile(g_PathDebug, "=== ZBYT DUŻA RÓŻNICA WIELKOŚCI DRUŻYN ===");
#endif
			doTransfer();
		}
		else {
			switch(g_ConVars[ECTypeTransfer][ConVarValue]) {
				case 3: {
					if(g_Teams[g_Wart[iTeamWinner]][ETBotSize]+RoundToCeil(g_ConVars[ECMaxDiff][ConVarValue] * 0.5) < g_Teams[g_Wart[iTeamLoser]][ETBotSize])
						doSwitch();
					else
						doTransfer();
				}
				case 2: {
					if(g_Teams[g_Wart[iTeamWinner]][ETBotSize] < g_Teams[g_Wart[iTeamLoser]][ETBotSize])
						doSwitch();
					else
						doTransfer();
				}
				default: {
					if(g_Teams[g_Wart[iTeamWinner]][ETBotSize] <= g_Teams[g_Wart[iTeamLoser]][ETBotSize])
						doSwitch();
					else
						doTransfer();
				}
			}
		}
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "================================================");
#endif
	}
}

TBMPrintToChat(client, const String:sMessage[], any:...) {
	decl String:sTxt[192];

	SetGlobalTransTarget(client);
	VFormat(sTxt, sizeof(sTxt), sMessage, 3);

	PrintToChat(client, "[TBM] %s", sTxt);
}

TBMPrintToChatAll(const String:sMessage[], any:...) {
	decl String:sTxt[192];

	for(new i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsConnected] || g_Players[i][EPIsBot] || !IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i);
		VFormat(sTxt, sizeof(sTxt), sMessage, 2);

		PrintToChat(i, "[TBM] %s", sTxt);
	}
}

TBMPrintToChatAdmins(const String:sMessage[], any:...) {
	decl String:sTxt[192];

	for(new i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsAdmin] || !g_Players[i][EPIsConnected] || g_Players[i][EPIsBot] || !IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i);
		VFormat(sTxt, sizeof(sTxt), sMessage, 2);

		PrintToChat(i, "[TBM] %s", sTxt);
	}
}

doTransfer() {
	if(g_Teams[g_Wart[iTeamWinner]][ETSize] <= 1) {
		TBMPrintToChatAll("%t %t", "No move player", "need players win");
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== %T %T ===", "No move player", LANG_SERVER, "need players win", LANG_SERVER);
#endif
		return;
	}
	if(g_Teams[g_Wart[iTeamWinner]][ETNumTargets] <= 1) {
		TBMPrintToChatAll("%t %t", "No move player", "no valid target win");
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== %T %T ===", "No move player", LANG_SERVER, "no valid target win", LANG_SERVER);
#endif
		return;
	}

	decl toLoser, w, Float:closestScore;
	new winner;

	if(g_Wart[bMaxSizeTeam]) {
		closestScore = Float:g_Teams[g_Wart[iTeamWinner]][ETPoints];
		for(w=0; w<g_Teams[g_Wart[iTeamWinner]][ETNumTargets]; ++w) {
			toLoser = g_Teams[g_Wart[iTeamWinner]][ETValidTargets][w];
			if(Float:g_Players[toLoser][EPKDRatio] < closestScore) {
				closestScore = Float:g_Players[toLoser][EPKDRatio];
				winner = toLoser;
			}
		}
	}
	else {
		decl Float:myScore;
		closestScore = FloatAbs(Float:g_Teams[g_Wart[iTeamWinner]][ETPoints] - Float:g_Teams[g_Wart[iTeamLoser]][ETPoints]);
		for(w=0; w<g_Teams[g_Wart[iTeamWinner]][ETNumTargets]; ++w) {
			toLoser = g_Teams[g_Wart[iTeamWinner]][ETValidTargets][w];
			myScore = FloatAbs((Float:g_Teams[g_Wart[iTeamWinner]][ETPoints]-Float:g_Players[toLoser][EPKDRatio]) - (Float:g_Teams[g_Wart[iTeamLoser]][ETPoints]+Float:g_Players[toLoser][EPKDRatio]));
			if(myScore < closestScore) {
				closestScore = myScore;
				winner = toLoser;
			}
		}
	}
	if(!winner || !g_Players[winner][EPIsConnected] || !IsClientInGame(winner)) {
		TBMPrintToChatAll("%t", "No target");
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== %T ===", "No target", LANG_SERVER);
#endif
		return;
	}

	g_Wart[iLastSwitchRound] = g_Wart[iRoundNumber];

	decl String:winnerName[MAX_NAME_LENGTH];
	GetClientName(winner, winnerName, MAX_NAME_LENGTH);

	if(g_ConVars[ECLimitAdmins][ConVarValue] > -1 && g_Teams[CS_TEAM_T][ETAdminSize]+g_Teams[CS_TEAM_CT][ETAdminSize] > g_ConVars[ECLimitAdmins][ConVarValue]) {
		TBMPrintToChatAdmins("%t", "Need transfer player", winnerName);
		return;
	}

	TBMPrintToChatAll("%t", "Transfer player", winnerName, (g_Wart[iTeamWinner] == CS_TEAM_T) ? "CT" : "TT");
#if defined DEBUG_PLUGIN
	LogToFile(g_PathDebug, "KD transferowanego gracza: %.3f", Float:g_Players[winner][EPKDRatio]);
	LogToFile(g_PathDebug, "%T", "Transfer player", LANG_SERVER, winnerName, (g_Wart[iTeamWinner] == CS_TEAM_T) ? "CT" : "TT");
#endif

	SwitchClientTeam(winner);

	g_Players[winner][EPBlockTransfer] = GetEngineTime() + Float:g_ConVars[ECPlayerFreq][ConVarValue];
}

doSwitch() {
	if(g_Teams[g_Wart[iTeamWinner]][ETSize] == 0 || g_Teams[g_Wart[iTeamLoser]][ETSize] == 0) {
		TBMPrintToChatAll("%t %t", "No switch players", "need players");
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== %T %T ===", "No switch players", LANG_SERVER, "need players", LANG_SERVER);
#endif
		return;
	}
	if(g_Teams[g_Wart[iTeamWinner]][ETNumTargets] == 0 || g_Teams[g_Wart[iTeamLoser]][ETNumTargets] == 0) {
		TBMPrintToChatAll("%t %t", "No switch players", "no valid targets");
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== %T %T ===", "No switch players", LANG_SERVER, "no valid target win", LANG_SERVER);
#endif
		return;
	}

	decl Float:myScore, toLoser, toWinner, w, l;
	new winner, loser, Float:closestScore = FloatAbs(Float:g_Teams[g_Wart[iTeamWinner]][ETPoints] - Float:g_Teams[g_Wart[iTeamLoser]][ETPoints]);
	for(w=0; w<g_Teams[g_Wart[iTeamWinner]][ETNumTargets]; ++w) {
		toLoser = g_Teams[g_Wart[iTeamWinner]][ETValidTargets][w];
		for(l=0; l<g_Teams[g_Wart[iTeamLoser]][ETNumTargets]; ++l) {
			toWinner = g_Teams[g_Wart[iTeamLoser]][ETValidTargets][l];
			myScore = FloatAbs((Float:g_Teams[g_Wart[iTeamWinner]][ETPoints]+Float:g_Players[toWinner][EPKDRatio]-Float:g_Players[toLoser][EPKDRatio]) - (Float:g_Teams[g_Wart[iTeamLoser]][ETPoints]+Float:g_Players[toLoser][EPKDRatio]-Float:g_Players[toWinner][EPKDRatio]));
			if(myScore < closestScore) {
				closestScore = myScore;
				winner = toLoser;
				loser = toWinner;
			}
		}
	}
	if(!winner || !loser || !g_Players[winner][EPIsConnected] || !g_Players[loser][EPIsConnected] || !IsClientInGame(winner) || !IsClientInGame(loser)) {
		TBMPrintToChatAll("%t", "No target");
#if defined DEBUG_PLUGIN
		LogToFile(g_PathDebug, "=== %T ===", "No target", LANG_SERVER);
#endif
		return;
	}

	g_Wart[iLastSwitchRound] = g_Wart[iRoundNumber];

	decl String:winnerName[MAX_NAME_LENGTH], String:loserName[MAX_NAME_LENGTH];
	GetClientName(winner, winnerName, MAX_NAME_LENGTH);
	GetClientName(loser, loserName, MAX_NAME_LENGTH);

	if(g_ConVars[ECLimitAdmins][ConVarValue] > -1 && g_Teams[CS_TEAM_T][ETAdminSize]+g_Teams[CS_TEAM_CT][ETAdminSize] > g_ConVars[ECLimitAdmins][ConVarValue]) {
		TBMPrintToChatAdmins("%t", "Need switch players", winnerName, loserName);
		return;
	}

	TBMPrintToChatAll("%t", "Switch players", winnerName, loserName);
#if defined DEBUG_PLUGIN
	LogToFile(g_PathDebug, "KD zamienianych graczy: Winner - %.3f, Loser - %.3f", Float:g_Players[winner][EPKDRatio], Float:g_Players[loser][EPKDRatio]);
	LogToFile(g_PathDebug, "%T", "Switch players", LANG_SERVER, winnerName, loserName);
#endif

	SwitchClientTeam(winner);
	SwitchClientTeam(loser);

	g_Players[winner][EPBlockTransfer] = GetEngineTime() + Float:g_ConVars[ECPlayerFreq][ConVarValue];
	g_Players[loser][EPBlockTransfer] = Float:g_Players[winner][EPBlockTransfer];
}

ClearGame() {
	g_Wart[iRoundNumber] = 0;
	g_Wart[iLastSwitchRound] = 0;
	SetValueForTeams(ETRowWins, 0);

	for(new i=1; i<=MAXPLAYERS; ++i) {
		ClearStatsForPlayer(i);
	}
}

GetValidTargets(team, bool:deadonly = false) {
	new num, i, Float:fGameTime = GetEngineTime();
	for(i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsConnected] || g_Players[i][EPIsBot]) continue;
		if(g_Players[i][EPTeam] != team) continue;
		if(Float:g_Players[i][EPBlockTransfer] > fGameTime) continue;
		if(!IsClientInGame(i)) continue;

		if(g_ConVars[ECImmunitySwitch][ConVarValue] && (GetUserFlagBits(i) & g_ConVars[ECImmunityFlags][ConVarValue])) continue;
		if(deadonly && IsPlayerAlive(i)) continue;

		g_Teams[team][ETValidTargets][num++] = i;
	}

	g_Teams[team][ETNumTargets] = num;
}

TeamConditions() {
	g_Wart[bMaxSizeTeam] = false;

	if(g_Teams[CS_TEAM_T][ETSize]-g_Teams[CS_TEAM_CT][ETSize] > g_ConVars[ECMaxDiff][ConVarValue]) {
		g_Wart[iTeamWinner] = CS_TEAM_T;
		g_Wart[iTeamLoser] = CS_TEAM_CT;
		g_Wart[bMaxSizeTeam] = true;
		return;
	}
	if(g_Teams[CS_TEAM_CT][ETSize]-g_Teams[CS_TEAM_T][ETSize] > g_ConVars[ECMaxDiff][ConVarValue]) {
		g_Wart[iTeamWinner] = CS_TEAM_CT;
		g_Wart[iTeamLoser] = CS_TEAM_T;
		g_Wart[bMaxSizeTeam] = true;
		return;
	}

	SetValueForTeams(ETCond, 0);

	if(g_Teams[CS_TEAM_T][ETWins]-g_Teams[CS_TEAM_CT][ETWins] > g_ConVars[ECMaxScore][ConVarValue])
		g_Teams[CS_TEAM_T][ETCond] += g_Teams[CS_TEAM_T][ETWins]-g_Teams[CS_TEAM_CT][ETWins]-g_ConVars[ECMaxScore][ConVarValue];
	else if(g_Teams[CS_TEAM_CT][ETWins]-g_Teams[CS_TEAM_T][ETWins] > g_ConVars[ECMaxScore][ConVarValue])
		g_Teams[CS_TEAM_CT][ETCond] += g_Teams[CS_TEAM_CT][ETWins]-g_Teams[CS_TEAM_T][ETWins]-g_ConVars[ECMaxScore][ConVarValue];

	if(g_Teams[CS_TEAM_T][ETRowWins] > g_ConVars[ECMaxStreak][ConVarValue])
		g_Teams[CS_TEAM_T][ETCond] += g_Teams[CS_TEAM_T][ETRowWins]-g_ConVars[ECMaxStreak][ConVarValue];
	else if(g_Teams[CS_TEAM_CT][ETRowWins] > g_ConVars[ECMaxStreak][ConVarValue])
		g_Teams[CS_TEAM_CT][ETCond] += g_Teams[CS_TEAM_CT][ETRowWins]-g_ConVars[ECMaxStreak][ConVarValue];

	if(g_Teams[CS_TEAM_T][ETSize] > g_Teams[CS_TEAM_CT][ETSize])
		g_Teams[CS_TEAM_T][ETCond] += g_Teams[CS_TEAM_T][ETSize]-g_Teams[CS_TEAM_CT][ETSize];
	else if(g_Teams[CS_TEAM_CT][ETSize] > g_Teams[CS_TEAM_T][ETSize])
		g_Teams[CS_TEAM_CT][ETCond] += g_Teams[CS_TEAM_CT][ETSize]-g_Teams[CS_TEAM_T][ETSize];

	if(Float:g_Teams[CS_TEAM_T][ETKDRatio] > Float:g_Teams[CS_TEAM_CT][ETKDRatio])
		++g_Teams[CS_TEAM_T][ETCond];
	else if(Float:g_Teams[CS_TEAM_CT][ETKDRatio] > Float:g_Teams[CS_TEAM_T][ETKDRatio])
		++g_Teams[CS_TEAM_CT][ETCond];

	if(Float:g_Teams[CS_TEAM_T][ETSumKDRatio] > Float:g_Teams[CS_TEAM_CT][ETSumKDRatio])
		++g_Teams[CS_TEAM_T][ETCond];
	else if(Float:g_Teams[CS_TEAM_CT][ETSumKDRatio] > Float:g_Teams[CS_TEAM_T][ETSumKDRatio])
		++g_Teams[CS_TEAM_CT][ETCond];

	if(IntMax(g_Teams[CS_TEAM_T][ETCond], g_Teams[CS_TEAM_CT][ETCond]) > g_ConVars[ECMaxCond][ConVarValue]) {
		if(g_Teams[CS_TEAM_T][ETCond] > g_Teams[CS_TEAM_CT][ETCond]) {
			g_Wart[iTeamWinner] = CS_TEAM_T;
			g_Wart[iTeamLoser] = CS_TEAM_CT;
		}
		else if(g_Teams[CS_TEAM_T][ETCond] < g_Teams[CS_TEAM_CT][ETCond]) {
			g_Wart[iTeamWinner] = CS_TEAM_CT;
			g_Wart[iTeamLoser] = CS_TEAM_T;
		}
		else {
			g_Wart[iTeamWinner] = CS_TEAM_NONE;
			g_Wart[iTeamLoser] = CS_TEAM_NONE;
		}
	}
	else {
		g_Wart[iTeamWinner] = CS_TEAM_NONE;
		g_Wart[iTeamLoser] = CS_TEAM_NONE;
	}
}

GetKDInTeams() {
	decl i, Float:fTmp, Float:sumMVP, bool:checkMVP;
	SetValueForTeams(ETKills, 0);
	SetValueForTeams(ETAssists, 0);
	SetValueForTeams(ETDeaths, 0);
	SetValueForTeams(ETScore, 0);
	SetValueForTeams(ETMVP, 0);
	SetValueForTeamsF(ETSumKDRatio, 0.0);
	GetScoreForPlayers();
	sumMVP = float(GetMVPForPlayersAndSum());
	checkMVP = bool:(Float:g_ConVars[ECMultiMVP][ConVarValue] >= 0.0 && g_Wart[eVersion] == Engine_CSGO && sumMVP > 1.0);

	for(i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsConnected] || g_Players[i][EPIsBot])
			continue;

		g_Teams[g_Players[i][EPTeam]][ETKills] += g_Players[i][EPKills];
		g_Teams[g_Players[i][EPTeam]][ETAssists] += g_Players[i][EPAssists];
		g_Teams[g_Players[i][EPTeam]][ETDeaths] += g_Players[i][EPDeaths];
		g_Teams[g_Players[i][EPTeam]][ETScore] += g_Players[i][EPScore];
		g_Teams[g_Players[i][EPTeam]][ETMVP] += g_Players[i][EPMVP];

		g_Players[i][EPKDRatio] = GetPlayerPointsToKD(i) / FloatMax(GetDeathsToKD(g_Players[i][EPDeaths]), 0.1);

		if(checkMVP) {
			fTmp = Float:g_Players[i][EPKDRatio] + Float:g_Players[i][EPKDRatio] * (float(g_Players[i][EPMVP])/sumMVP + Float:g_ConVars[ECMultiMVP][ConVarValue]);
			g_Players[i][EPKDRatio] = fTmp;
		}

		fTmp = Float:g_Teams[g_Players[i][EPTeam]][ETSumKDRatio] + Float:g_Players[i][EPKDRatio];
		g_Teams[g_Players[i][EPTeam]][ETSumKDRatio] = fTmp;
	}

	g_Teams[CS_TEAM_NONE][ETKDRatio] = GetTeamPointsToKD(CS_TEAM_NONE) / FloatMax(GetDeathsToKD(g_Teams[CS_TEAM_NONE][ETDeaths]), 0.1);
	g_Teams[CS_TEAM_SPECTATOR][ETKDRatio] = GetTeamPointsToKD(CS_TEAM_SPECTATOR) / FloatMax(GetDeathsToKD(g_Teams[CS_TEAM_SPECTATOR][ETDeaths]), 0.1);
	g_Teams[CS_TEAM_T][ETKDRatio] = GetTeamPointsToKD(CS_TEAM_T) / FloatMax(GetDeathsToKD(g_Teams[CS_TEAM_T][ETDeaths]), 0.1);
	g_Teams[CS_TEAM_CT][ETKDRatio] = GetTeamPointsToKD(CS_TEAM_CT) / FloatMax(GetDeathsToKD(g_Teams[CS_TEAM_CT][ETDeaths]), 0.1);
}

Float:GetPlayerPointsToKD(client) {
	decl Float:pointsF;
	if(g_Wart[eVersion] != Engine_CSGO) {
		pointsF = GetKillsToKD(g_Players[client][EPKills]);
	}
	else {
		switch(g_ConVars[ECTypePoints][ConVarValue]) {
			case 1: pointsF = GetKillsToKD(g_Players[client][EPKills]) + GetAssistsToKD(g_Players[client][EPAssists]);
			case 2: pointsF = GetKillsToKD(g_Players[client][EPKills]) + GetScoreToKD(g_Players[client][EPScore]);
			case 3: pointsF = GetKillsToKD(g_Players[client][EPKills]) + GetAssistsToKD(g_Players[client][EPAssists]) + GetScoreToKD(g_Players[client][EPScore]);
			case 4: pointsF = GetScoreToKD(g_Players[client][EPScore]);
			default: pointsF = GetKillsToKD(g_Players[client][EPKills]);
		}
	}
	return FloatMax(pointsF, 0.0);
}

Float:GetTeamPointsToKD(team) {
	decl Float:pointsF;
	if(g_Wart[eVersion] != Engine_CSGO) {
		pointsF = GetKillsToKD(g_Teams[team][ETKills]);
	}
	else {
		switch(g_ConVars[ECTypePoints][ConVarValue]) {
			case 1: pointsF = GetKillsToKD(g_Teams[team][ETKills]) + GetAssistsToKD(g_Teams[team][ETAssists]);
			case 2: pointsF = GetKillsToKD(g_Teams[team][ETKills]) + GetScoreToKD(g_Teams[team][ETScore]);
			case 3: pointsF = GetKillsToKD(g_Teams[team][ETKills]) + GetAssistsToKD(g_Teams[team][ETAssists]) + GetScoreToKD(g_Teams[team][ETScore]);
			case 4: pointsF = GetScoreToKD(g_Teams[team][ETScore]);
			default: pointsF = GetKillsToKD(g_Teams[team][ETKills]);
		}
	}
	return FloatMax(pointsF, 0.0);
}

Float:GetKillsToKD(kills) {
	new Float:killsF = float(kills);
	if(Float:g_ConVars[ECMultiKills][ConVarValue] > 0.0) {
		return killsF * Float:g_ConVars[ECMultiKills][ConVarValue];
	}
	return killsF;
}

Float:GetAssistsToKD(assists) {
	if(g_Wart[eVersion] != Engine_CSGO) {
		return 0.0;
	}
	new Float:assistsF = float(assists);
	if(Float:g_ConVars[ECMultiAssists][ConVarValue] > 0.0) {
		return assistsF * Float:g_ConVars[ECMultiAssists][ConVarValue];
	}
	return assistsF;
}

Float:GetDeathsToKD(deaths) {
	new Float:deathsF = float(deaths);
	if(Float:g_ConVars[ECMultiDeaths][ConVarValue] > 0.0) {
		return deathsF * Float:g_ConVars[ECMultiDeaths][ConVarValue];
	}
	return deathsF;
}

Float:GetScoreToKD(score) {
	if(g_Wart[eVersion] != Engine_CSGO) {
		return 0.0;
	}
	new Float:scoreF = float(score);
	if(Float:g_ConVars[ECMultiScore][ConVarValue] > 0.0) {
		return scoreF * Float:g_ConVars[ECMultiScore][ConVarValue];
	}
	return scoreF;
}

GetScoreForPlayers() {
	if(g_Wart[eVersion] != Engine_CSGO) {
		return;
	}
	for(new i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsConnected] || g_Players[i][EPIsBot] || !IsClientInGame(i))
			continue;

		g_Players[i][EPScore] = CS_GetClientContributionScore(i);
	}
}

GetMVPForPlayersAndSum() {
	if(g_Wart[eVersion] != Engine_CSGO) {
		return 0;
	}
	new sum, i;
	for(i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsConnected] || g_Players[i][EPIsBot] || !IsClientInGame(i))
			continue;

		g_Players[i][EPMVP] = CS_GetMVPCount(i);
		sum += g_Players[i][EPMVP];
	}
	return sum;
}

GetCountPlayersInTeams() {
	SetValueForTeams(ETSize, 0);
	SetValueForTeams(ETBotSize, 0);
	SetValueForTeams(ETAdminSize, 0);
	new i, num;
	for(i=1; i<=MaxClients; ++i) {
		if(!g_Players[i][EPIsConnected] || !IsClientInGame(i))
			continue;

		++g_Teams[g_Players[i][EPTeam]][ETBotSize];
		if(!g_Players[i][EPIsBot]) ++g_Teams[g_Players[i][EPTeam]][ETSize];
		if(g_Players[i][EPIsAdmin]) ++g_Teams[g_Players[i][EPTeam]][ETAdminSize];
		++num;
	}
	return num;
}

IntMax(value1, value2) {
	if(value1 > value2) return value1;
	return value2;
}

Float:FloatMax(Float:value1, Float:value2) {
	if(value1 > value2) return value1;
	return value2;
}

SetValueForTeams(eTeamData:eData, iVal) {
	g_Teams[CS_TEAM_NONE][eData] = g_Teams[CS_TEAM_SPECTATOR][eData] = g_Teams[CS_TEAM_T][eData] = g_Teams[CS_TEAM_CT][eData] = iVal;
}

SetValueForTeamsF(eTeamData:eData, Float:fVal) {
	g_Teams[CS_TEAM_NONE][eData] = g_Teams[CS_TEAM_SPECTATOR][eData] = g_Teams[CS_TEAM_T][eData] = g_Teams[CS_TEAM_CT][eData] = any:fVal;
}

ClearStatsForPlayer(client) {
	g_Players[client][EPKills] = g_Players[client][EPAssists] = g_Players[client][EPDeaths] = 0;
}

SwitchClientTeam(client) {
	if(IsPlayerAlive(client)) {
		CS_SwitchTeam(client, (g_Players[client][EPTeam] == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T);
		CS_UpdateClientModel(client);
	}
	else {
		ChangeClientTeam(client, (g_Players[client][EPTeam] == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T);
	}
}
