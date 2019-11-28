
TYPE
	CM_BUFFER_STATE : 
		(
		STATE_CLEAR,
		STATE_WAIT,
		STATE_LOCK,
		STATE_READING,
		STATE_SAVE,
		STATE_ERROR
		);
	CM_BUFFER_DAT : 	STRUCT 
		xAxis : ARRAY[0..8191]OF REAL;
		yAxis : ARRAY[0..8191]OF REAL;
	END_STRUCT;
	CM_BUFFER_CMD : 	STRUCT 
		Upload : BOOL; (*Start uploading buffer*)
		Cancel : BOOL; (*Cancel buffer upload*)
		ErrorReset : BOOL; (*Reset pending errors*)
	END_STRUCT;
	CM_BUFFER_PAR : 	STRUCT 
		ModulePath : STRING[80] := 'IF6.ST1'; (*Module path from physical view*)
		BufferType : STRING[5] := '9'; (*Raw data buffer type*)
		SensitivitySensor : REAL := 100; (*Sensivity for the sensor*)
		FileName : STRING[80] := 'ComMonBuffer'; (*File name for the buffer data*)
		DeviceName : STRING[80] := 'USER_DEVICE'; (*Device name for the buffer data*)
		VisuBufferEnable : BOOL; (*Enable/Disable controls in visualization*)
		Progress : USINT;
		Status : STRING[200];
	END_STRUCT;
	CM_BUFFER_MAIN : 	STRUCT 
		CMD : CM_BUFFER_CMD;
		PAR : CM_BUFFER_PAR;
		DAT : CM_BUFFER_DAT;
		ERR : CM_BUFFER_ERR;
	END_STRUCT;
	CM_BUFFER_ERR : 	STRUCT  (*Recipe managment error structure*)
		Text : WSTRING[200]; (* Error text *)
		No : DINT; (* Error number *)
		State : CM_BUFFER_STATE; (* Error step *)
	END_STRUCT;
END_TYPE
