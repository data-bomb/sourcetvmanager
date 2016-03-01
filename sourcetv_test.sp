//#undef REQUIRE_EXTENSIONS
#include "sourcetvmanager"

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_servercount", Cmd_GetServerCount);
	RegConsoleCmd("sm_selectserver", Cmd_SelectServer);
	RegConsoleCmd("sm_getselectedserver", Cmd_GetSelectedServer);
	RegConsoleCmd("sm_getbotindex", Cmd_GetBotIndex);
	RegConsoleCmd("sm_getbroadcasttick", Cmd_GetBroadcastTick);
	RegConsoleCmd("sm_localstats", Cmd_Localstats);
	RegConsoleCmd("sm_getdelay", Cmd_GetDelay);
	RegConsoleCmd("sm_spectators", Cmd_Spectators);
	RegConsoleCmd("sm_spechintmsg", Cmd_SendHintMessage);
	RegConsoleCmd("sm_specmsg", Cmd_SendMessage);
	RegConsoleCmd("sm_getviewentity", Cmd_GetViewEntity);
	RegConsoleCmd("sm_getvieworigin", Cmd_GetViewOrigin);
	RegConsoleCmd("sm_forcechasecam", Cmd_ForceChaseCameraShot);
	//RegConsoleCmd("sm_forcefixedcam", Cmd_ForceFixedCameraShot);
	RegConsoleCmd("sm_startrecording", Cmd_StartRecording);
	RegConsoleCmd("sm_stoprecording", Cmd_StopRecording);
	RegConsoleCmd("sm_isrecording", Cmd_IsRecording);
	RegConsoleCmd("sm_demofile", Cmd_GetDemoFileName);
	RegConsoleCmd("sm_recordtick", Cmd_GetRecordTick);
	RegConsoleCmd("sm_specstatus", Cmd_SpecStatus);
	RegConsoleCmd("sm_democonsole", Cmd_PrintDemoConsole);
	RegConsoleCmd("sm_botcmd", Cmd_ExecuteStringCommand);
	RegConsoleCmd("sm_speckick", Cmd_KickClient);
}

public SourceTV_OnStartRecording(hltvinstance, const String:filename[], bool:bContinuously)
{
	PrintToServer("Started recording sourcetv #%d demo to %s (continuosly %d)", hltvinstance, filename, bContinuously);
}

public SourceTV_OnStopRecording(hltvinstance, const String:filename[], recordingtick)
{
	PrintToServer("Stopped recording sourcetv #%d demo to %s (%d ticks)", hltvinstance, filename, recordingtick);
}

public Action:Cmd_GetServerCount(client, args)
{
	ReplyToCommand(client, "SourceTV server count: %d", SourceTV_GetHLTVServerCount());
	return Plugin_Handled;
}

public Action:Cmd_SelectServer(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_selectserver <instance id>");
		return Plugin_Handled;
	}
	
	new String:sArg[12];
	GetCmdArg(1, sArg, sizeof(sArg));
	new iInstance = StringToInt(sArg);
	
	SourceTV_SelectHLTVServer(iInstance);
	ReplyToCommand(client, "SourceTV selecting server: %d", iInstance);
	return Plugin_Handled;
}

public Action:Cmd_GetSelectedServer(client, args)
{
	ReplyToCommand(client, "SourceTV selected server: %d", SourceTV_GetSelectedHLTVServer());
	return Plugin_Handled;
}

public Action:Cmd_GetBotIndex(client, args)
{
	ReplyToCommand(client, "SourceTV bot index: %d", SourceTV_GetBotIndex());
	return Plugin_Handled;
}

public Action:Cmd_GetBroadcastTick(client, args)
{
	ReplyToCommand(client, "SourceTV broadcast tick: %d", SourceTV_GetBroadcastTick());
	return Plugin_Handled;
}

public Action:Cmd_Localstats(client, args)
{
	new proxies, slots, specs;
	if (!SourceTV_GetLocalStats(proxies, slots, specs))
	{
		ReplyToCommand(client, "SourceTV local stats: no server selected :(");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "SourceTV local stats: proxies %d - slots %d - specs %d", proxies, slots, specs);
	return Plugin_Handled;
}

public Action:Cmd_GetDelay(client, args)
{
	ReplyToCommand(client, "SourceTV delay: %f", SourceTV_GetDelay());
	return Plugin_Handled;
}

public Action:Cmd_Spectators(client, args)
{
	ReplyToCommand(client, "SourceTV spectator count: %d/%d", SourceTV_GetSpectatorCount(), SourceTV_GetClientCount());
	new String:sName[64];
	for (new i=1;i<=SourceTV_GetClientCount();i++)
	{
		if (!SourceTV_IsClientConnected(i))
			continue;
		
		SourceTV_GetSpectatorName(i, sName, sizeof(sName));
		ReplyToCommand(client, "Client %d: %s", i, sName);
	}
	return Plugin_Handled;
}

public Action:Cmd_SendHintMessage(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_spechintmsg <message>");
		return Plugin_Handled;
	}
	
	new String:sMsg[1024];
	GetCmdArgString(sMsg, sizeof(sMsg));
	StripQuotes(sMsg);
	
	new bool:bSent = SourceTV_BroadcastHintMessage("%s", sMsg);
	ReplyToCommand(client, "SourceTV sending hint message (success %d): %s", bSent, sMsg);
	return Plugin_Handled;
}

