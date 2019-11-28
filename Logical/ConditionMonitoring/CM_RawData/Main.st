// -------------------------------------------------------------------------
//  Version:	1.00 buffer upload																							
//	Changed:	06.11.2019		
// -------------------------------------------------------------------------
PROGRAM _INIT
	UploadData.paramMain.pModulePath := ADR(CM_buffer.PAR.ModulePath);							// Module slot, see position in  physical view
	UploadData.paramMain.sensitivitySensor01 := CM_buffer.PAR.SensitivitySensor;
	UploadData.paramMain.sensitivitySensor02 := CM_buffer.PAR.SensitivitySensor;
	UploadData.paramMain.sensitivitySensor03 := CM_buffer.PAR.SensitivitySensor;
	UploadData.paramMain.sensitivitySensor04 := CM_buffer.PAR.SensitivitySensor;

	UploadData.paramBufferUpload.nrArrayElements:= SIZEOF(CM_buffer.DAT.xAxis)/SIZEOF(CM_buffer.DAT.xAxis[0]);
	UploadData.paramBufferUpload.pArrayXaxis:= ADR(CM_buffer.DAT.xAxis);
	UploadData.paramBufferUpload.pArrayYaxis:= ADR(CM_buffer.DAT.yAxis);

	step := 0;	
END_PROGRAM

