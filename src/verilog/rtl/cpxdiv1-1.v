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

reg [31:0] ReY_reg;
reg [31:0] ImY_reg;


// Counter & state registers
reg [ 6:0] counter;
reg state = 0;

// Auxiliar registers
reg [31:0] multA;
reg [31:0] multB;
reg [31:0] dividend;
reg [31:0] divisor;

// Control registers
reg run_div;

// Multiplexer wires
wire signed [15:0] muxA;
wire signed [15:0] muxB;

// Operators output wires
wire signed [31:0] mult;
wire signed [31:0] sum;
wire [31:0] div;

// States
parameter IDLE = 0,
          RUN  = 1;

// Multiplexer logic
assign muxA = 	(counter < 3)  ? ReB_reg : (counter < 5)  ? ImB_reg : (counter < 7)  ? ReA_reg : (counter < 11) ? ImA_reg : ReA_reg;

assign muxB = 	(counter < 5)  ? muxA : (counter < 7)  ? ReB_reg: (counter < 9) ? ImB_reg : (counter < 11) ? ReB_reg : ImB_reg;

// Mult logic ( combinational multiplier )
assign mult = muxA * muxB;

// Sum logic
assign sum = (counter < 13) ? multA + multB : multA - multB;

// Connect the output registers to the interface output
assign ReY = ReY_reg;
assign ImY = ImY_reg;

// Instantiate division module
psddivide_top psddivide
      ( 
	.clock(clock), // master clock, active in the positive edge
        .reset(reset), // master reset, synchronous and active high
		
        .run(run_div),     // set to 1 during one clock cycle to start a division
        .busy(),   // set to 1 during the operation of the module - set to 0 when the outputs are ready
		
        .dividend( dividend ), 	     // operand A
        .divisor( divisor[31:16] ),  // operand B
        .quotient( div ),           // result  Q = A / B
        .rest()			     // rest isn't connected
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

	ReY_reg  <= 32'd0;
	ImY_reg  <= 32'd0;

	multA    <= 32'd0;
	multB    <= 32'd0;

	dividend <= 32'd0;
	divisor  <= 32'd0;

	run_div  <= 1'd0; 

	counter  <= 7'd0;
    end

  // STATE MACHINE
  else
  begin
    case (state)
	  IDLE: if (run)
	        begin
			state <= RUN;		// Changes the state from IDLE to RUN when run is active
			counter <= 6'h1;   	// Starts counter
			ReA_reg <= ReA;		// Load the input registers
			ReB_reg <= ReB;
			ImA_reg <= ImA;
			ImB_reg <= ImB;
		end

	  RUN: if(state==RUN)
		  begin
			case (counter)
				2: multA <= mult;	// multA = ReB^2

				4: multB <= mult;	// multB = ImB^2

				5: divisor <= sum;	// divisor = ReB^2 + ImB^2
				    
				6: multA <= mult;	// multA = ReA*ReB

				8: multB <= mult;	// multB = ImA*ImB

				9: begin
					dividend <= sum;	// dividend = ReA*ReB + ImA*ImB
					run_div <= 1;		// starts ReY division	
				   end

				10: begin
					multA <= mult;	// multA = ReB*ImA
					run_div <= 0;
				    end
				
				12: multB <= mult;	// multB = ReA*ImB

				13: dividend <= sum;	// dividend = ReB*ImA - ReA*ImB

				43: run_div <= 1;	// starts ImY division

				44: begin			
					ReY_reg <= div;	// loads output register: ReY_reg = (ReA*ReB + ImA*ImB) / (ReB^2 + ImB^2)
					run_div <= 0;	
				    end
				
				79: ImY_reg <= div;	// loads output register: ImY_reg = (ReB*ImA - ReA*ImB) / (ReB^2 + ImB^2)
				
				80:begin
		    	counter <= 6'h0;
				state   <= IDLE;
			  end
			endcase
			counter <= counter + 1'h1; 	// Increments counter every clock cicle
		  end
    endcase
  end

end

assign busy = state;	// Keep busy HIGH while the module is running

endmodule
