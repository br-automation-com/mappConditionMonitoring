// ********************************* B&R * Application TB-West ***************************************************
//	DESCRIPTION:	Add-on function for B&R condition monitoring module X20CMxxxx																		
//  Version:		1.00																							
//	Changed:		06.09.2019																						
//	Error numbers:	50000	reference data is missing
//																								
//****************************************************************************************************************

FUNCTION fctConMon
	// -------------------------------------------------------------------------
	// Stop analyzing
	IF((ptrConMon.intern.StepAnalyse >= STEP_ANA_DEV_CON) AND (ptrConMon.intern.StepAnalyse <> STEP_ANA_ERR) AND (ptrConMon.CMD.Analyse = FALSE)) THEN
		ptrConMon.STA.State := 'aborted';
		IF(ptrConMon.intern.StepAnalyse <> STEP_ANA_ERR) THEN 
			ptrConMon.intern.StepAnalyse := STEP_ANALYSE_WAIT;					
		END_IF
	END_IF
	// -------------------------------------------------------------------------
	// Reset errors
	IF(ptrConMon.CMD.ErrorReset = TRUE) THEN
		// Free up device link handle
		IF(ptrConMon.intern.DevLink_0.handle <> 0) THEN
			ptrConMon.intern.DevUnlink_0(enable := 1, handle := ptrConMon.intern.DevLink_0.handle);
		END_IF
		ptrConMon.intern.MpRecipeCsv_0(MpLink := ADR(ptrConMon.PAR.MpRecipe), Enable := 0, Load:= FALSE, Save:= FALSE);
		ptrConMon.CMD.ErrorReset := FALSE;
		ptrConMon.intern.StepAnalyse := STEP_ANALYSE_WAIT;				
	END_IF
	// ------------------------------------------------------------------------------
	// Run alarm core function block
	ptrConMon.intern.MpAlarmXCore_0.Enable := TRUE;
	ptrConMon.intern.MpAlarmXCore_0.MpLink := ADR(ptrConMon.PAR.MpAlarmXCore);
	ptrConMon.intern.MpAlarmXCore_0();
	// Run alarm history function block
	ptrConMon.intern.MpAlarmXHistory_0.Enable := TRUE;
	ptrConMon.intern.MpAlarmXHistory_0.MpLink := ADR(ptrConMon.PAR.MpAlarmXHistory);
	ptrConMon.intern.MpAlarmXHistory_0();
	ptrConMon.STA.FrequencyErrorCount := ptrConMon.intern.MpAlarmXCore_0.PendingAlarms;
	// -------------------------------------------------------------------------
	// Load default values for empty parameters
	IF(ptrConMon.PAR.TimerToStable = 0) THEN
		ptrConMon.PAR.TimerToStable := 3;
	END_IF
	IF(ptrConMon.PAR.RmsLimitInc = 0) THEN
		ptrConMon.PAR.RmsLimitInc := 2;
	END_IF
	IF(ptrConMon.PAR.RmsLimitLower = 0) THEN
		ptrConMon.PAR.RmsLimitLower := 10;
	END_IF
	IF(ptrConMon.PAR.RmsLimitUpper = 0) THEN
		ptrConMon.PAR.RmsLimitUpper := 100;
	END_IF
	IF(ptrConMon.PAR.EnvLimitInc = 0) THEN
		ptrConMon.PAR.EnvLimitInc := 2;
	END_IF
	IF(ptrConMon.PAR.EnvLimitLower = 0) THEN
		ptrConMon.PAR.EnvLimitLower := 20;
	END_IF
	IF(ptrConMon.PAR.EnvLimitUpper = 0) THEN
		ptrConMon.PAR.EnvLimitUpper := 100;
	END_IF
	IF(ptrConMon.PAR.ModuleChannel = 0) THEN
		ptrConMon.PAR.ModuleChannel := 1;
	END_IF
	IF(ptrConMon.PAR.FrequencyResolution = 0) THEN
		ptrConMon.PAR.FrequencyResolution := 1;
	END_IF
	IF(ptrConMon.PAR.FrequencyStart = 0) THEN
		ptrConMon.PAR.FrequencyStart := 1;
	END_IF
	
	// -------------------------------------------------------------------------
	// State machine for data handling
	// -------------------------------------------------------------------------
	CASE ptrConMon.intern.StepAnalyse OF
		// -------------------------------------------------------------------------
		// Wait state
		// -------------------------------------------------------------------------
		STEP_ANALYSE_WAIT:	
			ptrConMon.STA.State := 'waiting for command...';
			// -------------------------------------------------------------------------
			// Backup up module configuration data
			IF(ptrConMon.CMD.BackupConfig) THEN
				ptrConMon.intern.IOBandNo := 31;
				ptrConMon.intern.StepAnalyse := STEP_BAC_CFG1;
			END_IF
			// -------------------------------------------------------------------------
			// Start analysation process
			IF(ptrConMon.CMD.Analyse) THEN
				ptrConMon.intern.StepAnalyse := STEP_ANA_DEV_CON;
			END_IF
			// -------------------------------------------------------------------------
			// Restore module configuration data
			IF(ptrConMon.CMD.RestoreConfig) THEN
				ptrConMon.intern.IOBandNo := 31;
				ptrConMon.intern.StepAnalyse := STEP_RES_CFG1;
			END_IF
		// -------------------------------------------------------------------------
		// Read frequency band config data
		// -------------------------------------------------------------------------
		STEP_BAC_CFG1:
			ptrConMon.STA.State := 'backing up configuration...';
			ptrConMon.intern.IOChannelName1 := 'FrequencyBand';
			ptrConMon.intern.IOChannelName2 := 'ConfigRead';
			ptrConMon.intern.StepAnalyseCallback := STEP_BAC_CFG2;
			ptrConMon.intern.StepAnalyse := STEP_IO_READ;
		// -------------------------------------------------------------------------
		// Read normalized damage frequency at 60 rpm
		// -------------------------------------------------------------------------
		STEP_BAC_CFG2:
			ptrConMon.intern.FrequencyBandConfigRead[ptrConMon.intern.IOBandNo] := UDINT_TO_UINT(ptrConMon.intern.AsIOAccRead_0.value);
			ptrConMon.intern.IOChannelName2 := 'DmgFreq60rpmRead';
			ptrConMon.intern.StepAnalyseCallback := STEP_BAC_CFG3;
			ptrConMon.intern.StepAnalyse := STEP_IO_READ;
		// -------------------------------------------------------------------------
		// Read width of the tolerance band
		// -------------------------------------------------------------------------
		STEP_BAC_CFG3:
			ptrConMon.intern.FrequencyBandDmgFreq60rpmRead[ptrConMon.intern.IOBandNo] := UDINT_TO_UINT(ptrConMon.intern.AsIOAccRead_0.value);
			ptrConMon.intern.IOChannelName2 := 'ToleranceRead';
			ptrConMon.intern.StepAnalyseCallback := STEP_BAC_CFG4;
			ptrConMon.intern.StepAnalyse := STEP_IO_READ;
		// -------------------------------------------------------------------------
		// Read lower frequency
		// -------------------------------------------------------------------------
		STEP_BAC_CFG4:
			ptrConMon.intern.FrequencyBandToleranceRead[ptrConMon.intern.IOBandNo] := UDINT_TO_UINT(ptrConMon.intern.AsIOAccRead_0.value);
			ptrConMon.intern.IOChannelName2 := 'LowerFrequencyRead';
			ptrConMon.intern.StepAnalyseCallback := STEP_BAC_CFG5;
			ptrConMon.intern.StepAnalyse := STEP_IO_READ;
		// -------------------------------------------------------------------------
		// Read upper frequency
		// -------------------------------------------------------------------------
		STEP_BAC_CFG5:
			ptrConMon.intern.FrequencyBandLowerFrequencyRead[ptrConMon.intern.IOBandNo] := UDINT_TO_UINT(ptrConMon.intern.AsIOAccRead_0.value);
			ptrConMon.intern.IOChannelName2 := 'UpperFrequencyRead';
			ptrConMon.intern.StepAnalyseCallback := STEP_BAC_CFG6;
			ptrConMon.intern.StepAnalyse := STEP_IO_READ;
		// -------------------------------------------------------------------------
		// Finish backup and proceed with next step
		// -------------------------------------------------------------------------
		STEP_BAC_CFG6:
			ptrConMon.intern.FrequencyBandUpperFrequencyRead[ptrConMon.intern.IOBandNo] := UDINT_TO_UINT(ptrConMon.intern.AsIOAccRead_0.value);
			// Switch between last and second to last bands
			IF(ptrConMon.intern.IOBandNo = 31) THEN
				ptrConMon.intern.IOBandNo := 32;
				ptrConMon.intern.StepAnalyse := STEP_BAC_CFG1;
			ELSE			
				ptrConMon.CMD.BackupConfig := FALSE;
				ptrConMon.STA.State := 'configuration backed up';
				ptrConMon.intern.StepAnalyse := STEP_ANALYSE_WAIT;
			END_IF
		// -------------------------------------------------------------------------
		// Write frequency band config data
		// -------------------------------------------------------------------------
		STEP_RES_CFG1:
			ptrConMon.STA.State := 'restoring new configuration...';
			ptrConMon.intern.IOChannelName1 := 'FrequencyBand';
			ptrConMon.intern.IOChannelName2 := 'Config';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandConfigRead[ptrConMon.intern.IOBandNo];
			ptrConMon.intern.StepAnalyseCallback := STEP_RES_CFG2;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;
		// -------------------------------------------------------------------------
		// Write normalized damage frequency at 60 rpm
		// -------------------------------------------------------------------------
		STEP_RES_CFG2:
			ptrConMon.intern.IOChannelName2 := 'DmgFreq60rpm';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandDmgFreq60rpmRead[ptrConMon.intern.IOBandNo];
			ptrConMon.intern.StepAnalyseCallback := STEP_RES_CFG3;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;	
		// -------------------------------------------------------------------------
		// Write width of the tolerance band
		// -------------------------------------------------------------------------
		STEP_RES_CFG3:
			ptrConMon.intern.IOChannelName2 := 'Tolerance';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandToleranceRead[ptrConMon.intern.IOBandNo];
			ptrConMon.intern.StepAnalyseCallback := STEP_RES_CFG4;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;	
		// -------------------------------------------------------------------------
		// Write lower frequency
		// -------------------------------------------------------------------------
		STEP_RES_CFG4:
			ptrConMon.intern.IOChannelName2 := 'LowerFrequency';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandLowerFrequencyRead[ptrConMon.intern.IOBandNo];
			ptrConMon.intern.StepAnalyseCallback := STEP_RES_CFG5;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;	
		// -------------------------------------------------------------------------
		// Write upper frequency
		// -------------------------------------------------------------------------
		STEP_RES_CFG5:
			ptrConMon.intern.IOChannelName2 := 'UpperFrequency';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandUpperFrequencyRead[ptrConMon.intern.IOBandNo];
			ptrConMon.intern.StepAnalyseCallback := STEP_RES_CFG6;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;	
		// -------------------------------------------------------------------------
		// Finish restore and proceed with next step
		// -------------------------------------------------------------------------
		STEP_RES_CFG6:
			// Switch between last and second to last bands
			IF(ptrConMon.intern.IOBandNo = 31) THEN
				ptrConMon.intern.IOBandNo := 32;
				ptrConMon.intern.StepAnalyse := STEP_RES_CFG1;
			ELSE			
				ptrConMon.CMD.RestoreConfig := FALSE;
				ptrConMon.STA.State := 'configuration restored';
				ptrConMon.intern.StepAnalyse := STEP_ANALYSE_WAIT;
			END_IF					
		// -------------------------------------------------------------------------
		// Check file device name for data storage
		// -------------------------------------------------------------------------
		STEP_ANA_DEV_CON:
			// Proceed to next step if file device is not required
			IF(ptrConMon.PAR.Mode = MODE_NONE) THEN
				ptrConMon.intern.StepAnalyse := STEP_ANA_CFG_READ;
			ELSE				
				ptrConMon.STA.State := 'process file device...';

				// -------------------------------------------------------------------------
				// Create new file device if not specified by user
				IF((ADR(ptrConMon.PAR.FileDevice) = 0) OR (ptrConMon.PAR.FileDevice = '')) THEN
					ptrConMon.intern.DevName := 'ConMon';
					ptrConMon.intern.DevLink_0(enable := 1, pDevice := ADR(ptrConMon.intern.DevName), pParam := ADR('/DEVICE=C:/ConMon'));
					
					// -------------------------------------------------------------------------
					// File device connected successful
					IF((ptrConMon.intern.DevLink_0.status = ERR_OK) OR (ptrConMon.intern.DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST)) THEN						
						ptrConMon.intern.StepAnalyse := STEP_ANA_DEV_CHK;					
					// Error handling
					ELSIF(ptrConMon.intern.DevLink_0.status <> ERR_FUB_BUSY) THEN
						ptrConMon.STA.Status := FileIoGetSysError();
						ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
					END_IF
				// -------------------------------------------------------------------------
				// Proceed to next step if file device is specified
				ELSE
					ptrConMon.intern.DevName := ptrConMon.PAR.FileDevice;
					ptrConMon.intern.StepAnalyse := STEP_ANA_CFG_READ;
				END_IF
			END_IF
		// -------------------------------------------------------------------------
		// Connect to root path to create new folder
		// -------------------------------------------------------------------------
		STEP_ANA_DEV_CHK:
			ptrConMon.intern.DirInfo_0(enable := 1, pDevice := ADR(ptrConMon.intern.DevName), pPath := ADR(''));
			
			// -------------------------------------------------------------------------
			// File device connected successful
			IF(ptrConMon.intern.DirInfo_0.status = ERR_OK) THEN
				ptrConMon.intern.StepAnalyse := STEP_ANA_CFG_READ;
				// If folder is missing, create it in next step
			ELSIF(ptrConMon.intern.DirInfo_0.status = fiERR_DIR_NOT_EXIST) THEN
				ptrConMon.intern.StepAnalyse := STEP_ANA_DEV_ROT;				
				// Error handling
			ELSIF(ptrConMon.intern.DirInfo_0.status <> ERR_FUB_BUSY) THEN
				ptrConMon.STA.Status := FileIoGetSysError();
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF			
		// -------------------------------------------------------------------------
		// Connect to root path to create new folder
		// -------------------------------------------------------------------------
		STEP_ANA_DEV_ROT:
			ptrConMon.intern.DevLink_0(enable := 1, pDevice := ADR('ConMon_C'), pParam := ADR('/DEVICE=C:'));
			
			// -------------------------------------------------------------------------
			// File device connected successful
			IF(ptrConMon.intern.DevLink_0.status = ERR_OK) THEN
				ptrConMon.intern.StepAnalyse := STEP_ANA_DEV_CRT;
			// Error handling
			ELSIF(ptrConMon.intern.DevLink_0.status <> ERR_FUB_BUSY) THEN
				ptrConMon.STA.Status := FileIoGetSysError();
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF
		// -------------------------------------------------------------------------
		// Create new folder for data
		// -------------------------------------------------------------------------
		STEP_ANA_DEV_CRT:
			ptrConMon.intern.DirCreate_0(enable := 1, pDevice := ADR('ConMon_C'), pName:= ADR('ConMon'));
			
			// -------------------------------------------------------------------------
			// Folder created successful
			IF((ptrConMon.intern.DirCreate_0.status = ERR_OK) OR (ptrConMon.intern.DirCreate_0.status = fiERR_DIR_ALREADY_EXIST)) THEN
				ptrConMon.intern.StepAnalyse := STEP_ANA_DEV_CON;
			// Error handling
			ELSIF(ptrConMon.intern.DirCreate_0.status <> ERR_FUB_BUSY) THEN
				ptrConMon.STA.Status := FileIoGetSysError();
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF
		// -------------------------------------------------------------------------
		// Read current sensor config
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_READ:
			// Get pointer to record data
			IF(ptrConMon.PAR.RecordName <> '') THEN
				PV_xgetadr(ADR(ptrConMon.PAR.RecordName), ADR(ptrConMon.intern.RecordADR), ADR(ptrConMon.intern.RecordLEN));
				ptrConMon.STA.FrequencyErrorLast := 0;
				
				ptrConMon.STA.State := 'prepare sensor config...';
				ptrConMon.intern.IOBandNo := 1;
				ptrConMon.intern.IOChannelName1 := 'SensorConfig0';
				ptrConMon.intern.IOChannelName2 := 'Read';
				ptrConMon.intern.StepAnalyseCallback := STEP_ANA_CFG_WRITE;
				ptrConMon.intern.StepAnalyse := STEP_IO_READ;	
			ELSE 
				ptrConMon.STA.Status := ERR_RECORD_NAME;
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF
		// -------------------------------------------------------------------------
		// Enable IEPE power supply
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_WRITE:
			ptrConMon.intern.IOChannelName1 := 'SensorConfig0';
			ptrConMon.intern.IOChannelName2 := '';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.AsIOAccRead_0.value OR SHL(1, ptrConMon.PAR.ModuleChannel - 1);
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_CFG_RMS;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;			
		// -------------------------------------------------------------------------
		// Write frequency band config data RMS
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_RMS:
			ptrConMon.intern.IOBandNo := 31;
			ptrConMon.intern.FrequencyBandUpperFrequencyWrite := ptrConMon.PAR.FrequencyStart*4;			
			ptrConMon.intern.IOChannelName1 := 'FrequencyBand';
			ptrConMon.intern.IOChannelName2 := 'Config';
			ptrConMon.intern.IOChannelValue := FREQUENCY_BAND_CONFIG_RMS OR (ptrConMon.PAR.ModuleChannel - 1);
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_CFG_ENV;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;
		// -------------------------------------------------------------------------
		// Write frequency band config data envelope
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_ENV:
			ptrConMon.intern.IOBandNo := 32;
			ptrConMon.intern.IOChannelValue := FREQUENCY_BAND_CONFIG_ENV OR (ptrConMon.PAR.ModuleChannel - 1);
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_CFG_LIM;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;		
		// -------------------------------------------------------------------------
		// Calculate frequency band limits for next round
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_LIM:
			ptrConMon.STA.State := 'set new frequency limits...';
			ptrConMon.STA.DataIsValid := FALSE;
			ptrConMon.intern.IOBandNo := 31;
			ptrConMon.intern.FrequencyBandLowerFrequencyWrite := ptrConMon.intern.FrequencyBandUpperFrequencyWrite;
			ptrConMon.intern.FrequencyBandUpperFrequencyWrite := ptrConMon.intern.FrequencyBandLowerFrequencyWrite + ptrConMon.PAR.FrequencyResolution*4;
			ptrConMon.intern.StepAnalyse := STEP_ANA_CFG_LIM_LOW;		
		// -------------------------------------------------------------------------
		// Write frequency band lower frequency limit
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_LIM_LOW:
			ptrConMon.intern.IOChannelName2 := 'LowerFrequency';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandLowerFrequencyWrite;
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_CFG_LIM_UPP;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;		
		// -------------------------------------------------------------------------
		// Write frequency band upper frequency limit
		// -------------------------------------------------------------------------
		STEP_ANA_CFG_LIM_UPP:
			ptrConMon.intern.IOChannelName2 := 'UpperFrequency';
			ptrConMon.intern.IOChannelValue := ptrConMon.intern.FrequencyBandUpperFrequencyWrite;
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_DAT_GEN;
			ptrConMon.intern.StepAnalyse := STEP_IO_WRITE;
		// -------------------------------------------------------------------------
		// Entry point for data collection, switch over between band 31 and 32
		// -------------------------------------------------------------------------
		STEP_ANA_DAT_GEN:
			ptrConMon.STA.State := 'generating data...';
			// Switch between bands
			IF(ptrConMon.intern.IOBandNo = 31) THEN
				ptrConMon.intern.IOBandNo := 32;
				ptrConMon.intern.StepAnalyse := STEP_ANA_CFG_LIM_LOW;	
			ELSE
				ptrConMon.intern.TimerStableData(IN := 0, PT := 0);
				ptrConMon.intern.StepAnalyse := STEP_ANA_DAT_TIM;	
			END_IF
		// -------------------------------------------------------------------------
		// Wait for data to stabilize
		// -------------------------------------------------------------------------
		STEP_ANA_DAT_TIM:
			// Set current frequency, wait for data to stabilize
			ptrConMon.STA.FrequencyValue := ptrConMon.intern.FrequencyBandLowerFrequencyWrite/4 + ptrConMon.PAR.FrequencyResolution/2;
			ptrConMon.intern.TimerStableData(IN := 1, PT := ptrConMon.PAR.TimerToStable*100);
					
			IF(ptrConMon.intern.TimerStableData.Q) THEN
				ptrConMon.intern.AverageCnt := 0;
				ptrConMon.intern.StepAnalyse := STEP_ANA_DAT_RMS;
			END_IF
		// -------------------------------------------------------------------------
		// Wait for data refresh from module (every 300ms)
		// -------------------------------------------------------------------------
		STEP_ANA_DAT_RMS:
			// Wait for next data (350ms) before 
			ptrConMon.intern.TimerAverageData(IN := 1, PT := 35);		
					
			IF(ptrConMon.intern.TimerAverageData.Q) THEN
				// Reset timer, read RMS data
				ptrConMon.intern.TimerAverageData(IN := 0, PT := 35);
				ptrConMon.intern.IOBandNo := 31;
				ptrConMon.intern.IOChannelName1 := 'FrequencyBand';
				ptrConMon.intern.IOChannelName2 := '';
				ptrConMon.intern.StepAnalyseCallback := STEP_ANA_DAT_ENV;
				ptrConMon.intern.StepAnalyse := STEP_IO_READ;
			END_IF		
		// -------------------------------------------------------------------------
		// Store current RMS value in buffer
		// -------------------------------------------------------------------------
		STEP_ANA_DAT_ENV:
			ptrConMon.intern.Rms[ptrConMon.intern.AverageCnt] := UDINT_TO_REAL(ptrConMon.intern.AsIOAccRead_0.value);
			// Switch to ENV band and read ENV value
			ptrConMon.intern.IOBandNo := 32;
			ptrConMon.intern.IOChannelName1 := 'FrequencyBand';
			ptrConMon.intern.IOChannelName2 := '';
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_DAT_AVE;
			ptrConMon.intern.StepAnalyse := STEP_IO_READ;
		// -------------------------------------------------------------------------
		// Creating average value
		// -------------------------------------------------------------------------
		STEP_ANA_DAT_AVE:
			// Store current ENV value in buffer
			ptrConMon.intern.Env[ptrConMon.intern.AverageCnt]	:= UDINT_TO_REAL(ptrConMon.intern.AsIOAccRead_0.value);	
			
			// -------------------------------------------------------------------------
			// If we dont have enough data (3) take another round
			IF(ptrConMon.intern.AverageCnt < 2) THEN
				ptrConMon.intern.AverageCnt := ptrConMon.intern.AverageCnt + 1;
				ptrConMon.intern.StepAnalyse := STEP_ANA_DAT_RMS;
			// -------------------------------------------------------------------------
			// Three RMS and ENV values in buffer
			ELSE
				// Build average for RMS and ENV
				ptrConMon.intern.RmsValue := (ptrConMon.intern.Rms[0]+ptrConMon.intern.Rms[1]+ptrConMon.intern.Rms[2])/3;
				ptrConMon.intern.EnvValue := (ptrConMon.intern.Env[0]+ptrConMon.intern.Env[1]+ptrConMon.intern.Env[2])/3;
				
				// -------------------------------------------------------------------------
				// Free running mode
				IF(ptrConMon.PAR.Mode = MODE_NONE) THEN
					// Reset old user data, move new data over
					brsmemset(ADR(ptrConMon.intern.RecordData), 0, SIZEOF(ptrConMon.intern.RecordData));
					ptrConMon.intern.RecordData.EnvValue := ptrConMon.intern.EnvValue;
					ptrConMon.intern.RecordData.RmsValue := ptrConMon.intern.RmsValue;
					brsmemcpy(ptrConMon.intern.RecordADR, ADR(ptrConMon.intern.RecordData), SIZEOF(ptrConMon.intern.RecordData));
					ptrConMon.intern.StepAnalyse := STEP_ANA_DAT_ACK;
				// -------------------------------------------------------------------------
				// Reference and analysing mode
				ELSE
					// Create file name with module name and channel data
					ptrConMon.intern.idx2 := 0;
					brsmemset(ADR(ptrConMon.intern.tmpSTR1), 0, SIZEOF(ptrConMon.intern.tmpSTR1));
					brsmemset(ADR(ptrConMon.intern.tmpSTR2), 0, SIZEOF(ptrConMon.intern.tmpSTR2));
					FOR ptrConMon.intern.idx1 := 0 TO brsstrlen(ADR(ptrConMon.PAR.ModuleName)) DO
						IF(brsmemcmp(ADR(ptrConMon.PAR.ModuleName) + ptrConMon.intern.idx1, ADR('.'), 1) <> 0) THEN
							brsmemcpy(ADR(ptrConMon.intern.tmpSTR1) + ptrConMon.intern.idx2, ADR(ptrConMon.PAR.ModuleName) + ptrConMon.intern.idx1, 1);
							ptrConMon.intern.idx2 := ptrConMon.intern.idx2 + 1;
						END_IF
					END_FOR;
					brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR('_'));
					brsitoa(ptrConMon.PAR.ModuleChannel, ADR(ptrConMon.intern.tmpSTR2));
					brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.tmpSTR2));
					brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR('_'));
					brsitoa(ptrConMon.STA.FrequencyValue, ADR(ptrConMon.intern.tmpSTR2));
					brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.tmpSTR2));
					
					ptrConMon.intern.StepAnalyse := STEP_REC_VAR_REG;
				END_IF
			END_IF
		// -------------------------------------------------------------------------
		// Register mapp recipe structure
		// -------------------------------------------------------------------------
		STEP_REC_VAR_REG:
			ptrConMon.intern.MpRecipeRegPar_0(MpLink := ADR(ptrConMon.PAR.MpRecipe), Enable := 1, PVName := ADR(ptrConMon.PAR.RecordName), Category := ADR(ptrConMon.PAR.ModuleName));
			
			// -------------------------------------------------------------------------
			// Structure registered successful
			IF(ptrConMon.intern.MpRecipeRegPar_0.Active = TRUE AND ptrConMon.intern.MpRecipeRegPar_0.Error = FALSE) THEN
				// In referencing mode just store data
				IF(ptrConMon.PAR.Mode = MODE_REFERENCING) THEN
					ptrConMon.STA.State := 'storing reference data...';
					// Create new data set to store in file
					brsmemset(ADR(ptrConMon.intern.RecordData), 0, SIZEOF(ptrConMon.intern.RecordData));
					ptrConMon.intern.RecordData.EnvValue := ptrConMon.intern.EnvValue;
					ptrConMon.intern.RecordData.RmsValue := ptrConMon.intern.RmsValue;
					ptrConMon.intern.RecordData.EnvReference := ptrConMon.intern.EnvValue;
					ptrConMon.intern.RecordData.RmsReference := ptrConMon.intern.RmsValue;
					brsmemcpy(ptrConMon.intern.RecordADR, ADR(ptrConMon.intern.RecordData), SIZEOF(ptrConMon.intern.RecordData));
					ptrConMon.intern.MpRecipeCsv_0.Save := TRUE;
					ptrConMon.intern.StepAnalyse := STEP_REC_LOA_SAV;
					ptrConMon.intern.StepAnalyseCallback := STEP_ANA_DAT_ACK;
				// In analysing mode load reference data first
				ELSE 
					ptrConMon.STA.State := 'loading reference data...';
					ptrConMon.intern.MpRecipeCsv_0.Load := TRUE;
					ptrConMon.intern.StepAnalyse := STEP_REC_LOA_SAV;
					ptrConMon.intern.StepAnalyseCallback := STEP_REC_VAR_CMP;					
				END_IF	
			// -------------------------------------------------------------------------
			// Error handling
			ELSIF(ptrConMon.intern.MpRecipeRegPar_0.Error = TRUE) THEN
				ptrConMon.STA.Status := ptrConMon.intern.MpRecipeRegPar_0.StatusID;
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF
		// -------------------------------------------------------------------------
		// Compare new data to stored reference
		// -------------------------------------------------------------------------
		STEP_REC_VAR_CMP:
			// Move stored data into working memory, assume everything is fine
			brsmemcpy(ADR(ptrConMon.intern.RecordData), ptrConMon.intern.RecordADR, SIZEOF(ptrConMon.intern.RecordData));
			ptrConMon.intern.RecordData.RmsStatus := DATA_STATUS_OK;
			ptrConMon.intern.RecordData.EnvStatus := DATA_STATUS_OK;
			
			// -------------------------------------------------------------------------
			// Check RMS lower limits, nothing happens below this value
			IF(ptrConMon.intern.RmsValue > ptrConMon.PAR.RmsLimitLower) THEN
				// Check RMS upper limits and difference to reference value
				IF((ptrConMon.intern.RmsValue > ptrConMon.PAR.RmsLimitUpper) OR (ptrConMon.intern.RmsValue > ptrConMon.intern.RecordData.RmsReference*ptrConMon.PAR.RmsLimitInc)) THEN
					ptrConMon.intern.RecordData.RmsStatus := DATA_STATUS_EXCEEDED;
					ptrConMon.intern.RecordData.RmsExceededCnt := ptrConMon.intern.RecordData.RmsExceededCnt + 1;
					ptrConMon.STA.FrequencyErrorLast := ptrConMon.STA.FrequencyValue;
				END_IF				
			END_IF
			
			// -------------------------------------------------------------------------
			/// Check ENV lower limits, nothing happens below this value
			IF(ptrConMon.intern.EnvValue > ptrConMon.PAR.EnvLimitLower) THEN
				// Check ENV upper limits and difference to reference value
				IF((ptrConMon.intern.EnvValue > ptrConMon.PAR.EnvLimitUpper) OR (ptrConMon.intern.EnvValue > ptrConMon.intern.RecordData.EnvReference*ptrConMon.PAR.EnvLimitInc)) THEN
					ptrConMon.intern.RecordData.EnvStatus := DATA_STATUS_EXCEEDED;
					ptrConMon.intern.RecordData.EnvExceededCnt := ptrConMon.intern.RecordData.EnvExceededCnt + 1;
					ptrConMon.STA.FrequencyErrorLast := ptrConMon.STA.FrequencyValue;
				END_IF
			END_IF
			
			// -------------------------------------------------------------------------
			// Store new data back
			ptrConMon.STA.State := 'storing latest data...';
			ptrConMon.intern.RecordData.RmsValue := ptrConMon.intern.RmsValue;
			ptrConMon.intern.RecordData.EnvValue := ptrConMon.intern.EnvValue;
			brsmemcpy(ptrConMon.intern.RecordADR, ADR(ptrConMon.intern.RecordData), SIZEOF(ptrConMon.intern.RecordData));
			// Trigger alarm when RMS value is exceeded
			IF(ptrConMon.intern.RecordData.RmsStatus = DATA_STATUS_EXCEEDED) THEN
				MpAlarmXSet(ptrConMon.PAR.MpAlarmXCore, 'RmsExceeded');
			END_IF
			ptrConMon.intern.oldRmsAlarmStatus := ptrConMon.intern.RecordData.RmsStatus;
			// Trigger alarm when ENV value is exceeded
			IF(ptrConMon.intern.RecordData.EnvStatus = DATA_STATUS_EXCEEDED) THEN
				MpAlarmXSet(ptrConMon.PAR.MpAlarmXCore, 'EnvExceeded');
			END_IF
			ptrConMon.intern.oldEnvAlarmStatus := ptrConMon.intern.RecordData.EnvStatus;
			
			ptrConMon.intern.MpRecipeCsv_0.Save := TRUE;
			ptrConMon.intern.StepAnalyse := STEP_REC_LOA_SAV;
			ptrConMon.intern.StepAnalyseCallback := STEP_ANA_DAT_ACK;			
		// -------------------------------------------------------------------------
		// Load or save mapp recipe data
		// -------------------------------------------------------------------------
		STEP_REC_LOA_SAV:
			ptrConMon.intern.MpRecipeCsv_0(MpLink := ADR(ptrConMon.PAR.MpRecipe), Enable := 1, DeviceName := ADR(ptrConMon.intern.DevName), FileName := ADR(ptrConMon.intern.tmpSTR1), Category := ADR(ptrConMon.PAR.ModuleName));
			
			// -------------------------------------------------------------------------
			// Recipe finished successful
			IF(ptrConMon.intern.MpRecipeCsv_0.Active = TRUE AND ptrConMon.intern.MpRecipeCsv_0.CommandDone = TRUE  AND ptrConMon.intern.MpRecipeCsv_0.Error = FALSE) THEN
				ptrConMon.intern.MpRecipeCsv_0(MpLink := ADR(ptrConMon.PAR.MpRecipe), Enable := 1, Load:= FALSE, Save:= FALSE);
				ptrConMon.intern.StepAnalyse := ptrConMon.intern.StepAnalyseCallback;
			// -------------------------------------------------------------------------
			// Error handling
			ELSIF(ptrConMon.intern.MpRecipeCsv_0.Error = TRUE) THEN
				IF((ptrConMon.intern.MpRecipeCsv_0.Load = TRUE) AND (ptrConMon.intern.MpRecipeCsv_0.StatusID = mpRECIPE_ERR_LOAD_DATA)) THEN
					ptrConMon.STA.Status := 50000;
					ptrConMon.STA.State := 'err: reference data missing';
				ELSE
					ptrConMon.STA.Status := ptrConMon.intern.MpRecipeCsv_0.StatusID;
				END_IF
				ptrConMon.intern.MpRecipeCsv_0(MpLink := ADR(ptrConMon.PAR.MpRecipe), Enable := 1, Load := FALSE, Save := FALSE);
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF
		// -------------------------------------------------------------------------
		// Waiting for user to acknoledge new data
		// -------------------------------------------------------------------------
		STEP_ANA_DAT_ACK:
			ptrConMon.STA.DataIsValid := TRUE;
			ptrConMon.STA.State := 'waiting for data acknowledge...';
					
			// -------------------------------------------------------------------------
			// Go to next round until stop frequency is reached
			IF(ptrConMon.CMD.Continue) THEN
				ptrConMon.CMD.Continue := FALSE;
				IF(ptrConMon.intern.FrequencyBandLowerFrequencyWrite >= ptrConMon.PAR.FrequencyStop*4) THEN
					ptrConMon.STA.State := 'analyzing finished';
					ptrConMon.CMD.Analyse := FALSE;
					ptrConMon.intern.StepAnalyse := STEP_ANALYSE_WAIT;					
				ELSE
					ptrConMon.intern.StepAnalyse := STEP_ANA_CFG_LIM;
				END_IF
			END_IF		
		// -------------------------------------------------------------------------
		// Call function block to read module register data
		// -------------------------------------------------------------------------
		STEP_IO_READ:
			// Create variable name with channel data
			brsmemset(ADR(ptrConMon.intern.tmpSTR1), 0, SIZEOF(ptrConMon.intern.tmpSTR1));
			brsmemset(ADR(ptrConMon.intern.tmpSTR2), 0, SIZEOF(ptrConMon.intern.tmpSTR2));
			brsstrcpy(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.IOChannelName1));
			brsitoa(ptrConMon.intern.IOBandNo, ADR(ptrConMon.intern.tmpSTR2));
			brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.tmpSTR2));
			brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.IOChannelName2));
			
			ptrConMon.intern.AsIOAccRead_0(enable := 1, pDeviceName := ADR(ptrConMon.PAR.ModuleName), pChannelName := ADR(ptrConMon.intern.tmpSTR1));
			
			// -------------------------------------------------------------------------
			// Read variable information successful
			IF(ptrConMon.intern.AsIOAccRead_0.status = ERR_OK) THEN
				ptrConMon.intern.StepAnalyse := ptrConMon.intern.StepAnalyseCallback;
			// -------------------------------------------------------------------------
			// Error handling
			ELSIF(ptrConMon.intern.AsIOAccRead_0.status <> ERR_FUB_BUSY) THEN
				ptrConMon.STA.State := 'err: reading reference data failed';
				ptrConMon.STA.Status := ptrConMon.intern.AsIOAccRead_0.status;
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF
		// -------------------------------------------------------------------------
		// Call function block to write module register data
		// -------------------------------------------------------------------------
		STEP_IO_WRITE:
			// Create variable name with channel data
			brsmemset(ADR(ptrConMon.intern.tmpSTR1), 0, SIZEOF(ptrConMon.intern.tmpSTR1));
			brsmemset(ADR(ptrConMon.intern.tmpSTR2), 0, SIZEOF(ptrConMon.intern.tmpSTR2));
			brsstrcpy(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.IOChannelName1));
			brsitoa(ptrConMon.intern.IOBandNo, ADR(ptrConMon.intern.tmpSTR2));
			brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.tmpSTR2));
			brsstrcat(ADR(ptrConMon.intern.tmpSTR1), ADR(ptrConMon.intern.IOChannelName2));
			
			ptrConMon.intern.AsIOAccWrite_0(enable := 1, pDeviceName := ADR(ptrConMon.PAR.ModuleName), pChannelName := ADR(ptrConMon.intern.tmpSTR1), value := ptrConMon.intern.IOChannelValue);
			
			// -------------------------------------------------------------------------
			// Write variable information successful
			IF(ptrConMon.intern.AsIOAccWrite_0.status = ERR_OK) THEN
				ptrConMon.intern.StepAnalyse := ptrConMon.intern.StepAnalyseCallback;
			// -------------------------------------------------------------------------
			// Error handling
			ELSIF(ptrConMon.intern.AsIOAccWrite_0.status <> ERR_FUB_BUSY) THEN
				ptrConMon.STA.State := 'err: writing reference data failed';
				ptrConMon.STA.Status := ptrConMon.intern.AsIOAccWrite_0.status;
				ptrConMon.intern.StepAnalyse := STEP_ANA_ERR;
			END_IF			
		// -------------------------------------------------------------------------
		// Error step, WTF
		// -------------------------------------------------------------------------
		STEP_ANA_ERR:
			brsmemset(ADR(ptrConMon.CMD), 0, SIZEOF(ptrConMon.CMD));
			IF(brsmemcmp(ADR(ptrConMon.STA.State), ADR('err'), 3) <> 0) THEN
				ptrConMon.STA.State := 'error';
			END_IF			
	END_CASE;
	
	fctConMon := FALSE;
END_FUNCTION
