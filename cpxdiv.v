//-------------------------------------------------------------------------------
//  FEUP / MEEC - Digital Systems Design 2023/2024
// 
// Complex number divider
//-------------------------------------------------------------------------------
//
//				  DATAPATH
//
//            ReA            ImA             ReB            ImB
//             │              │               │              │
// ┌───────────┼──────────────┼───────────────┼──────────────┼───────────┐
// │ cpxdiv    │              │               │              │           │
// │     ┌─────┴─────┐  ┌─────┴─────┐   ┌─────┴─────┐  ┌─────┴─────┐     │
// │     │> ReA_reg  │  │> ImA_reg  │   │> ReB_reg  │  │> ImB_reg  │     │
// │     └─────┬─────┘  └─────┬─────┘   └─────┬─────┘  └─────┬─────┘     │
// │           │              │               │              │           │
// │           │       ┌──────┴───────────────┼───────────┐  │           │
// │           │       │                      │           │  │           │
// │           │ ┌─────┼──────┬───────────────┘ ┌─────────┼──┤           │
// │           │ │     │      │                 │         │  │           │
// │           └─┼─────┼───┬──┼─────────────────┼─────┐   │  │           │
// │             │     │   │  │                 │     │   │  │           │
// │             │  ───┴───┴──┴───              │  ───┴───┴──┴───        │
// │             │  \  2   1  0  /              │  \  2   1  0  /        │
// │  counter ───┼───\   muxA   /     counter ──┼───\   muxB   /         │
// │             │    \________/                │    \________/          │
// │             │       ┌─┘                    │       ┌─┘              │
// │           ┌─┴───────┴─┐                  ┌─┴───────┴─┐              │
// │ run_mult ─┤ A       B │        run_mult ─┤ A       B │              │
// │           │           │                  │           │              │
// │           │    A*B    │         ___      │    A*B    │              │
// │           └─────┬─────┘        /   \     └─────┬─────┘              │
// │                 └──────────────  +  ───────────┘                    │
// │                                \___/                                │
// │                     ┌────────────┴────────────┐                     │
// │              ┌──────┴───────┐          ┌──────┴──────┐              │
// │              │>  dividend   │          │>  divisor   │              │
// │              └──────┬───────┘          └──────┬──────┘              │
// │                 ┌───┴─────────────────────┐   │                     │
// │                 │       ┌─────────────────┼───┴───┐                 │
// │               ┌─┴───────┴─┐             ┌─┴───────┴─┐               │
// │     run_divA ─┤ A       B │   run_divB ─┤ A       B │               │
// │               │           │             │           │               │
// │               │    A/B    │             │    A/B    │               │
// │               └─────┬─────┘             └─────┬─────┘               │
// └─────────────────────┼─────────────────────────┼─────────────────────┘
//                       │                         │
//                       V                         V
//                      ReY                       ImY
//
//
//- Controller design: sequence of states/computing stages.
//                     ┌─────────────┐
//                     │  INIT_REGS  │
//                     ├─────────────┤
//     ┌───────┐ run=1 │ ReA_reg=ReA │ counter=1 ┌────────────┐ counter=2 ┌─────────────┐ counter=19 ┌────────────┐
//     │ START ├──────►│ ImA_reg=ImA ├──────────►│  START_M1  ├──────────►│ RESET_CTRL1 ├───────────►│  START_M2  │
//     ├───────┤       │ ReB_reg=ReB │           ├────────────┤           ├─────────────┤            ├────────────┤
//     │       │       │ ImB_reg=ImB │           │ run_mult=1 │           │ run_mult=0  │            │ run_mult=1 │
//     └───────┘       │  counter=0  │           └────────────┘           └─────────────┘            └──────┬─────┘
//         ▲           │   state=1   │                                                                      │
//         │           └─────────────┘                                                                      │ counter=20
//         │                                                                                                │
//  ┌──────┴───────┐                                                                                        ▼
//  │ CPXDIV_READY │                                                                                 ┌─────────────┐
//  ├──────────────┤                                                                                 │ RESET_CTRL2 │
//  │  counter=0   │                                                                                 ├─────────────┤
//  │   state=0    │                     ┌──────┐ state=1 ┌────────────┐ posedge(clock)              │  run_mult=0 │
//  └──────────────┘                     │ IDLE ├────────►│  RUNNING   ├───┐                         └──────┬──────┘
//         ▲                             ├──────┤         ├────────────┤   │                                │
//         │                             │      │◄────────┤ counter+=1 │◄──┘                                │ counter=21
//         │ counter=90                  └──────┘ state=0 └────────────┘                                    │
//         │                                                                                                ▼
//  ┌──────┴──────┐                                                                                 ┌──────────────┐
//  │ RESET_CTRL4 │                                                                                 │ STORE_M1_SUM │
//  ├─────────────┤                                                                                 ├──────────────┤
//  │  run_divB=0 │                                                                                 │ divisior=sum │
//  └─────────────┘                                                                                 └───────┬──────┘
//         ▲                                                                                                │
//         │                                                                                                │ counter=37
//         │ counter=57                                                                                     │
//         │                                               ┌───────────────┐                                │
// ┌───────┴───────┐ counter=56 ┌─────────────┐ counter=39 │ STORE_M2_SUM_ │ counter=38 ┌────────────┐      │
// │ STORE_M3_SUM_ ├────────────┤ RESET_CTRL3 │◄───────────┤ &_START_DIVA  │◄───────────┤  START_M3  │◄─────┘
// │ &_START_DIVA  │            ├─────────────┤            ├───────────────┤            ├────────────┤
// ├───────────────┤            │  run_divA=0 │            │  dividend=sum │            │ run_mult=1 │
// │  dividend=sum │            └─────────────┘            │  run_divA=1   │            └────────────┘
// │  run_divB=1   │                                       │  run_mult=0   │
// └───────────────┘                                       └───────────────┘
//
/*
- Preliminary analysis of the solution space based on the data provided for the major arithmetic operators and the justification of the solutions(s) selected with convenient justification.

	For this project, we were presented with two different types of both multiplier and divider modules, that could be used in the implementation of the circuit.
	By analyzing the space, the max frequency and the number of functioning clock cycles of each component, we could choose between three possibilities, all of them using at least one sequential divider,
because a combinational divider isn't efficient in both it's speed and area, so our options to be under the restrictions were a module with one combinational multiplier and a one sequential divider, 
with one combinational multiplier and two sequential dividers or with two sequential multipliers and two sequential dividers. We ended up choosing for the inital iteraction the module with two sequential multipliers and two sequential dividers, for being the only one that could work at 200MHz.
	In the module we chose all the LUTs introduced by the given sequential modules has a value of 774 LUT, which lets us use a maximum of 126 LUTs in the rest of the module to be under the maximum LUT value. In our iteraction of the module we could do two multiplications and two divisions at the same time, so reducing the number of clock cycles of six multiplications to the equivalent of three multiplications and using the same logic for the divisions we just need to wait the clock cycles of one divison, extimating the max running time to be: 5ns * (3*18 + 34) clock cycles = 5n * 88 = 440ns, (5ns * (3*18 + 33) clock cycles = 5n * 87 = 435ns for the updated divison module), which was also under the required running time.

- Results of the functional verification process of your cpxdiv module alone.

	We started by creating our own testbench, that was then switched for the provided one and updated it to correct some problems it had with the initial clocks.
	The initial simulations had more than 100 clock cycles at 200MHz, which meant that we were over the limit for speed and above our extimated clocks.
	Analising the module and after the updated multiplication and division modules, we started to reduce the clock cycles and we ended up with a total of 90 clock cycles at 200MHz, corresponding to 450ns of running time and about what we initially calculated, the two clock cycles that we had to add from our calculations were added to store values in registors after the sum of the multiplication results.

- Results of the synthesis of cpxdiv module and possible optimizations done during this stage:
	
	In the first synthesis of our module we had a about 1200 LUTs and our max frequency was under the supposed 200MHz, even if we changed the synthesis optimizations, initially we had dificulty optimizing it, so we also created the other two modules with one combinational multipliers we had theorised in the start of the project, we then synthesized the two new modules and the module with one sequential division was under about 926 LUTs, while the module with two sequential dividers had about 1300 LUTs, but both of them also had a max frequency under the supposed 100MHz. We then started testing various modifications to the code, for example the most significant optimization was for the subtraction of the values of the last two multiplications we could save about 100 LUTs if we did A-B directly, istead of doing A+(~B)+1 which we thought would use less space because we weren't adding a subtractor. One other optimization was also made when fixing the code, after adding an else after the reset so that the code wouldn't run if the reset was active, we also saved some space. Another change was to connect the output wires of the divisions directly to the output of the module. What we did for the optimization of the max frequency was truncate the size of the counter, if we changed the size from an 8-bit registor to a 7-bit one, the max frequency increased and our code was still functional.
	After these optimizations, the final results for the module with two sequential multipliers and two sequential dividers, with a synthesis of Speed and High, we achieved 842 LUTs and a max frequency of 200MHz, which is what we needed to be below the restrictions, while for the module with one combinational multiplier and two sequential dividers the final LUTs value for these optimizations was 919 both modules with combinational multipliers still had a max frequency under 100MHz.
 
- Results of the final implementation:
	
	We only implemented the module that has two sequential multipliers and two sequential dividers in the FPGA because it didn't have any time constrains at 200MHz, after generating the programing file and initializing the FPGA we ran the provided C code and it worked as expected, although it had slightly diferent results from simulation to the board because of how C rouds some numbers.
*/


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
reg [6:0] counter;
reg state;

