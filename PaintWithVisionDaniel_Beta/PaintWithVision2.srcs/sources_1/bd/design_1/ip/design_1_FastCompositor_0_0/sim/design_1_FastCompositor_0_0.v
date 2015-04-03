// (c) Copyright 1995-2015 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: user:user:FastCompositor:1.0
// IP Revision: 2

`timescale 1ns/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module design_1_FastCompositor_0_0 (
  clk,
  resetn,
  A_data,
  A_valid,
  A_ready,
  B_data,
  B_valid,
  B_ready,
  C_data,
  C_valid,
  C_ready,
  tlast,
  tkeep
);

input wire clk;
input wire resetn;
input wire [31 : 0] A_data;
input wire A_valid;
output wire A_ready;
input wire [31 : 0] B_data;
input wire B_valid;
output wire B_ready;
output wire [31 : 0] C_data;
output wire C_valid;
input wire C_ready;
output wire tlast;
output wire [3 : 0] tkeep;

  FastCompositor inst (
    .clk(clk),
    .resetn(resetn),
    .A_data(A_data),
    .A_valid(A_valid),
    .A_ready(A_ready),
    .B_data(B_data),
    .B_valid(B_valid),
    .B_ready(B_ready),
    .C_data(C_data),
    .C_valid(C_valid),
    .C_ready(C_ready),
    .tlast(tlast),
    .tkeep(tkeep)
  );
endmodule
