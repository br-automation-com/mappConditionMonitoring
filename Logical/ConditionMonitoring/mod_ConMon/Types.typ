
TYPE
	CM_ANALYSE_INTERN_typ : 	STRUCT  (*Internal structure*)
		IOChannelName1 : STRING[40];
		IOChannelName2 : STRING[40];
		IOChannelValue : UDINT;
		IOBandNo : USINT;
		StepAnalyseCallback : USINT;
		StepAnalyse : USINT;
		AsIOAccWrite_0 : AsIOAccWrite;
		AsIOAccRead_0 : AsIOAccRead;
		TimerAverageData : TON_10ms;
		TimerStableData : TON_10ms;
		RmsValue : REAL;
		EnvValue : REAL;
		Rms : ARRAY[0..2]OF REAL;
		Env : ARRAY[0..2]OF REAL;
		AverageCnt : USINT;
		oldRmsAlarmStatus : USINT;
		oldEnvAlarmStatus : USINT;
		tmpSTR1 : STRING[80];
		tmpSTR2 : STRING[80];
		idx1 : UDINT;
		idx2 : UDINT;
		MpRecipeCsv_0 : MpRecipeCsv;
		MpRecipeRegPar_0 : MpRecipeRegPar;
		DevName : STRING[80];
		DevLink_0 : DevLink;
		DirInfo_0 : DirInfo;
		DirCreate_0 : DirCreate;
		DevUnlink_0 : DevUnlink;
		MpAlarmXCore_0 : MpAlarmXCore;
		MpAlarmXHistory_0 : MpAlarmXHistory;
		FrequencyBandConfigRead : ARRAY[31..32]OF UINT;
		FrequencyBandDmgFreq60rpmRead : ARRAY[31..32]OF UINT;
		FrequencyBandToleranceRead : ARRAY[31..32]OF UINT;
		FrequencyBandLowerFrequencyRead : ARRAY[31..32]OF UINT;
		FrequencyBandUpperFrequencyRead : ARRAY[31..32]OF UINT;
		FrequencyBandLowerFrequencyWrite : UINT;
		FrequencyBandUpperFrequencyWrite : UINT;
		RecordADR : UDINT;
		RecordLEN : UDINT;
		RecordData : CM_ANALYSE_REC_typ;
	END_STRUCT;
	CM_ANALYSE_REC_typ : 	STRUCT  (*Record structure for analysis*)
		RmsValue : REAL;
		RmsReference : REAL;
		RmsExceededCnt : UDINT;
		RmsStatus : USINT;
		EnvValue : REAL;
		EnvReference : REAL;
		EnvExceededCnt : UDINT;
		EnvStatus : USINT;
		AlarmDisabled : BOOL;
	END_STRUCT;
	CM_ANALYSE_STA_typ : 	STRUCT  (*Status information*)
		State : STRING[80];
		Status : DINT;
		FrequencyValue : UINT;
		FrequencyErrorCount : UDINT;
		FrequencyErrorLast : UINT;
		DataIsValid : BOOL;
	END_STRUCT;
	CM_ANALYSE_PAR_typ : 	STRUCT  (*Parameter for analysis*)
		RecordName : {REDUND_UNREPLICABLE} STRING[80];
		FileDevice : STRING[80];
		MpRecipe : MpComIdentType;
		MpAlarmXCore : MpComIdentType;
		MpAlarmXHistory : MpComIdentType;
		ModuleName : STRING[50];
		ModuleChannel : USINT;
		FrequencyResolution : UINT;
		FrequencyStart : UINT;
		FrequencyStop : UINT;
		RmsLimitInc : REAL;
		RmsLimitLower : REAL;
		RmsLimitUpper : REAL;
		EnvLimitInc : REAL;
		EnvLimitLower : REAL;
		EnvLimitUpper : REAL;
		TimerToStable : USINT;
		Mode : USINT;
	END_STRUCT;
	CM_ANALYSE_CMD_typ : 	STRUCT  (*Command structure*)
		BackupConfig : BOOL;
		RestoreConfig : BOOL;
		Analyse : BOOL;
		Continue : BOOL;
		ErrorReset : BOOL;
	END_STRUCT;
	CM_ANALYSE_typ : 	STRUCT  (*Main structure*)
		CMD : CM_ANALYSE_CMD_typ;
		PAR : CM_ANALYSE_PAR_typ;
		STA : CM_ANALYSE_STA_typ;
		intern : CM_ANALYSE_INTERN_typ;
	END_STRUCT;
	CM_data_type : 	STRUCT  (*Data type for connection to IOs*)
		BrokenWire : BOOL;
		Overflow : BOOL;
		ActualSpeed : REAL;
		CM_Iso10816 : REAL;
		CM_RmsAccRaw : REAL;
		CM_RmsAccEnvelope : REAL;
		CM_RmsVelRaw : REAL;
		CM_RmsVelEnvelope : REAL;
		CM_PeakRaw : REAL;
		CM_RmsRaw : REAL;
		CM_CrestFactorRaw : REAL;
		CM_KutosisRaw : REAL;
		CM_SkewnessRaw : REAL;
		CM_Vdi3822KtRaw : REAL;
		CM_PeakRawRefCalc : REAL;
		CM_RmsRawRefCalc : REAL;
		CM_PeakHighFreq : REAL;
		CM_RmsHighFreq : REAL;
		CM_CrestHighFreq : REAL;
		CM_Vdi3822KtHighFreq : REAL;
		CM_PeakHighFreqRefCalc : REAL;
		CM_RmsHighFreqRefCalc : REAL;
		CM_FreqBand : ARRAY[0..7]OF REAL;
	END_STRUCT;
END_TYPE