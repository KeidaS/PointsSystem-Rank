#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Points sistem for events",
	author = "KeidaS",
	description = "Gives a point to a player and shows a rank",
	version = "1.0",
	url = "www.hermandadfenix.es"
};

char queryBuffer[3096];

int points[MAXPLAYERS + 1];

bool playerReaded[MAXPLAYERS + 1];

Handle db = INVALID_HANDLE;


public void OnPluginStart(){
	RegConsoleCmd("darpunto", GivePoint);
	RegConsoleCmd("quitarpunto", RemovePoint);
	RegConsoleCmd("puntos", ShowPoints);
	
	ConnectDB();
}

public void ConnectDB() {
	char error[255];
	db = SQL_Connect("rankme", true, error, sizeof(error));
	
	if (db == INVALID_HANDLE) {
		LogError("ERROR CONNECTING TO THE DB");
	} else {
		Format(queryBuffer, sizeof(queryBuffer), "CREATE TABLE IF NOT EXISTS pointsrank (steamid VARCHAR(32) PRIMARY KEY NOT NULL, name varchar(64) NOT NULL, points INTEGER)");
		SQL_TQuery(db, ConnectDBCallback, queryBuffer);
	}
}

public void ConnectDBCallback(Handle owner, Handle hndl, char[] error, any data) {
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR CREATING THE TABLE");
		LogError("%s", error);
	}
}

public void OnMapEnd() {
	for (int i = 0; i <= MAXPLAYERS; i++) {
		points[i] = 0;
		playerReaded[i] = false;
	}
}

public void OnClientDisconnect(int client) {
	points[client] = 0;
	playerReaded[client] = false;
}

public Action:GivePoint(int client, int args) {
	char autorizado[32];
	GetClientAuthId(client, AuthId_Steam2, autorizado, sizeof(autorizado));
	//if (StrEqual(autorizado, "STEAM_1:1:31661148") || StrEqual(autorizado, "STEAM_1:1:66818075") || StrEqual(autorizado, "STEAM_0:0:136338492") || StrEqual(autorizado, "STEAM_1:1:52738396") || StrEqual(autorizado, "STEAM_0:0:101043897")) {
		char name[64];
		if (args < 1) {
			ReplyToCommand(client, "[SM] Uso: !darpunto <nombre>");
			return Plugin_Handled;
		} else {
			GetCmdArg(1, name, sizeof(name));
		}
		decl String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		target_count = ProcessTargetString(
				name,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml);
		if (target_count != 1) {
			PrintToChat(client, "Hay más de un usuario con ese nombre");
			return Plugin_Handled;
		} else {
			char query[254];
			char steamID[32];
			if (!IsFakeClient(target_list[0])) {
				char name1[64];
				GetClientAuthId(target_list[0], AuthId_Steam2, steamID, sizeof(steamID));
				Format(query, sizeof(query), "SELECT points FROM pointsrank WHERE steamid = '%s'", steamID);
				SQL_TQuery(db, GivePointCallback, query, GetClientUserId(target_list[0]));
				GetClientName(target_list[0], name1, sizeof(name1));
				PrintToChat(client, "Le has dado un punto a %s", name1);
				PrintToChatAll("%s ha ganado un punto!", name1);
			}
			return Plugin_Continue;
		}
	/*} else {
		PrintToChat(client, "¿Qué tramas moreno?");
		return Plugin_Handled;
	}*/
}

public void GivePointCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR GETING THE POINTS");
		LogError("%i", error);
	} else if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) {
		InsertClientToTable(client);
	} else {
		points[client] = SQL_FetchInt(hndl, 0) + 1;
		playerReaded[client] = true;
		UpdateRank(client);
	}
}

public void InsertClientToTable(client) {
	char query[254];
	char steamID[32];
	char name[64];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	GetClientName(client, name, sizeof(name));
	Format(query, sizeof(query), "INSERT INTO pointsrank VALUES ('%s', '%s', 1)", steamID, name);
	SQL_TQuery(db, InsertClientToTableCallback, query, GetClientUserId(client));
}

public void InsertClientToTableCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR ADDING USER ON TABLE");
		LogError("%i", error);
	} else {
		points[client] = 1;
		playerReaded[client] = true;
	}
}

