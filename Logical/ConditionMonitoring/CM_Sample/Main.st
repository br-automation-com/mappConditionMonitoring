// -------------------------------------------------------------------------
//  Version:	1.00 Condition monitoring example																							
//	Changed:	06.11.2019	
// -------------------------------------------------------------------------
PROGRAM _INIT
	// -------------------------------------------------------------------------
	// Point to first module
	CM_data_vis ACCESS ADR(CM_data[1]);
	
	// -------------------------------------------------------------------------
	// Initialize default values
	CM_Analyse.PAR.RecordName := 'CM_Sample:CM_data_analyse';					// Pointer to a data structure (CM_ANALYSE_REC_typ) where the current data is stored
	CM_Analyse.PAR.ModuleName := 'IF6.ST1';										// Module slot, see position in  physical view
	CM_Analyse.PAR.MpRecipe := gRecipeCsvCM;									// mappRecipe handle
	CM_Analyse.PAR.FileDevice := 'USER_DEVICE';									// Device where the data is stored
	CM_Analyse.PAR.MpAlarmXCore := gAlarmXCoreCM;								// mappAlarmX handle
	CM_Analyse.PAR.MpAlarmXHistory := gAlarmXHistoryCM;							// mappAlarmHistoryX handle
	CM_Analyse.PAR.FrequencyStop := MAX_STOP_FREQUENCY;							// Use complete buffer for recording
END_PROGRAM

PROGRAM _CYCLIC
	// -------------------------------------------------------------------------
	// Watch array boundaries and point to current raw data
	IF(visModuleSelection*4 + visChannelSelection > SIZEOF(CM_data)/SIZEOF(CM_data[1]) OR (visModuleSelection*4 + visChannelSelection = 0)) THEN
		visChannelSelection := 1;
	END_IF
	CM_data_vis ACCESS ADR(CM_data[visModuleSelection*4 + visChannelSelection]);
	
	// -------------------------------------------------------------------------
	// Analyse X20CM4810 frequency band
	// -------------------------------------------------------------------------
	CASE StepAutoAnalyze OF
		// -------------------------------------------------------------------------
		// Wait state
		// -------------------------------------------------------------------------
		STEP_AUTO_WAIT:
			IF(EDGEPOS(visStartStopAnalyse)) THEN
				brsmemset(ADR(RmsValuesBuffer), 0, SIZEOF(RmsValuesBuffer) - 1);
				brsmemset(ADR(EnvValuesBuffer), 0, SIZEOF(EnvValuesBuffer) - 1);
				brsmemset(ADR(RmsReferenceBuffer), 0, SIZEOF(RmsReferenceBuffer) - 1);
				brsmemset(ADR(EnvReferenceBuffer), 0, SIZEOF(EnvReferenceBuffer) - 1);
				CM_Analyse.CMD.Analyse := TRUE;
				StepAutoAnalyze := STEP_AUTO_READ;
			END_IF
		// -------------------------------------------------------------------------
		// Read data
		// -------------------------------------------------------------------------
		STEP_AUTO_READ:
			// -------------------------------------------------------------------------
			// New data arrived, move data in buffers
			IF(EDGEPOS(CM_Analyse.STA.DataIsValid)) THEN
				// Make sure array is large enough for data
				IF(CM_Analyse.PAR.FrequencyStart < MAX_STOP_FREQUENCY AND CM_Analyse.PAR.FrequencyStop < MAX_STOP_FREQUENCY) THEN
					RmsValuesBuffer[CM_Analyse.STA.FrequencyValue] := CM_data_analyse.RmsValue;
					EnvValuesBuffer[CM_Analyse.STA.FrequencyValue] := CM_data_analyse.EnvValue;
					RmsReferenceBuffer[CM_Analyse.STA.FrequencyValue] := CM_data_analyse.RmsReference;
					EnvReferenceBuffer[CM_Analyse.STA.FrequencyValue] := CM_data_analyse.EnvReference;
				END_IF
				// Ack data
				CM_Analyse.CMD.Continue := TRUE;
			END_IF
			// Finish current run
			IF(EDGENEG(CM_Analyse.CMD.Analyse)) THEN
				visStartStopAnalyse := FALSE;
				StepAutoAnalyze := STEP_AUTO_WAIT;
			ELSIF(EDGENEG(visStartStopAnalyse)) THEN
				CM_Analyse.CMD.Analyse := FALSE;
				StepAutoAnalyze := STEP_AUTO_WAIT;
			END_IF
	END_CASE;
	
	// Cyclic function call
	fctConMon(ptrConMon := ADR(CM_Analyse));
END_PROGRAM

PROGRAM _EXIT
	CM_Analyse.CMD.ErrorReset := TRUE;
	fctConMon(ptrConMon := ADR(CM_Analyse));
END_PROGRAM

