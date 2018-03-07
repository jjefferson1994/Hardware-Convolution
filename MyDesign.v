//=============================================================================================
// DUT
//=============================================================================================
//**Notes: This is the version with the steps broken down very far
//=============================================================================================
//synopsys translate_off

`include "/afs/eos.ncsu.edu/software/synopsys2017/syn/dw/sim_ver/DW02_prod_sum.v"
`include "/afs/eos.ncsu.edu/software/synopsys2017/syn/dw/sim_ver/DW01_add.v"

//synopsys translate_on

module MyDesign(
    //=============================================================================================
    // General
    //
    input wire clk,
    input wire reset,  

    //=============================================================================================
    // Control
    // These are the control statements for the high level state machine to start reading and processing data from memory
    output reg dut__xxx__finish,
    input  wire xxx__dut__go,  

	//=============================================================================================
    // A - memory 
    //
    output reg  [8:0] dut__dim__address, // Register for sending address location to A-memory
    output reg  dut__dim__enable, //enable bit is high when reading and writing from
    output reg  dut__dim__write, //write flag is high when writing, low when reading
    output reg  [15:0] dut__dim__data,  // write data
    input  wire [15:0] dim__dut__data,  // read data
	
    //=============================================================================================
    // B-vector memory 
    //
    output reg  [9:0] dut__bvm__address, // Register for sending address location to B and M-memory
    output reg  dut__bvm__enable, //enable bit is high when reading and writing from
    output reg  dut__bvm__write, //write flag is high when writing, low when reading
    output reg  [15:0] dut__bvm__data,  // write data
    input  wire [15:0] bvm__dut__data,  // read data

    //=============================================================================================
    // Output data memory 
    //
    output reg  [2:0] dut__dom__address,
    output reg  [15:0] dut__dom__data,  // write data
    output reg  dut__dom__enable,
    output reg  dut__dom__write
	);