public void UpdateRank(int client) {
	char query[254];
	char steamID[32];
	char name[64];
	if (IsClientInGame(client) && !IsFakeClient(client)) {
		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		if (playerReaded[client]) {
			Format(query, sizeof(query), "UPDATE pointsrank SET name = '%s', points = '%i' WHERE steamid = '%s'", name, points[client], steamID);
			SQL_TQuery(db, UpdateRankCallback, query);
		}
	}
}

public void UpdateRankCallback(Handle owner, Handle hndl, char[] error, any data) {
	if (hndl == INVALID_HANDLE) {
		LogError("%s", error);
	}
}

public Action:RemovePoint(int client, int args) {
	char autorizado[32];
	GetClientAuthId(client, AuthId_Steam2, autorizado, sizeof(autorizado));
	//if (StrEqual(autorizado, "STEAM_1:1:31661148") || StrEqual(autorizado, "STEAM_1:1:66818075") || StrEqual(autorizado, "STEAM_0:0:136338492") || StrEqual(autorizado, "STEAM_1:1:52738396") || StrEqual(autorizado, "STEAM_0:0:101043897")) {
		char name[64];
		if (args < 1) {
			ReplyToCommand(client, "[SM] Uso: !quitarpunto <nombre>");
			return Plugin_Handled;
		} else {
			GetCmdArg(1, name, sizeof(name));
		}
		decl String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		target_count = ProcessTargetString(
				name,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml);
		if (target_count <= 0) {
			PrintToChat(client, "Hay más de un usuario con ese nombre");
			return Plugin_Handled;
		} else if (target_count > 1) {
			PrintToChat(client, "Hay más de un usuario con ese nombre");
			return Plugin_Handled;
		} else {
			char query[254];
			char steamID[32];
			char name1[64];
			if (!IsFakeClient(target_list[0])) {
				GetClientAuthId(target_list[0], AuthId_Steam2, steamID, sizeof(steamID));
				Format(query, sizeof(query), "SELECT points FROM pointsrank WHERE steamid = '%s'", steamID);
				SQL_TQuery(db, RemovePointCallback, query, GetClientUserId(target_list[0]));
				GetClientName(target_list[0], name1, sizeof(name1));
				PrintToChat(client, "Le has quitado un punto a %s", name1);
				PrintToChatAll("Se le ha retirado un punto a %s", name1);
			}
			return Plugin_Continue;
		}
	/*} else {
		PrintToChat(client, "¿Qué tramas moreno?");
		return Plugin_Handled;
	}*/
}

public void RemovePointCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR GETING THE POINTS");
		LogError("%i", error);
	} else if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) {
		points[client] = 0;
	} else {
		points[client] = SQL_FetchInt(hndl, 0) - 1;
		playerReaded[client] = true;
		UpdateRank(client);
	}
}

public Action:ShowPoints(int client, int args) {
	Menu menu = new Menu(MenuHandler_Points, MenuAction_Start | MenuAction_Select | MenuAction_End);
	menu.SetTitle("Event ranking");
	menu.AddItem("Points ranking", "Points ranking");
	menu.Display(client, 20);
	PrintToChat(client, "Tienes %i puntos", points[client]);
}

public int MenuHandler_Points(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "Points ranking")) {
			ShowRank(param1, "timeTotal");
		}
	}
}

public void ShowRank(int client, char[] typeRank) {
	char query[254];
	Format(query, sizeof(query), "SELECT name, points FROM pointsrank ORDER BY points DESC LIMIT 999");
	SQL_TQuery(db, ShowRankCallback, query, GetClientUserId(client));
}

public void ShowRankCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR SHOWING THE RANK");
		LogError("%s", error);
	} else {
		int rankPosition;
		int points1;
		char name[64];
		char rank[128];
		Menu menu = new Menu(MenuHandler_ShowRank, MenuAction_Start | MenuAction_Select | MenuAction_End | MenuAction_Cancel);
		menu.SetTitle("Points ranking");
		while (SQL_FetchRow(hndl)) {
			rankPosition++;
			SQL_FetchString(hndl, 0, name, sizeof(name));
			points1 = SQL_FetchInt(hndl, 1);
			Format(rank, sizeof(rank), "%i %s - %i puntos", rankPosition, name, points1);
			menu.AddItem("Rank", rank);
		}
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_ShowRank(Menu menu, MenuAction action, int param1, int param2) {
} 