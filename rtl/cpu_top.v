`default_nettype none
module cpu_top#( //use other modules to send specific instructions to provide the output
    parameter test_file = "test_alu.hex"
)(
    input wire clk,
    input wire reset
);

    // Program Counter
    reg [31:0] pc = 32'b0; //holds address of current instruction

    // Instruction memory: word-addressed, 32-bit wide
    reg [31:0] imem [0:1023]; //1024 instances of imem(an array) that holds 32 bits
    wire [31:0] instr;

    // data memory
    reg [31:0] dmem[0:1023];

    //before simulation
    initial begin
        $readmemh({"../selftest/", test_file}, imem);//fills array from the start from hex file
    end

    assign instr = imem[pc[11:2]]; //memory of instructions that is held at the address in pc

    // Decode stub — pull out fields, don't act on them yet
    // set bit locations by architecture
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //immediate values

    //set bit locations by architecture
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};  // I-type, sign-extended
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-Type
    wire [31:0] imm_s = {{21{instr[31]}}, instr[30:25], instr[11:8], instr[7]};  // S-Type
    wire [31:0] imm_u = {instr[31], instr[30:20], instr[19:12], {12{1'b0}}};  // U-type
    wire [31:0] imm_j = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0}; // J-type 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //ALU operations

    //ALU data values
    wire[31:0] result;
    wire[31:0] data1, data2;

    //decides which operations to do if R-type / if alu needs to add or sub, etc.
    wire alu_src = (opcode == 7'b0110011); 

    //decides if i need to store
    wire alu_store = (opcode == 7'b0100011);

    //if AUIPC called then must use different a variable
    wire alu_AUIPC = (opcode == 7'b0010111);

    wire use_funct7 = alu_src || (opcode == 7'b0010011 && funct3 == 3'b101); //includes the immediate versions of SRL/SRA

    //normal operations vs load operations
    wire [2:0] alu_op_lo = (opcode == 7'b0000011 || opcode == 7'b0100011 || alu_AUIPC)? 3'b000 : funct3; //forces to add if its load/store
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Branch Operations Mux

    reg comparsion;
    //funct3 dependent outputs
    parameter BEQ = 3'b000;
    parameter BNE = 3'b001;
    parameter BLT = 3'b100; 
    parameter BGE = 3'b101;
    parameter BLTU = 3'b110;
    parameter BGEU = 3'b111;
    //comparsion output dependent on funct3
    always@(*)begin
        case(funct3)
            BEQ: comparsion = (data1 == data2)? 1:0;
            BNE: comparsion = (data1 != data2)? 1:0;
            BLT: comparsion = ($signed(data1) < $signed(data2))? 1:0;
            BGE: comparsion = ($signed(data1) >= $signed(data2))? 1:0;
            BLTU: comparsion = (data1 < data2)? 1:0;
            BGEU: comparsion = (data1 >= data2)? 1:0;
            default: comparsion = 1'b0;
        endcase
    end
    //decides if you should allowed to branch between to addresses
    wire branch_taken = (opcode == 7'b1100011) && comparsion;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Write Enable to Registers

    //list of possible operation codes that allow for the funciton to write into the registers
    wire reg_write = (opcode == 7'b0110111) ||                          // U-type (LUI - upper immediate)
                     (opcode == 7'b0010111) ||                          // U-type (AUIPC - upper immediate)
                     (opcode == 7'b1101111) ||                          // J-type (JAL - jumps)
                     (opcode == 7'b1100111) ||                          // I-type (JALR - jumps)
                     (opcode == 7'b0010011) ||                          // I-type (OPI - Register-Register Arithmetic Immediate)
                     (opcode == 7'b0000011) ||                          // I-type (LOAD - LB, LH, LW, LBU, LHU)
                     (opcode == 7'b0110011) ||                          // R-type (OP - Register-Register Arithmetic)
                     (opcode == 7'b0001111);                            // FENCE

    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    // PC update 
    always @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else if(opcode == 7'b1101111) //Jump for the JAL function
            pc <= pc + imm_j;
        else if(branch_taken) //branch function
            pc <= pc + imm_b;
        else if(opcode == 7'b1100111) //Jump for JALR function
            pc <= (data1 + imm_i) & ({32'hFFFFFFFE});
        else
            pc <= pc + 4;
    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    wire is_ebreak = (opcode == 7'b1110011) && (instr[31:20] == 12'd1);

    // Debug: print what's happening each cycle
    always @(posedge clk) begin
            if (!reset && !is_ebreak ) 
            $display("pc=%0d instr=%h opcode=%b rd=%0d rs1=%0d imm_i=%0d data1=%0d data2=%0d result=%0d imm_j =%0d imm_b =%0d",
                       pc, instr, opcode, rd, rs1, $signed(imm_i), data1, data2, result, imm_j, imm_b);
    end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //data memory (store copy for rs2 to memory)
    wire[31:0] dmem_rdata = dmem[result[11:2]];

    wire[31:0] wb_data = (opcode == 7'b1101111 || opcode == 7'b1100111)? (pc + 4) : // JAL / JALR 
                         (opcode == 7'b0000011)? dmem_rdata : //bypasses alu since it's unneccessary
                         (opcode == 7'b0110111)? imm_u : result; //LUI bypasses alu also


    alu m2(
        .a((alu_AUIPC)? pc : data1),
        .b((alu_src)? data2 : //dealing with R-type 
           (alu_store)? imm_s : //if dealing with store force add
           (alu_AUIPC)? imm_u : imm_i), //default: I-type immediate (used by ADDI, JALR, loads)
        .alu_op({funct7[5] && use_funct7, alu_op_lo}),
        .result(result)
    );
    
    regfile m1(
        .clk(clk),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(wb_data),
        .write_enable(reg_write),
        .rs1_data(data1),
        .rs2_data(data2)
    );

    //store copy for rs2 to memory
    always@(posedge clk)begin
        if(opcode == 7'b0100011)
            dmem[result[11:2]] <= data2; 
    end

    
  
    

endmodule

`default_nettype wire