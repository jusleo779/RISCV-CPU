`default_nettype none
module cpu_top#( //use other modules to send specific instructions to provide the output
    parameter test_file = "test_alu.hex"
)(
    input wire clk,
    input wire reset
);

//Pipelining(Variables)

    //Instruction Fetch / Decode
    reg [31:0] if_id_instr; 
    reg [31:0] if_id_pc;    

    //Instruction Decode / Execute 
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_imm_i;
    reg [31:0] id_ex_imm_j;
    reg [31:0] id_ex_imm_b;
    reg [31:0] id_ex_imm_s; 
    reg [31:0] id_ex_imm_u;
    reg [31:0] id_ex_data1;
    reg [31:0] id_ex_data2; 
    reg [6:0] id_ex_opcode;        //saved for memory
    reg [6:0] id_ex_funct7;
    reg [2:0] id_ex_funct3; 
    reg id_ex_alu_src;
    reg id_ex_alu_store;
    reg id_ex_alu_AUIPC;
    reg id_ex_use_funct7;
    reg [2:0] id_ex_alu_op_lo;
    reg [4:0] id_ex_rd;            //saved for write back
    reg id_ex_reg_write;           //saved for write back
    reg [4:0] id_ex_rs1;           //saved for forwarding
    reg [4:0] id_ex_rs2;           //saved for forwarding

    // Execute / Memory
    reg[6:0] ex_mem_opcode;
    reg ex_mem_reg_write;
    reg[31:0] ex_mem_result;
    reg[31:0] ex_mem_data2;
    reg[4:0] ex_mem_rd;
    reg[31:0] ex_mem_imm_u;
    reg [31:0] ex_mem_pc;

    // Memory / Write Back
    reg[31:0] mem_wb_wb_data;
    reg mem_wb_reg_write;
    reg[4:0] mem_wb_rd;




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Instruction Fetch Stage

    // Program Counter
    reg [31:0] pc = 32'b0; //holds address of current instruction


    // Instruction memory: word-addressed, 32-bit wide
    reg [31:0] imem [0:1023]; //1024 instances of imem(an array) that holds 32 bits
    wire [31:0] instr;

    // data memory
    reg [31:0] dmem[0:1023];

    //before simulation (IF- Instruction Fetch)
    initial begin
        $readmemh({"../selftest/", test_file}, imem);//fills array from the start from hex file
    end

    assign instr = imem[pc[11:2]]; //memory of instructions that is held at the address in pc

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instruction Decode Stage

    // Decode stub — pull out fields, don't act on them yet
    // set bit locations by architecture (R-Type)
    wire [6:0] opcode = if_id_instr[6:0];
    wire [4:0] rd     = if_id_instr[11:7];
    wire [2:0] funct3 = if_id_instr[14:12];
    wire [4:0] rs1    = if_id_instr[19:15];
    wire [4:0] rs2    = if_id_instr[24:20];
    wire [6:0] funct7 = if_id_instr[31:25];

    //Immediate values
    //set bit locations by architecture
    wire [31:0] imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};  // I-type, sign-extended
    wire [31:0] imm_b = {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0}; // B-Type
    wire [31:0] imm_s = {{21{if_id_instr[31]}}, if_id_instr[30:25], if_id_instr[11:8], if_id_instr[7]};  // S-Type
    wire [31:0] imm_u = {if_id_instr[31], if_id_instr[30:20], if_id_instr[19:12], {12{1'b0}}};  // U-type
    wire [31:0] imm_j = {{12{if_id_instr[31]}}, if_id_instr[19:12], if_id_instr[20], if_id_instr[30:25], if_id_instr[24:21], 1'b0}; // J-type 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Execute Stage    
    
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

    //Forwarding
        //checks if the addresses are equal, there is no x0 being sent, & checks if it writes(if not it fails)
    wire ex_mem_matches_rs1 = ((id_ex_rs1 == ex_mem_rd) && (ex_mem_rd != 0) && ex_mem_reg_write);
    wire mem_wb_matches_rs1 = ((id_ex_rs1 == mem_wb_rd) && (mem_wb_rd != 0) && mem_wb_reg_write);

        //checks if it's fits critera before saving it as the data1 value
    wire [31:0] fwd_a_ex_mem = (ex_mem_matches_rs1)? ex_mem_result :
                               (mem_wb_matches_rs1)? mem_wb_wb_data : id_ex_data1; 

        //checks if the addresses are equal, there is no x0 being sent, & checks if it writes(if not it fails)
    wire ex_mem_matches_rs2 = ((id_ex_rs2 == ex_mem_rd) && (ex_mem_rd != 0) && ex_mem_reg_write);
    wire mem_wb_matches_rs2 = ((id_ex_rs2 == mem_wb_rd) && (mem_wb_rd != 0) && mem_wb_reg_write);

        //checks if it's fits critera before saving it as the data2 value
    wire [31:0] fwd_b_ex_mem = (ex_mem_matches_rs2)? ex_mem_result :
                               (mem_wb_matches_rs2)? mem_wb_wb_data : id_ex_data2; 


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
        case(id_ex_funct3)
            BEQ: comparsion = (fwd_a_ex_mem == fwd_b_ex_mem)? 1:0;
            BNE: comparsion = (fwd_a_ex_mem != fwd_b_ex_mem)? 1:0;
            BLT: comparsion = ($signed(fwd_a_ex_mem) < $signed(fwd_b_ex_mem))? 1:0;
            BGE: comparsion = ($signed(fwd_a_ex_mem) >= $signed(fwd_b_ex_mem))? 1:0;
            BLTU: comparsion = (fwd_a_ex_mem < fwd_b_ex_mem)? 1:0;
            BGEU: comparsion = (fwd_a_ex_mem >= fwd_b_ex_mem)? 1:0;
            default: comparsion = 1'b0;
        endcase
    end
    //decides if you should allowed to branch between to addresses
    wire branch_taken = (id_ex_opcode == 7'b1100011) && comparsion;
    
    //flushing(instructions after a JAL/JALR/Branch the next instruction should be skipped)
    wire flush = (id_ex_opcode == 7'b1101111) || branch_taken || (id_ex_opcode == 7'b1100111);
    

    // PC update 
    always @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else if(id_ex_opcode == 7'b1101111) //Jump for the JAL function
            pc <= id_ex_pc + id_ex_imm_j;
        else if(branch_taken) //branch function
            pc <= id_ex_pc + id_ex_imm_b;
        else if(id_ex_opcode == 7'b1100111) //Jump for JALR function
            pc <= (fwd_a_ex_mem + id_ex_imm_i) & ({32'hFFFFFFFE});
        else
            pc <=  pc + 4;
    end
   

    alu m2(
        .a((id_ex_alu_AUIPC)? id_ex_pc : fwd_a_ex_mem),
        .b((id_ex_alu_src)? fwd_b_ex_mem : //dealing with R-type 
           (id_ex_alu_store)? id_ex_imm_s : //if dealing with store force add
           (id_ex_alu_AUIPC)? id_ex_imm_u : id_ex_imm_i), //default: I-type immediate (used by ADDI, JALR, loads)
        .alu_op({id_ex_funct7[5] && id_ex_use_funct7, id_ex_alu_op_lo}),
        .result(result)
    );

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Memory Stage

    //store copy for rs2 to memory
    always@(posedge clk)begin
        if(ex_mem_opcode == 7'b0100011)
            dmem[ex_mem_result[11:2]] <= ex_mem_data2; 
    end

    //data memory (store copy for rs2 to memory)
    wire[31:0] dmem_rdata = dmem[ex_mem_result[11:2]];

    wire[31:0] wb_data = (ex_mem_opcode == 7'b1101111 || ex_mem_opcode == 7'b1100111)? (ex_mem_pc + 4) : // JAL / JALR 
                         (ex_mem_opcode == 7'b0000011)? dmem_rdata : //bypasses alu since it's unneccessary
                         (ex_mem_opcode == 7'b0110111)? ex_mem_imm_u : ex_mem_result; //LUI bypasses alu also
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Write Back Stage

    //Write Enable to Registers
    //list of possible operation codes that allow for the funciton to write into the registers
    wire reg_write = (opcode == 7'b0110111) ||                          // U-type (LUI - upper immediate)
                     (opcode == 7'b0010111) ||                          // U-type (AUIPC - upper immediate)
                     (opcode == 7'b1101111) ||                          // J-type (JAL - jumps)
                     (opcode == 7'b1100111) ||                          // I-type (JALR - jumps)
                     (opcode == 7'b0010011) ||                          // I-type (OPI - Register-Register Arithmetic Immediate)
                     (opcode == 7'b0000011) ||                          // I-type (LOAD - LB, LH, LW, LBU, LHU)
                     (opcode == 7'b0110011);                            // R-type (OP - Register-Register Arithmetic)

    //writes the data / sets the data1 & data2
    regfile m1(
        .clk(clk),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(mem_wb_rd),
        .rd_data(mem_wb_wb_data),
        .write_enable(mem_wb_reg_write),
        .rs1_data(data1),
        .rs2_data(data2)
    );


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//DEBUGGING    
    wire is_ebreak = (opcode == 7'b1110011) && (if_id_instr[31:20] == 12'd1);

    // Debug: print what's happening each cycle
    always @(posedge clk) begin
    if (!reset && !is_ebreak)
        $display("IF: pc=%0d | ID: instr=%h rs1=%0d rs2=%0d rd=%0d | EX: op=%b rs1=%0d rd=%0d res=%0d | MEM: rd=%0d wb=%0d | WB: rd=%0d data=%0d rw=%b",
            pc,
            if_id_instr, rs1, rs2, rd,
            id_ex_opcode, id_ex_rs1, id_ex_rd, result,
            ex_mem_rd, wb_data,
            mem_wb_rd, mem_wb_wb_data, mem_wb_reg_write
            );
    end
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Pipelining(saving instructions from previous states to be used)
 
 // IF(Instruction Fetch) / ID (Instruction Decode)

    always@(posedge clk)begin
        if(reset)begin
            if_id_instr <= 32'd0;
            if_id_pc <= 32'd0;
        end
        else if(flush) 
            if_id_instr <= 32'd0;
        else begin
            if_id_instr <= instr;
            if_id_pc <= pc;
        end
        
    end    

  // ID (Instruction Decode) / EX (Execute)

    always@(posedge clk)begin
        if(reset)begin
            id_ex_pc <= 32'd0;
            id_ex_imm_i <= 32'd0;
            id_ex_imm_j <= 32'd0;
            id_ex_imm_b <= 32'd0;
            id_ex_imm_s <= 32'd0;
            id_ex_imm_u <= 32'd0;
            id_ex_data1 <= 32'd0;
            id_ex_data2 <= 32'd0;
            id_ex_opcode <= 7'd0;
            id_ex_funct7 <= 7'd0;
            id_ex_funct3 <= 3'd0;
            id_ex_alu_src <= 0;
            id_ex_alu_store <= 0;
            id_ex_alu_AUIPC <= 0;
            id_ex_use_funct7 <= 0;
            id_ex_alu_op_lo <= 3'd0;
            id_ex_rd <= 5'd0;
            id_ex_reg_write <= 0;
            id_ex_rs1 <= 5'd0;
            id_ex_rs2 <= 5'd0;
        end
        else if(flush)begin 
            id_ex_opcode <= 7'b0000000;
            id_ex_reg_write <= 1'b0; 
        end
        else begin
            id_ex_pc <= if_id_pc;
            id_ex_imm_i <= imm_i;
            id_ex_imm_j <= imm_j;
            id_ex_imm_b <= imm_b;
            id_ex_imm_s <= imm_s;
            id_ex_imm_u <= imm_u;
            id_ex_data1 <= data1;
            id_ex_data2 <= data2;
            id_ex_opcode <= opcode;
            id_ex_funct7 <= funct7;
            id_ex_funct3 <= funct3;
            id_ex_alu_src <= alu_src;
            id_ex_alu_store <= alu_store;
            id_ex_alu_AUIPC <= alu_AUIPC;
            id_ex_use_funct7 <= use_funct7;
            id_ex_alu_op_lo <= alu_op_lo;
            id_ex_rd <= rd;
            id_ex_reg_write <= reg_write;
            id_ex_rs1 <= rs1;
            id_ex_rs2 <= rs2;
        end
    end    

   // EX(Execute) / MEM(Memory)
    always@(posedge clk)begin
        if(reset)begin
            //ex_mem_opcode;
            ex_mem_reg_write <= 0;
            ex_mem_result <= 32'd0;
            ex_mem_data2 <= 32'd0;
            ex_mem_rd <= 5'd0;
            ex_mem_imm_u <= 32'd0;
            ex_mem_pc <= 32'd0;
            ex_mem_opcode <= 7'd0;
        end
        else begin
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_result <= result;
            ex_mem_data2 <= fwd_b_ex_mem;
            ex_mem_rd <= id_ex_rd;
            ex_mem_imm_u <= id_ex_imm_u;
            ex_mem_pc <= id_ex_pc;
            ex_mem_opcode <= id_ex_opcode;
        end
    end

    //Memory / Write back
    always@(posedge clk)begin
        if(reset)begin
            mem_wb_wb_data <= 32'd0;
            mem_wb_reg_write <= 0;
            mem_wb_rd <= 5'd0;
        end
        else begin
            mem_wb_wb_data <= wb_data;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_rd <= ex_mem_rd;
        end
    end


endmodule

`default_nettype wire