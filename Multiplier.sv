// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: Multiplier.v
// Megafunction Name(s):
// 			lpm_mult
//
// Simulation Library Files(s):
// 			lpm
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 12.1 Build 177 11/07/2012 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2012 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files from any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.

`timescale 1 ps / 1 ps

module Multiplier 
	#(parameter WIDTH_DATA = 32,
					WIDTH_RESULT = 32)
	(dataa,
	datab,
	result);

	input	[WIDTH_DATA-1:0]  dataa;
	input	[WIDTH_DATA-1:0]  datab;
	output [WIDTH_RESULT-1:0] result;

	lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.result (result),
				.aclr (1'b0),
				.clken (1'b1),
				.clock (1'b0),
				.sclr(1'b0),
				.sum());
	defparam
		lpm_mult_component.lpm_hint = "MAXIMIZE_SPEED=5",
		lpm_mult_component.lpm_representation = "UNSIGNED",
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_widtha = WIDTH_DATA,
		lpm_mult_component.lpm_widthb = WIDTH_DATA, 
		lpm_mult_component.lpm_widthp = WIDTH_RESULT; 

endmodule

