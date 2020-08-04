Float_Div_inst : Float_Div PORT MAP (
		clock	 => clock_sig,
		dataa	 => dataa_sig,
		datab	 => datab_sig,
		division_by_zero	 => division_by_zero_sig,
		result	 => result_sig
	);