public Action:Cmd_SendMessage(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_specmsg <message>");
		return Plugin_Handled;
	}
	
	new String:sMsg[1024];
	GetCmdArgString(sMsg, sizeof(sMsg));
	StripQuotes(sMsg);
	
	new bool:bSent = SourceTV_BroadcastConsoleMessage("%s", sMsg);
	ReplyToCommand(client, "SourceTV sending console message (success %d): %s", bSent, sMsg);
	return Plugin_Handled;
}

public Action:Cmd_GetViewEntity(client, args)
{
	ReplyToCommand(client, "SourceTV view entity: %d", SourceTV_GetViewEntity());
	return Plugin_Handled;
}

public Action:Cmd_GetViewOrigin(client, args)
{
	new Float:pos[3];
	SourceTV_GetViewOrigin(pos);
	ReplyToCommand(client, "SourceTV view origin: %f %f %f", pos[0], pos[1], pos[2]);
	return Plugin_Handled;
}

public Action:Cmd_ForceChaseCameraShot(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_startrecording <target> <ineye>");
		return Plugin_Handled;
	}
	
	new String:sTarget[PLATFORM_MAX_PATH];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	StripQuotes(sTarget);
	new iTarget = FindTarget(client, sTarget, false, false);
	if (iTarget == -1)
		return Plugin_Handled;
	
	new bool:bInEye;
	if (args >= 2)
	{
		new String:sInEye[16];
		GetCmdArg(2, sInEye, sizeof(sInEye));
		StripQuotes(sInEye);
		bInEye = sInEye[0] == '1';
	}
	
	SourceTV_ForceChaseCameraShot(iTarget, 0, 96, -20, (GetRandomFloat()>0.5)?30:-30, bInEye, 20.0);
	ReplyToCommand(client, "SourceTV forcing camera shot on %N.", iTarget);
	return Plugin_Handled;
}

public Action:Cmd_StartRecording(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_startrecording <filename>");
		return Plugin_Handled;
	}
	
	new String:sFilename[PLATFORM_MAX_PATH];
	GetCmdArgString(sFilename, sizeof(sFilename));
	StripQuotes(sFilename);
	
	if (SourceTV_StartRecording(sFilename))
	{
		SourceTV_GetDemoFileName(sFilename, sizeof(sFilename));
		ReplyToCommand(client, "SourceTV started recording to: %s", sFilename);
	}
	else
		ReplyToCommand(client, "SourceTV failed to start recording to: %s", sFilename);
	return Plugin_Handled;
}

public Action:Cmd_StopRecording(client, args)
{
	ReplyToCommand(client, "SourceTV stopped recording %d", SourceTV_StopRecording());
	return Plugin_Handled;
}

public Action:Cmd_IsRecording(client, args)
{
	ReplyToCommand(client, "SourceTV is recording: %d", SourceTV_IsRecording());
	return Plugin_Handled;
}

public Action:Cmd_GetDemoFileName(client, args)
{
	new String:sFileName[PLATFORM_MAX_PATH];
	ReplyToCommand(client, "SourceTV demo file name (%d): %s", SourceTV_GetDemoFileName(sFileName, sizeof(sFileName)), sFileName);
	return Plugin_Handled;
}

public Action:Cmd_GetRecordTick(client, args)
{
	ReplyToCommand(client, "SourceTV recording tick: %d", SourceTV_GetRecordingTick());
	return Plugin_Handled;
}
	
public Action:Cmd_SpecStatus(client, args)
{
	new iSourceTV = SourceTV_GetBotIndex();
	if (!iSourceTV)
		return Plugin_Handled;
	FakeClientCommand(iSourceTV, "status");
	ReplyToCommand(client, "Sent status bot console.");
	return Plugin_Handled;
}

public Action:Cmd_PrintDemoConsole(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_democonsole <message>");
		return Plugin_Handled;
	}
	
	new String:sMsg[1024];
	GetCmdArgString(sMsg, sizeof(sMsg));
	StripQuotes(sMsg);
	
	new bool:bSent = SourceTV_PrintToDemoConsole("%s", sMsg);
	ReplyToCommand(client, "SourceTV printing to demo console (success %d): %s", bSent, sMsg);
	return Plugin_Handled;
}

public Action:Cmd_ExecuteStringCommand(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_botcmd <cmd>");
		return Plugin_Handled;
	}
	
	new String:sCmd[1024];
	GetCmdArgString(sCmd, sizeof(sCmd));
	StripQuotes(sCmd);
	
	new iSourceTV = SourceTV_GetBotIndex();
	if (!iSourceTV)
		return Plugin_Handled;
	FakeClientCommand(iSourceTV, sCmd);
	ReplyToCommand(client, "SourceTV executing command on bot: %s", sCmd);
	return Plugin_Handled;
}

public Action:Cmd_KickClient(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_speckick <index> <reason>");
		return Plugin_Handled;
	}
	
	new String:sIndex[16], String:sMsg[1024];
	GetCmdArg(1, sIndex, sizeof(sIndex));
	StripQuotes(sIndex);
	GetCmdArg(2, sMsg, sizeof(sMsg));
	StripQuotes(sMsg);
	
	new iTarget = StringToInt(sIndex);
	SourceTV_KickClient(iTarget, sMsg);
	ReplyToCommand(client, "SourceTV kicking spectator %d with reason %s", iTarget, sMsg);
	return Plugin_Handled;
}