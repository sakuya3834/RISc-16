module CPU( clk, rst );

	input clk;
	input rst;

	reg [15:0] pc;
	reg [15:0] instruction;
 	reg	[15:0] instruction_memory [8:0];

	// Data Memory
	reg [15:0] data_memory [10:0]; // Array[10] of 16bits in each slot
	reg [15:0] data_address;

	// Register Data
	reg [2:0] 	reg_address_A; 	// reg to write reg_data_write
	reg [15:0]	reg_data_A;		// data to write to register[reg_address_write]

    reg [2:0] 	reg_address_B;		// address of register B
	reg [15:0]	reg_data_B;			// data of register B

	reg [2:0] 	reg_address_C;		// address of register C
	reg [15:0]	reg_data_C;			// data of register C

	// Control Signals
	reg [0:0] 	cs_write_reg;			// Controls If reg_data_write is written to reg_address_write
	reg [3:0] 	cs_alu;					// Controls Which ALU Operation Will Be Commited
	reg 		cs_alu_select;			// Controls If Operand1 = Instruction[9:0] OR reg_data_c
	reg 		cs_read_data_memory;
	reg 		cs_write_data_memory;

	reg [3:0]  pc_control;

	// ALU Properties
	reg [15:0] alu_operand0;
	reg [15:0] alu_operand1;
	reg [15:0] alu_result;
	reg alu_overflow;
	reg alu_zero;

	// Data
	reg [15:0] registers [7:0];

	reg [2:0] opcode;
	reg [15:0] immediate;
	integer i;

	initial begin
		// Load Instructions
		$readmemb("p2inst.mips",instruction_memory);

		// Reset Registers
	    for(i = 0; i < 8; i = i+1)
		begin
	        registers[i] = 0;
		end

        // reset data mem
      	for (i = 0; i < 10; i = i + 1)
        begin
          data_memory[i] = 0;
        end
	end

  // print contents of registers and data mem after every inst
  // also print control signals
  always @(negedge clk)
    begin
      // print contents of registers
      $display("\nPrint Registers:");
	    for(i = 0; i < 8; i = i+1)
		begin
          $display("R%d = %d", i, registers[i]);
		end
      // print contents of data mem
      $display("\nPrint DataMem:");
      	for(i = 0; i < 10; i = i + 1)
      	begin
          $display("D[%d] = %d", i, data_memory[i]);
      	end
      // print control signals
      $display("\nControl Signals:");
      $display("reg_address_A: %b", reg_address_A);
      $display("reg_address_B: %b", reg_address_B);
      $display("reg_address_C: %b", reg_address_C);
      $display("reg_data_B: %b", reg_data_B);
      $display("reg_data_C: %b", reg_data_C);
      $display("cs_write_reg: %b", cs_write_reg);
      $display("cs_write_data_memory: %b", cs_write_data_memory);
      $display("cs_read_data_memory: %b", cs_read_data_memory);
      $display("cs_alu: %b", cs_alu);
      $display("cs_alu_select: %b", cs_alu_select);
    end

	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			pc = 16'd0; // Reset PC to address 0x00
		end
	end

	always @(posedge clk) begin

		// Instruction Fetch
		$display("\nPC = %b", pc);
		instruction = instruction_memory[pc];

		// Print Instruction
		$display("IF = %b", instruction);

		// Reset Control Signals
		cs_write_reg = 0;
		cs_alu = 4'b0000;
		cs_alu_select = 0;
		cs_write_data_memory = 0;
		cs_read_data_memory = 0;

		// Instruction Decode
		assign opcode = instruction[15:13]; // Set the opcode
		$display("Opcode =  %b" , opcode);

        // ---ADD---
		if (opcode == 3'b000) begin
		  $display("Instruction = ADD : %b" , instruction[6:0]);
          reg_address_A = instruction[12:10];
          reg_address_B = instruction[9:7];
		  reg_address_C = instruction[2:0];
          reg_data_B = registers[reg_address_B];
		  reg_data_C = registers[reg_address_C];
          cs_write_reg = 1;
          cs_write_data_memory = 0;
          cs_read_data_memory = 0;
		  cs_alu = 4'b0001;
		  cs_alu_select = 0;
		end

        // ---ADDI---
		if(opcode == 3'b001) begin
			$display("Instruction = ADDI : %b" , instruction[6:0]);
			// Add Immediate Instruction
			reg_address_A = instruction[12:10];
			cs_write_reg = 1;
          	cs_write_data_memory = 0;
          	cs_read_data_memory = 0;
			cs_alu = 4'b0001;
			cs_alu_select = 1;
		end

		// ---NAND---
		if (opcode == 3'b010) begin
		  $display("Instruction = NAND : %b" , instruction[6:0]);
          reg_address_A = instruction[12:10];
          reg_address_B = instruction[9:7];
		  reg_address_C = instruction[2:0];
          reg_data_B = registers[reg_address_B];
		  reg_data_C = registers[reg_address_C];
          cs_write_reg = 1;
          cs_write_data_memory = 0;
          cs_read_data_memory = 0;
          cs_alu = 4'b0010;
          cs_alu_select = 0;
		end

		// ---LUI---
		if (opcode == 3'b011) begin
		  $display("Instruction = LUI : %b" , instruction[6:0]);
          reg_address_A = instruction[12:10];
          cs_write_reg = 1;
          cs_write_data_memory = 0;
          cs_read_data_memory = 0;
          cs_alu = 4'b0011;
          cs_alu_select = 1;
		end

		// ---SW---
		if (opcode == 3'b100) begin
		  $display("Instruction = SW : %b" , instruction[6:0]);
          reg_address_A = instruction[12:10];
          reg_address_B = instruction[9:7];
          reg_data_B = registers[reg_address_B];
          cs_write_reg = 0;
          cs_write_data_memory = 1;
          cs_read_data_memory = 0;
          cs_alu = 4'b0001;
          cs_alu_select = 1;
		end

		// ---LW---
		if (opcode == 3'b101) begin
		  $display("Instruction = LW : %b" , instruction[6:0]);
          reg_address_A = instruction[12:10];
          reg_address_B = instruction[9:7];
          reg_data_B = registers[reg_address_B];
		  cs_write_reg = 1;
		  cs_write_data_memory = 0;
          cs_read_data_memory = 1;
		  cs_alu = 4'b0000;
		  cs_alu_select = 1;
		end

		// ---BEQ---
		if (opcode == 3'b110) begin
		  $display("Instruction = BEQ : %b" , instruction[6:0]);
		end

		// ---JALR---
		if (opcode == 3'b111) begin
		  $display("Instruction = JALR : %b" , instruction[6:0]);
		end
		// ID END

        // read all values from registers
		reg_address_A = instruction[12:10];
        reg_address_B = instruction[9:7];
     	reg_address_C = instruction[2:0];
		reg_data_B = registers[reg_address_B];
		reg_data_C = registers[reg_address_C];

		// ALU Operation
		immediate = { {9{1'b0}}, instruction[6:0]}; // This just extends the immediate value to 16 bits by padding 0's on the high order bits
		alu_operand0 = reg_data_B;
		alu_operand1 = (cs_alu_select == 0) ? reg_data_C : immediate;

		// ALU START
		case (cs_alu)
			4'b0000: // add
				begin
					alu_result 		= alu_operand0 + alu_operand1;
					alu_overflow 	= 0;
					alu_zero		= (alu_result == 0) ? 1 : 0;
                  	$display("Added %d + %d = %d", alu_operand0, alu_operand1, alu_result);
				end
			4'b0001: // Signed add
				begin
					alu_result = alu_operand0 + alu_operand1;

					if ((alu_operand0 >= 0 && alu_operand1 >= 0 && alu_result < 0) ||
						(alu_operand0 < 0 && alu_operand1 < 0 && alu_result >= 0)) begin
						alu_overflow = 1;
					end else begin
						alu_overflow = 0;
					end

					alu_zero = (alu_result == 0) ? 1 : 0;
					$display("Added %d + %d = %d",alu_operand0, alu_operand1, alu_result);
				end
			4'b0010: // bitwise NAND
			     begin
                   alu_result = alu_operand0 ~& alu_operand1;
                   $display("NANDed %b ~& %b = %b", alu_operand0, alu_operand1, alu_result);
			     end
			4'b0011: // PASS 1
			     begin
                   immediate = instruction[9:0];
                   alu_result = immediate << 6;
                   $display("Shifted %b 6 left to get %b", immediate, alu_result);
			     end
			4'b0100: // subtract
			     begin
			     end
			default:
				begin
					alu_zero 		= 0;
					alu_overflow 	= 0;
				end
		endcase
		// ALU END

		// Write Back To Reg
		if (cs_write_reg == 1) begin
			registers[reg_address_A] = alu_result;
			$display("Write R%d = %d",reg_address_A, alu_result);
		end

		//For SW Instruction: Load From Memory Into Reg
      	if (cs_write_data_memory) begin
          	data_address = alu_result;
			data_memory[data_address] = registers[reg_address_A];
          	$display("Stored r[%d] in d[%d]", reg_address_A, data_address);
		end

		//For LW Instruction:  Store From Reg Into Memory
      	if(cs_read_data_memory) begin
          	data_address = alu_result;
			registers[reg_address_A] = data_memory[data_address];
          	$display("Loaded d[%d] into r[%d]", data_address, reg_address_A);
		end

		// Increment PC According to pc_control
		case (pc_control)
			3'b000 : pc = pc + 1;
			default: pc = pc + 1;
		endcase
	end

endmodule
