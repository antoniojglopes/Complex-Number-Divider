//-------------------------------------------------------------------------------
//  FEUP / MEEC - Digital Systems Design 2023/2024
// 
// Complex number divider
//-------------------------------------------------------------------------------

`timescale 1ns / 100ps

module cpxdiv(
         input        clock,
         input        reset,
         input        run,
         input [15:0] ReA,
         input [15:0] ImA,
         input [15:0] ReB,
         input [15:0] ImB,
         output[31:0] ReY,
         output[31:0] ImY,
         output       busy
             );

// Input registers
reg [15:0] ReA_reg;
reg [15:0] ImA_reg;
reg [15:0] ReB_reg;
reg [15:0] ImB_reg;


// Counter & state registers
reg [ 5:0] counter;
reg state;

// Auxiliar registers
reg [31:0] multA;
reg [31:0] multB;
reg [31:0] dividend;
reg [15:0] divisor;

// Control registers
reg run_divA;
reg run_divB;

// Multiplexer wires
wire signed [15:0] muxA;
wire signed [15:0] muxB;

// Operators output wires
wire signed [31:0] mult;

wire signed [31:0] sum;


// Multiplexer logic
assign muxA = 	(counter < 3) ? ReB_reg : (counter < 5)  ? ImB_reg : (counter < 7)  ? ReA_reg: (counter < 11) ? ImA_reg : ReA_reg;

assign muxB = 	(counter < 5)  ? muxA : (counter < 7)  ? ReB_reg: (counter < 9) ? ImB_reg : (counter < 11) ? ReB_reg : ImB_reg;

// Mult logic
assign mult = muxA * muxB;	// Combinational multiplier

// Sum logic
assign sum = (counter < 13) ? multA + multB : multA - multB;


// Instantiate division modules
psddivide_top psddivide_A
      ( 
	.clock(clock), // master clock, active in the positive edge
        .reset(reset), // master reset, synchronous and active high
		
        .run(run_divA),     // set to 1 during one clock cycle to start a division
        .busy(),   // set to 1 during the operation of the module - set to 0 when the outputs are ready
		
        .dividend( dividend ), 	     // operand A
        .divisor( divisor ),  // operand B
        .quotient( ReY),           // result  Q = A / B
        .rest()			     // rest isn't connected
        ); 

psddivide_top psddivide_B
      ( 
	.clock(clock), // master clock, active in the positive edge
        .reset(reset), // master reset, synchronous and active high
		
        .run(run_divB),     // set to 1 during one clock cycle to start a division
        .busy(),   // set to 1 during the operation of the module - set to 0 when the outputs are ready
		
        .dividend( dividend ),       // operand A
        .divisor( divisor ),  // operand B
        .quotient( ImY ),           // result  Q = A / B
        .rest()             	     // rest isn't connected
        ); 


always @(posedge clock)
begin

  // SYNC RESET
  if (reset) 
    begin
	ReA_reg  <= 16'd0;
	ImA_reg  <= 16'd0;
	ReB_reg  <= 16'd0;
	ImB_reg  <= 16'd0;

	multA    <= 32'd0;
	multB    <= 32'd0;

	dividend <= 32'd0;
	divisor  <= 32'd0;

	run_divA <= 1'd0; 
	run_divB <= 1'd0;

	counter  <= 6'd0;
    end

  // STATE MACHINE
  else
  begin
	  if (run)
	        begin
			state <= 1;		// Changes the state from IDLE to RUN when run is active
			counter <= 5'h0;   	// Starts counter
			ReA_reg <= ReA;		// Load the input registers
			ReB_reg <= ReB;
			ImA_reg <= ImA;
			ImB_reg <= ImB;
		end

	  if (state==1) 
		  begin
			counter <= counter + 5'h1; 		// Increments counter every clock cicle
			case (counter)
				2: multA <= mult;	// multA = ReB^2

				4: multB <= mult;	// multB = ImB^2

				5: divisor <= sum[31:16];	// divisor = ReB^2 + ImB^2
				    
				6: multA <= mult;	// multA = ReA*ReB

				8: multB <= mult;	// multB = ImA*ImB

				9: begin
					dividend <= sum;	// dividend = ReA*ReB + ImA*ImB
					run_divA <= 1;		// starts ReY division	
				   end

				10: begin
					multA <= mult;	// multA = ReB*ImA
					run_divA <= 0;
				    end
				
				12: multB <= mult;	// multB = ReA*ImB

				13: begin
					dividend <= sum;	// dividend = ReB*ImA - ReA*ImB
					run_divB <= 1;		// starts ImY division	
				    end
					
				14: run_divB <= 0;

				48: begin			// Load division outputs into outputs registers
					state<=0;
					counter<=0;
				    end
			endcase
		  end
	end
end

assign busy = state;		// Keep busy HIGH while the module is running

endmodule