PROGRAM _CYCLIC
	CM_buffer.PAR.Status := UploadData._internal.statusTxt;
	CASE(step) OF
		// ---------------------------------------------------------------------------------------------------------
		// Clear requests 
		// ---------------------------------------------------------------------------------------------------------
		STATE_CLEAR:
			UploadData.enable := 1;
			UploadData.requestBufferLock := FALSE;
			UploadData.uploadBuffer := FALSE;
			CM_buffer.PAR.Status := 'Waiting for module to be ready...';
			IF(UploadData.initDone AND UploadData.moduleCfgUploadDone) THEN
				step := STATE_WAIT;
			END_IF
		// ---------------------------------------------------------------------------------------------------------
		// Wait for new command
		// ---------------------------------------------------------------------------------------------------------
		STATE_WAIT:
			UploadData.cancelBufferUpload := FALSE;
			CM_buffer.PAR.Progress := 0;
			CM_buffer.PAR.VisuBufferEnable := TRUE;
			// Wait for new command
			IF(CM_buffer.CMD.Upload)THEN		
				CM_buffer.PAR.VisuBufferEnable := FALSE;
				step := STATE_LOCK;
			END_IF
		// ---------------------------------------------------------------------------------------------------------
		// Wait for buffer lock
		// ---------------------------------------------------------------------------------------------------------
		STATE_LOCK:
			UploadData.requestBufferLock := TRUE;
			IF(UploadData.bufferLockValid) THEN
				UploadData.uploadBuffer := TRUE;
				step := STATE_READING;
			END_IF
		// ---------------------------------------------------------------------------------------------------------
		// Wait for buffer lock
		// ---------------------------------------------------------------------------------------------------------
		STATE_READING:
			CM_buffer.PAR.Progress := REAL_TO_USINT(UploadData.bufferUploadLength*100/8196);
			// ---------------------------------------------------------------------------------------------------------
			// Wait until buffer upload is finished or upload is canceled
			IF(UploadData.bufferUploadDone) THEN
				// Release lock and reset upload command, return to wait state
				UploadData.requestBufferLock := FALSE;  
				UploadData.uploadBuffer := FALSE;
				UploadData.cancelBufferUpload := FALSE;
				CM_buffer.CMD.Upload := 0;
				step := STATE_SAVE;
			END_IF
			// ---------------------------------------------------------------------------------------------------------
			// Cancel upload
			IF(CM_buffer.CMD.Cancel) THEN
				// Release lock and reset upload command, return to wait state
				UploadData.enable := FALSE;
				CM_buffer.CMD.Upload := 0;
				CM_buffer.CMD.Cancel := 0;
				step := STATE_CLEAR;
			END_IF
			// ---------------------------------------------------------------------------------------------------------
			// Jump to error state if status is not 0
			IF(UploadData.status <> ERR_OK) THEN
				CM_buffer.ERR.No := UploadData.status;
				CM_buffer.ERR.State := step;
				CM_buffer.ERR.Text := "Error reading buffer";
				step := STATE_ERROR;
			END_IF
		// ---------------------------------------------------------------------------------------------------------
		// Save data to CSV file
		// ---------------------------------------------------------------------------------------------------------
		STATE_SAVE:
			MpRecipeCsv_0.Save := TRUE;
			IF(MpRecipeCsv_0.CommandDone AND NOT MpRecipeCsv_0.Error) THEN
				CM_buffer.CMD.Upload := 0; 
				MpRecipeCsv_0.Save := FALSE;
				step := STATE_WAIT;
			ELSIF(MpRecipeCsv_0.Error) THEN
				CM_buffer.ERR.No := UploadData.status;
				CM_buffer.ERR.State := step;
				CM_buffer.ERR.Text := "Error saving buffer";
				step := STATE_ERROR;
			END_IF
			// ---------------------------------------------------------------------------------------------------------
		// Error state
		// ---------------------------------------------------------------------------------------------------------
		STATE_ERROR:
			// Release lock and reset all commands
			UploadData.requestBufferLock := FALSE;  
			UploadData.uploadBuffer := FALSE;
			UploadData.cancelBufferUpload := FALSE;
			MpRecipeCsv_0.Save := FALSE;
			CM_buffer.CMD.Upload := 0;
			CM_buffer.CMD.Cancel := 0;
			// ---------------------------------------------------------------------------------------------------------
			// Reset error
			IF(CM_buffer.CMD.ErrorReset <> 0) THEN
				// Acknowledge erros
				UploadData.acknowledgeError := TRUE;
				MpRecipeCsv_0.ErrorReset := TRUE;
				// Wait for function blocks to reset
				IF(UploadData.status = 0 AND MpRecipeCsv_0.StatusID = 0) THEN
					UploadData.acknowledgeError := FALSE;
					MpRecipeCsv_0.ErrorReset := FALSE;
					CM_buffer.CMD.ErrorReset := FALSE;
					brsmemset(ADR(CM_buffer.ERR), 0, SIZEOF(CM_buffer.ERR));
					brsmemset(ADR(CM_buffer.DAT), 0, SIZEOF(CM_buffer.DAT));
					step := STATE_WAIT;
				END_IF
			END_IF
	END_CASE
	
	// ---------------------------------------------------------------------------------------------------------
	// Cyclic function call for buffer upload
	UploadData.paramBufferUpload.moduleBuffer := DINT_TO_UINT(brsatoi(ADR(CM_buffer.PAR.BufferType)));
	UploadData();
	// Cyclic function call for file access
	MpRecipeCsv_0(MpLink := ADR(gRecipeCsvBuffer), Enable := 1, DeviceName := ADR(CM_buffer.PAR.DeviceName), FileName := ADR(CM_buffer.PAR.FileName), Category := ADR('CM_RawData'));
	MpRecipeRegPar_0(MpLink := ADR(gRecipeCsvBuffer), Enable := 1, PVName := ADR('::CM_RawData:CM_buffer.DAT'), Category := ADR('CM_RawData'));
	IF(MpRecipeRegPar_0.Error) THEN
		CM_buffer.ERR.No := UploadData.status;
		CM_buffer.ERR.State := step;
		CM_buffer.ERR.Text := "Error registering buffer variable";
		step := STATE_ERROR;
	END_IF
	
END_PROGRAM

PROGRAM _EXIT
	UploadData(enable := FALSE);
	MpRecipeCsv_0(Enable := FALSE);
	MpRecipeRegPar_0(Enable := FALSE);
END_PROGRAM