// Auxiliar registers
reg [31:0] dividend;
reg [15:0] divisor;

// Control registers
reg run_mult;
reg run_divA;
reg run_divB;

// Multiplexer wires
wire [15:0] muxA;
wire [15:0] muxB;

// Sum wire
wire signed [31:0] sum;

// Module output wires
wire [31:0] multA;
wire [31:0] multB;

// Multiplexer logic
assign muxA = (counter < 19) ? ReB_reg : (counter < 37) ? ReA_reg : ImA_reg;
assign muxB = (counter < 19) ? ImB_reg : (counter < 37) ? ImA_reg : ReA_reg;

// Sum logic
assign sum = (counter < 56) ? multA + multB : multA - multB;

// Instantiate multiplication modules
psdmult_top psdmulttop_A
      ( 
	.clock(clock),	// master clock, active in the positive edge
        .reset(reset),	// master reset, synchronous and active high
		
        .run(run_mult),	// set to 1 during one clock cycle to start a multiplication
        .busy(),	// not used
		
        .A( ReB_reg ),	// the operand A
        .B( muxA ),	// the operand B
        .P( multA )	// the result P = A * B
        ); 

psdmult_top psdmulttop_B
      ( 
	.clock(clock),	// master clock, active in the positive edge
        .reset(reset),	// master reset, synchronous and active high
		
        .run(run_mult),	// set to 1 during one clock cycle to start a multiplication
        .busy(),	// not used
		
        .A( ImB_reg ),	// the operand A
        .B( muxB ),	// the operand B
        .P( multB )	// the result P = A * B
        );