//Parameters for the module
//=============================================================================================
	//parameters and book-keeping for the second dot product

	
	//next state logic for getting rid of wired or
	reg [8:0] dut__dim__address__next;
	reg [15:0] dim__dut__data__next;
	
	reg [8:0] dut__bvm__address__next;
	reg [15:0] bvm__dut__data__next;
	
	//registers for saving memory
	reg [2303:0] A;
	reg [575:0] B;
	reg [1023:0] U;
	
	//these are broken into 1x9s
	reg [143:0] A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15; 
	
	//these are also broken into 1x9s
	reg [143:0] B0, B1, B2, B3;

	//these are broken into 1x64s
	reg [1023:0] M0, M1, M2, M3, M4, M5, M6, M7;
	
	//go control signal
	reg receivedGo;
	
	//Counters
	reg [11:0] masterCount;
	reg [5:0] Acount;
	reg [5:0] next_Acount;
	reg [5:0] Bcount;
	reg [5:0] next_Bcount;
	
	//for the C values
	wire [15:0] rect_C0, rect_C1, rect_C2, rect_C3, rect_C4, rect_C5, rect_C6, rect_C7, rect_C8, rect_C9, rect_C10, rect_C11, rect_C12, rect_C13, rect_C14, rect_C15, rect_C16, rect_C17, rect_C18, rect_C19, rect_C20, rect_C21, rect_C22, rect_C23, rect_C24, rect_C25, rect_C26, rect_C27, rect_C28, rect_C29, rect_C30, rect_C31, rect_C32, rect_C33, rect_C34, rect_C35, rect_C36, rect_C37, rect_C38, rect_C39, rect_C40, rect_C41, rect_C42, rect_C43, rect_C44, rect_C45, rect_C46, rect_C47, rect_C48, rect_C49, rect_C50, rect_C51, rect_C52, rect_C53, rect_C54, rect_C55, rect_C56, rect_C57, rect_C58, rect_C59, rect_C60, rect_C61, rect_C62, rect_C63;
	
	//for the U values
	//wire [31:0] U0, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14, U15, U16, U17, U18, U19, U20, U21, U22, U23, U24, U25, U26, U27, U28, U29, U30, U31, U32, U33, U34, U35, U36, U37, U38, U39, U40, U41, U42, U43, U44, U45, U46, U47, U48, U49, U50, U51, U52, U53, U54, U55, U56, U57, U58, U59, U60, U61, U62, U63;
		
	//for outputs
	wire [15:0] W0, W1, W2, W3, W4, W5, W6, W7;
	reg [15:0] next_O0, next_O1, next_O2, next_O3, next_O4, next_O5, next_O6, next_O7;
	
	//Clock part of the system (mostly used for I/O
	//=============================================================================================
	always @ (posedge clk) //clocked system
	begin
		// Reset values
		if(reset) //reset and a go signal both should reset the counters and such
		begin
			//resets the couters
			masterCount <= 12'b000000000000; //overall master count for the entire module (controller)
			Acount <= 6'b0; //This counter needs to start behind by one
			Bcount <= 6'b0;
		
			//intializes the huge registers to 0
			A <= 2304'b0;
			B <= 576'b0;
			M0 <= 1024'b0;
			M1 <= 1024'b0;
			M2 <= 1024'b0;
			M3 <= 1024'b0;
			M4 <= 1024'b0;
			M5 <= 1024'b0;
			M6 <= 1024'b0;
			M7 <= 1024'b0;
			
			//resets the control signals for reading in memory
			//this is for A-memory
			dut__dim__address <= 9'b0;
			dut__dim__enable <= 1'b0;
			dut__dim__write <= 1'b0;
			dut__dim__data <= 1'b0;
			
			dut__bvm__address <= 9'b0;
			dut__bvm__enable <= 1'b0;
			dut__bvm__write <= 1'b0;
			dut__bvm__data <= 1'b0;
			
			dut__dom__address <= 3'b0;
			dut__dom__enable <= 1'b0;
			dut__dom__write <= 1'b1;

			//finish signal needs to be set high initially to start testbench
			dut__xxx__finish <= 1'b1;
		end
		else 
		begin
			//Block for reading in from memory
			//=============================================================================================
			if(xxx__dut__go) //looks for the go signal and a flag goes high
			begin
				masterCount <= 12'b000000000000; //overall master count for the entire module (controller)
				receivedGo <= 1'b1;
				Acount <= 6'b0;
				Bcount <= 6'b0;
				dut__dim__enable <= 1'b1; //enable for A
				dut__bvm__enable <= 1'b1; //enable for B
				dut__dom__enable <= 1'b1; //enable for O 
				
				//intializes the huge registers to 0
				A <= 2304'b0;
				B <= 576'b0;
				M0 <= 1024'b0;
				M1 <= 1024'b0;
				M2 <= 1024'b0;
				M3 <= 1024'b0;
				M4 <= 1024'b0;
				M5 <= 1024'b0;
				M6 <= 1024'b0;
				M7 <= 1024'b0;
				
				dut__dim__address <= 9'b0;
				dut__bvm__address <= 9'b0;
				dut__dom__address <= 3'b111;
				
				dut__xxx__finish <= 1'b0;
			end
			
			// Handle initilization for go signal input
			if(receivedGo)
			begin
			masterCount <= masterCount + 1'b1;
			
			dut__dim__address <= dut__dim__address__next;
			dim__dut__data__next <= dim__dut__data; //reading in
			
			dut__bvm__address <= dut__bvm__address__next;
			bvm__dut__data__next <= bvm__dut__data; //reading in
			
				//Fills in register A based off the master counter
				if(masterCount < 145)
				begin
					A <= {A[2287:0],dim__dut__data__next};
					Acount <= next_Acount + 1'b1; // increments A counter
				end
				
				//Fills in register B based off the master counter
				if(masterCount < 37)
				begin
					B <= {B[559:0],bvm__dut__data__next};
					Bcount <= next_Bcount + 1'b1; // increments A counter
				end
				
				if(masterCount > 599 && masterCount < 609)
				begin
					dut__dom__write <= 1'b1;
				end
				else dut__dom__write <= 1'b0;
				
				//This block is for outputting the information after finishing
				if(masterCount > 600)
				begin
					case(masterCount)
						601:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O0;
						end
						602:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O1;
						end
						603:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O2;
						end
						604:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O3;
						end
						605:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O4;
						end
						606:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O5;
						end
						607:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O6;
						end
						608:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= next_O7;
						end
						609:
						begin
							dut__dom__address <= dut__dom__address + 1'b1;
							dut__dom__data <= 1'b0;
						end
						default: 
						begin
							dut__dom__address <= dut__dom__address;
							dut__dom__data <= 1'b0;
						end
					endcase
				end
				
				if(masterCount > 610)
				begin
					dut__xxx__finish <= 1'b1;
					receivedGo <= 1'b0;
				end
				
				//Fills in register M based off the master counter
				if(masterCount > 36 && masterCount < 101)
				begin
					M0 <= {M0[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 100 && masterCount < 165)
				begin
					M1 <= {M1[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 164 && masterCount < 229)
				begin
					M2 <= {M2[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 228 && masterCount < 293)
				begin
					M3 <= {M3[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 292 && masterCount < 357)
				begin
					M4 <= {M4[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 356 && masterCount < 421)
				begin
					M5 <= {M5[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 420 && masterCount < 485)
				begin
					M6 <= {M6[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end
				else if(masterCount > 484 && masterCount < 549)
				begin
					M7 <= {M7[1007:0],bvm__dut__data__next};
					dut__bvm__address <= dut__bvm__address + 1'b1;
				end

				
				//combinational logic for splitting up A and B for your controller
				//=============================================================================================
				A0 = A[2303:2160]; //gets the first part of A
				A1 = A[2159:2016]; //gets the first part of A
				A2 = A[2015:1872]; //gets the first part of A
				A3 = A[1871:1728]; //gets the first part of A
				A4 = A[1727:1584]; //gets the first part of A
				A5 = A[1583:1440]; //gets the first part of A
				A6 = A[1439:1296]; //gets the first part of A
				A7 = A[1295:1152]; //gets the first part of A
				A8 = A[1151:1008]; //gets the first part of A
				A9 = A[1007:864]; //gets the first part of A
				A10 = A[863:720]; //gets the first part of A
				A11 = A[719:576]; //gets the first part of A
				A12 = A[575:432]; //gets the first part of A
				A13 = A[431:288]; //gets the first part of A
				A14 = A[287:144]; //gets the first part of A
				A15 = A[143:0]; //gets the first part of A
				
				B0 = B[575:432];
				B1 = B[431:288];
				B2 = B[287:144];
				B3 = B[143:0];
			//=============================================================================================
			 //this is the 1x64 going into step 2 (***I am reading the correct U values)
				U <= {rect_C0, rect_C1, rect_C4, rect_C5,
					rect_C2, rect_C3, rect_C6, rect_C7,
					rect_C8, rect_C9, rect_C12, rect_C13,
					rect_C10, rect_C11, rect_C14, rect_C15,
					rect_C16, rect_C17, rect_C20, rect_C21,
					rect_C18, rect_C19, rect_C22, rect_C23,
					rect_C24, rect_C25, rect_C28, rect_C29,
					rect_C26, rect_C27, rect_C30, rect_C31,
					rect_C32, rect_C33, rect_C36, rect_C37,
					rect_C34, rect_C35, rect_C38, rect_C39,
					rect_C40, rect_C41, rect_C44, rect_C45,
					rect_C42, rect_C43, rect_C46, rect_C47,
					rect_C48, rect_C49, rect_C52, rect_C53,
					rect_C50, rect_C51, rect_C54, rect_C55,
					rect_C56, rect_C57, rect_C60, rect_C61,
					rect_C58, rect_C59, rect_C62, rect_C63};
					
				next_O0 = W0;
				next_O1 = W1;
				next_O2 = W2;
				next_O3 = W3;
				next_O4 = W4;
				next_O5 = W5;
				next_O6 = W6;
				next_O7 = W7;
			end
		end	
	end
	
	always @*
	begin	
		next_Acount = Acount; // increments A counter
		casex(Acount)
			2: dut__dim__address__next = dut__dim__address + 4'hE;
			5: dut__dim__address__next = dut__dim__address + 4'hE;
			8: dut__dim__address__next = dut__dim__address - 8'h1F; //moves to next quadrant
			11: dut__dim__address__next = dut__dim__address + 4'hE;
			14: dut__dim__address__next = dut__dim__address + 4'hE;
			17: dut__dim__address__next = dut__dim__address + 4'hB; //moves to next quadrant
			20: dut__dim__address__next = dut__dim__address + 4'hE;
			23: dut__dim__address__next = dut__dim__address + 4'hE;
			26: dut__dim__address__next = dut__dim__address - 8'h1F; //moves to next quadrant
			29: dut__dim__address__next = dut__dim__address + 4'hE;
			32: dut__dim__address__next = dut__dim__address + 4'hE;
			35: 
			begin
				next_Acount = 6'b111111; //resest the counter for incrementing through the quadrants
				if(dut__dim__address__next == 8'h55) //first quadrant done
				begin
					dut__dim__address__next = 8'h06;
				end
				else if(dut__dim__address__next == 8'h5B) //second quadrant done
				begin
					dut__dim__address__next = 8'h60;
				end
				else if(dut__dim__address__next == 8'hB5) //third quadrant done
				begin
					dut__dim__address__next = 8'h66;
				end
				else dut__dim__address__next = dut__dim__address;
			end
			63: dut__dim__address__next = dut__dim__address;
			default: dut__dim__address__next =  dut__dim__address + 1'b1; //moves the address value by 1
		endcase
		
		//this block reads in the data from B-memory
		//=============================================================================================
		next_Bcount = Bcount;
		casex(Bcount)
			8: dut__bvm__address__next = dut__bvm__address + 4'h8;
			17: dut__bvm__address__next = dut__bvm__address + 4'h8;
			26: dut__bvm__address__next = dut__bvm__address + 4'h8;
			35: 
			begin
				dut__bvm__address__next = 8'h40;
			end
			default: dut__bvm__address__next = dut__bvm__address + 1'b1;
		endcase
		
	end

//Code for the 4 instatiations for step 1 per the rubric
//=============================================================================================
//First Quadrant

firstDotRect DR0 (clk, A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, 
				B0, rect_C0, rect_C1, rect_C2, rect_C3, rect_C4, rect_C5, rect_C6, rect_C7, rect_C8, rect_C9, rect_C10, rect_C11, rect_C12, rect_C13, rect_C14, rect_C15); 		
//Second Quadrant

firstDotRect DR1 (clk, A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15,
				B1, rect_C16, rect_C17, rect_C18, rect_C19, rect_C20, rect_C21, rect_C22, rect_C23, rect_C24, rect_C25, rect_C26, rect_C27, rect_C28, rect_C29, rect_C30, rect_C31); 

//Third Quadrant
firstDotRect DR2 (clk, A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15,
				B2, rect_C32, rect_C33, rect_C34, rect_C35, rect_C36, rect_C37, rect_C38, rect_C39, rect_C40, rect_C41, rect_C42, rect_C43, rect_C44, rect_C45, rect_C46, rect_C47); 
//Fourth Quadrant
firstDotRect DR3 (clk, A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15,
				B3, rect_C48, rect_C49, rect_C50, rect_C51, rect_C52, rect_C53, rect_C54, rect_C55, rect_C56, rect_C57, rect_C58, rect_C59, rect_C60, rect_C61, rect_C62, rect_C63); 

				
//Code for Step 2 (used similar method as step 1)
//=============================================================================================				
secondDotRect DR20 (clk, M0, U, W0);
secondDotRect DR21 (clk, M1, U, W1);	
secondDotRect DR22 (clk, M2, U, W2);	
secondDotRect DR23 (clk, M3, U, W3);	
secondDotRect DR24 (clk, M4, U, W4);	
secondDotRect DR25 (clk, M5, U, W5);	
secondDotRect DR26 (clk, M6, U, W6);
secondDotRect DR27 (clk, M7, U, W7);	


endmodule

//=============================================================================================
module firstDotRect(clk, A0in, A1in, A2in, A3in, A4in, A5in, A6in, A7in, A8in, A9in, A10in, A11in, A12in, A13in, A14in, A15in, 
						Bin, rect_C0out, rect_C1out, rect_C2out, rect_C3out, rect_C4out, rect_C5out, rect_C6out, rect_C7out, rect_C8out, rect_C9out, rect_C10out, rect_C11out, rect_C12out, rect_C13out, rect_C14out, rect_C15out);
	//parameters and book-keeping for the first dot product
	parameter A_width = 16; // width of each chunck for input A
	parameter B_width = 16; // width of each chunck for input B
	parameter num_inputs = 9; // number of chunks
	parameter SUM_width = 32; 
	wire inst_TC; //   when tc = 1
	
	input clk;
	input [143:0] A0in, A1in, A2in, A3in, A4in, A5in, A6in, A7in, A8in, A9in, A10in, A11in, A12in, A13in, A14in, A15in, Bin;
	wire [31:0] C0out, C1out, C2out, C3out, C4out, C5out, C6out, C7out, C8out, C9out, C10out, C11out, C12out, C13out, C14out, C15out;
	reg [15:0] temp_C0out, temp_C1out, temp_C2out, temp_C3out, temp_C4out, temp_C5out, temp_C6out, temp_C7out, temp_C8out, temp_C9out, temp_C10out, temp_C11out, temp_C12out, temp_C13out, temp_C14out, temp_C15out;
	output [15:0] rect_C0out, rect_C1out, rect_C2out, rect_C3out, rect_C4out, rect_C5out, rect_C6out, rect_C7out, rect_C8out, rect_C9out, rect_C10out, rect_C11out, rect_C12out, rect_C13out, rect_C14out, rect_C15out;
	
	assign inst_TC = 1'b1;
	
	always @ (posedge clk)
	begin
		temp_C0out <= C0out[31:16]; temp_C1out <= C1out[31:16]; temp_C2out <= C2out[31:16]; temp_C3out <= C3out[31:16];
		temp_C4out <= C4out[31:16]; temp_C5out <= C5out[31:16]; temp_C6out <= C6out[31:16]; temp_C7out <= C7out[31:16]; 
		temp_C8out <= C8out[31:16]; temp_C9out <= C9out[31:16]; temp_C15out <= C15out[31:16]; temp_C10out <= C10out[31:16];
		temp_C11out <= C11out[31:16]; temp_C12out <= C12out[31:16]; temp_C13out <= C13out[31:16]; temp_C14out <= C14out[31:16]; 
	end
	
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D0 (.A(A0in), .B(Bin), .TC(inst_TC), .SUM(C0out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D1 (.A(A1in), .B(Bin), .TC(inst_TC), .SUM(C1out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D2 (.A(A2in), .B(Bin), .TC(inst_TC), .SUM(C2out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D3 (.A(A3in), .B(Bin), .TC(inst_TC), .SUM(C3out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D4 (.A(A4in), .B(Bin), .TC(inst_TC), .SUM(C4out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D5 (.A(A5in), .B(Bin), .TC(inst_TC), .SUM(C5out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D6 (.A(A6in), .B(Bin), .TC(inst_TC), .SUM(C6out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D7 (.A(A7in), .B(Bin), .TC(inst_TC), .SUM(C7out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D8 (.A(A8in), .B(Bin), .TC(inst_TC), .SUM(C8out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D9 (.A(A9in), .B(Bin), .TC(inst_TC), .SUM(C9out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D10 (.A(A10in), .B(Bin), .TC(inst_TC), .SUM(C10out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D11 (.A(A11in), .B(Bin), .TC(inst_TC), .SUM(C11out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D12 (.A(A12in), .B(Bin), .TC(inst_TC), .SUM(C12out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D13 (.A(A13in), .B(Bin), .TC(inst_TC), .SUM(C13out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D14 (.A(A14in), .B(Bin), .TC(inst_TC), .SUM(C14out));
	DW02_prod_sum #(A_width, B_width, num_inputs, SUM_width) D15 (.A(A15in), .B(Bin), .TC(inst_TC), .SUM(C15out));


	rectify R0 (clk, temp_C0out,rect_C0out);
	rectify R1 (clk, temp_C1out,rect_C1out);
	rectify R2 (clk, temp_C2out,rect_C2out);
	rectify R3 (clk, temp_C3out,rect_C3out);
	rectify R4 (clk, temp_C4out,rect_C4out);
	rectify R5 (clk, temp_C5out,rect_C5out);
	rectify R6 (clk, temp_C6out,rect_C6out);
	rectify R7 (clk, temp_C7out,rect_C7out);
	rectify R8 (clk, temp_C8out,rect_C8out);
	rectify R9 (clk, temp_C9out,rect_C9out);
	rectify R10 (clk, temp_C10out,rect_C10out);
	rectify R11 (clk, temp_C11out,rect_C11out);
	rectify R12 (clk, temp_C12out,rect_C12out);
	rectify R13 (clk, temp_C13out,rect_C13out);
	rectify R14 (clk, temp_C14out,rect_C14out);
	rectify R15 (clk, temp_C15out,rect_C15out);
	
endmodule


//=============================================================================================
module secondDotRect(clk, Min, Uin, rect_Wout);
	//parameters and book-keeping for the first dot product
	parameter A_width2 = 16; // width of each chunck for input A
	parameter B_width2 = 16; // width of each chunck for input B
	parameter num_inputs2 = 8; // number of chunks
	parameter SUM_width2 = 32; 
	wire inst_TC2; //   when tc = 1
	
	parameter width_add = 32;
	wire inst_CI0;
	
	input clk;
	input [1023:0] Min, Uin;
	output [15:0] rect_Wout;
	
	reg [63:0] Min0, Min1, Min2, Min3, Min4, Min5, Min6, Min7, Min8, Min9, Min10, Min11, Min12, Min13, Min14, Min15;
	reg [63:0] Uin0, Uin1, Uin2, Uin3, Uin4, Uin5, Uin6, Uin7, Uin9, Uin10, Uin11, Uin12, Uin13, Uin14, Uin15;
	
	wire [31:0] firstM0, firstM1, firstM2, firstM3, firstM4, firstM5, firstM6, firstM7, firstM8, firstM9, firstM10, firstM11, firstM12, firstM13, firstM14, firstM15;
	reg [31:0] firstM0_pipe, firstM1_pipe, firstM2_pipe, firstM3_pipe, firstM4_pipe, firstM5_pipe, firstM6_pipe, firstM7_pipe, firstM8_pipe, firstM9_pipe, firstM10_pipe, firstM11_pipe, firstM12_pipe, firstM13_pipe, firstM14_pipe, firstM15_pipe;
	
	wire [31:0] secondM0, secondM1, secondM2, secondM3, secondM4, secondM5, secondM6, secondM7;
	reg [31:0] secondM0_pipe, secondM1_pipe, secondM2_pipe, secondM3_pipe, secondM4_pipe, secondM5_pipe, secondM6_pipe, secondM7_pipe;
	
	wire [31:0] thirdM0, thirdM1, thirdM2, thirdM3;
	reg [31:0] thirdM0_pipe, thirdM1_pipe, thirdM2_pipe, thirdM3_pipe;
	
	wire [31:0] fourthM0, fourthM1;
	reg [31:0] fourthM0_pipe, fourthM1_pipe;
	
	wire [31:0] final_W
	reg [15:0] pipe_final_W;
	
	wire CO0, CO1, CO2, CO3, CO4, CO5, CO6, CO7, CO8, CO9, CO10, CO11, CO12, CO13, CO14;
	
	assign inst_TC2 = 1'b1;
	assign inst_CI0 = 1'b0; //carry in for the adders needs to stay 0
	
	always @ (posedge clk)
	begin
		Min0 <= Min[1023:960];
		Min1 <= Min[959:896];
		Min2 <= Min[895:832];
		Min3 <= Min[831:768];
		Min4 <= Min[767:704];
		Min5 <= Min[703:640];
		Min6 <= Min[639:576];
		Min7 <= Min[575:512];
		Min8 <= Min[511:448];
		Min9 <= Min[447:384];
		Min10 <= Min[383:320];
		Min11 <= Min[319:256];
		Min12 <= Min[255:192];
		Min13 <= Min[191:128];
		Min14 <= Min[127:64];
		Min15 <= Min[63:0];
		
		Uin0 <= Uin[1023:960];
		Uin1 <= Uin[959:896];
		Uin2 <= Uin[895:832];
		Uin3 <= Uin[831:768];
		Uin4 <= Uin[767:704];
		Uin5 <= Uin[703:640];
		Uin6 <= Uin[639:576];
		Uin7 <= Uin[575:512];
		Uin8 <= Uin[511:448];
		Uin9 <= Uin[447:384];
		Uin10 <= Uin[383:320];
		Uin11 <= Uin[319:256];
		Uin12 <= Uin[255:192];
		Uin13 <= Uin[191:128];
		Uin14 <= Uin[127:64];
		Uin15 <= Uin[63:0];
		
		firstM0_pipe <= firstM0;
		firstM1_pipe <= firstM1;
		firstM2_pipe <= firstM2;
		firstM3_pipe <= firstM3;
		firstM4_pipe <= firstM4;
		firstM5_pipe <= firstM5;
		
		pipe_final_W <= final_W[31:16];
	end
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D140 (.A(Min0), .B(Uin0), .TC(inst_TC2), .SUM(firstM0));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D141 (.A(Min1), .B(Uin1), .TC(inst_TC2), .SUM(firstM1));
	DW01_add #(width_add) A0 (.A(firstM0_pipe), .B(firstM1_pipe), .CI(inst_CI0), .SUM(secondM0), .CO(CO0));
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D142 (.A(Min2), .B(Uin2), .TC(inst_TC2), .SUM(firstM2));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D143 (.A(Min3), .B(Uin3), .TC(inst_TC2), .SUM(firstM3));
	DW01_add #(width_add) A1 (.A(firstM2_pipe), .B(firstM3_pipe), .CI(inst_CI0), .SUM(secondM1), .CO(CO1));
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D144 (.A(Min4), .B(Uin4), .TC(inst_TC2), .SUM(firstM4));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D145 (.A(Min5), .B(Uin5), .TC(inst_TC2), .SUM(firstM5));
	DW01_add #(width_add) A2 (.A(firstM4_pipe), .B(firstM5_pipe), .CI(inst_CI0), .SUM(secondM2), .CO(CO2));
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D146 (.A(Min6), .B(Uin6), .TC(inst_TC2), .SUM(firstM6));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D147 (.A(Min7), .B(Uin7), .TC(inst_TC2), .SUM(firstM7));
	DW01_add #(width_add) A3 (.A(firstM6_pipe), .B(firstM7_pipe), .CI(inst_CI0), .SUM(secondM3), .CO(CO3));
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D148 (.A(Min8), .B(Uin8), .TC(inst_TC2), .SUM(firstM8));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D149 (.A(Min9), .B(Uin9), .TC(inst_TC2), .SUM(firstM9));
	DW01_add #(width_add) A4 (.A(firstM8_pipe), .B(firstM9_pipe), .CI(inst_CI0), .SUM(secondM4), .CO(CO4));
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D1410 (.A(Min10), .B(Uin10), .TC(inst_TC2), .SUM(firstM10));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D1411 (.A(Min11), .B(Uin11), .TC(inst_TC2), .SUM(firstM11));
	DW01_add #(width_add) A5 (.A(firstM10_pipe), .B(firstM11_pipe), .CI(inst_CI0), .SUM(secondM5), .CO(CO5));
	
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D1412 (.A(Min12), .B(Uin12), .TC(inst_TC2), .SUM(firstM12));
	DW02_prod_sum #(A_width2, B_width2, num_inputs2, SUM_width2) D1413 (.A(Min13), .B(Uin13), .TC(inst_TC2), .SUM(firstM13));
	DW01_add #(width_add) A6 (.A(firstM12_pipe), .B(firstM13_pipe), .CI(inst_CI0), .SUM(secondM6), .CO(CO5));
	
	rectify R20 (clk, pipe_final_W, rect_Wout);
	
	
endmodule

//=============================================================================================
// module to rectify
module rectify(clk, Cin, Cout);
	input clk;
	input [15:0] Cin;
	output reg [15:0] Cout;
	
	always @ (posedge clk)
	begin
		Cout = (Cin[15] == 1'b1) ? 16'b0 : Cin;
	end
endmodule