// Instantiate division modules
psddivide_top psddivide_A
      ( 
	.clock(clock),	// master clock, active in the positive edge
        .reset(reset),	// master reset, synchronous and active high
		
        .run(run_divA),	// set to 1 during one clock cycle to start a division
        .busy(),	// not used
		
        .dividend( dividend ),	// operand A
        .divisor( divisor ),	// operand B
        .quotient( ReY ),	// result  Q = A / B
        .rest()			// not used
        ); 

psddivide_top psddivide_B
      ( 
	.clock(clock),	// master clock, active in the positive edge
        .reset(reset),	// master reset, synchronous and active high
		
        .run(run_divB),	// set to 1 during one clock cycle to start a division
        .busy(),	// not used
		
        .dividend( dividend ),	// operand A
        .divisor( divisor ),	// operand B
        .quotient( ImY ),	// result  Q = A / B
        .rest()			// not used
        ); 


always @(posedge clock)
begin

  // SYNC RESET
  if (reset) begin

		ReA_reg  <= 0;
		ImA_reg  <= 0;
		ReB_reg  <= 0;
		ImB_reg  <= 0;
		
		dividend <= 0;
		divisor  <= 0;

		run_mult <= 0;
		run_divA <= 0; 
		run_divB <= 0;
		
		state    <= 0;
		counter  <= 0;
  end

  // STATE MACHINE
  else
  begin
  
	if (run==1) begin

		state   <= 1;		// Changes the state from 0 to 1 when run is active
		counter <= 0;
		ReA_reg <= ReA;		// Load the input registers
		ReB_reg <= ReB;
		ImA_reg <= ImA;
		ImB_reg <= ImB;			
	end

	if (state == 1) begin

		counter <= counter + 7'h1; 		// Increments counter every clock cicle

		case (counter)

			1:  run_mult <= 1;		// Starts first pair of multiplications

			2:  run_mult <= 0;
			    
			19: run_mult <= 1;		// Starts second pair of multiplications

			20: run_mult <= 0;			

			21: divisor <= sum[31:16];	// Stores first sum of multiplications in divisor
			
			37: run_mult <= 1;		// Starts third set of multiplications

			38: begin

			    run_mult <= 0;		

			    dividend <= sum;		// Stores second sum of multiplications in dividend
			    run_divA <= 1;		// Starts ReY division
			end

			39: run_divA <= 0;

			56: begin

			    dividend <= sum;		// Stores third sum of multiplications in dividend 
			    run_divB <= 1;		// Starts ImY division
			end

			57: run_divB <= 0;
			
			90: begin   			// Last clock cycle. Both outputs ready.

			    counter <= 0;
			    state   <= 0;
			end
		endcase
	end
  end
end

assign busy = state;			// Keep busy HIGH while running

endmodule
