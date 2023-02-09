module core
        #(
            parameter MEM_ADDR_WIDTH,
            parameter REG_ADDR_WIDTH,
            parameter DATA_WIDTH
        )
        (
            input logic clk,
            input logic rst,

            /*
                Memory
            */
            output logic[MEM_ADDR_WIDTH-1:0] mem_addr,
            output logic[DATA_WIDTH-1:0] mem_data_in,
            output logic mem_r_en,
            output logic mem_w_en,

            input logic[DATA_WIDTH-1:0] mem_data_out,
            input logic mem_rdy,
            input logic mem_cplt,

            /*
                Register
            */
            output logic[REG_ADDR_WIDTH-1:0] reg_r_addr_1,
            output logic[REG_ADDR_WIDTH-1:0] reg_r_addr_2,
            output logic[REG_ADDR_WIDTH-1:0] reg_w_addr,
            output logic[DATA_WIDTH-1:0] reg_w_data,
            output logic reg_w_en,

            input logic[DATA_WIDTH-1:0] reg_r_data_1,
            input logic[DATA_WIDTH-1:0] reg_r_data_2

`ifdef DISPLAY_PC
            ,
            output logic[MEM_ADDR_WIDTH-1:0] pc_out
`endif
        );

/*
    Stage 0 Definitions
*/
parameter s_0_data_bot = 0;
parameter s_0_data_top = s_0_data_bot + (DATA_WIDTH - 1);

parameter s_0_pc_bot = s_0_data_top + 1;
parameter s_0_pc_top = s_0_pc_bot + (MEM_ADDR_WIDTH - 1);

parameter s_0_valid = s_0_pc_top + 1;

logic load_0;

logic[s_0_valid:s_0_data_bot] stage_0_buf;

/*
    Stage 1 Definitions
*/
parameter s_1_w_reg_addr_bot = 0;
parameter s_1_w_reg_addr_top = s_1_w_reg_addr_bot + (REG_ADDR_WIDTH - 1);

parameter s_1_op_b_bot = s_1_w_reg_addr_top + 1;
parameter s_1_op_b_top = s_1_op_b_bot + (DATA_WIDTH - 1);

parameter s_1_op_a_bot = s_1_op_b_top + 1;
parameter s_1_op_a_top = s_1_op_a_bot + (DATA_WIDTH - 1);

parameter s_1_mem_addr_bot = s_1_op_a_top + 1;
parameter s_1_mem_addr_top = s_1_mem_addr_bot + (MEM_ADDR_WIDTH - 1);

parameter s_1_pc_bot = s_1_mem_addr_bot;
parameter s_1_pc_top = s_1_mem_addr_top;

parameter s_1_branch_add_bot = s_1_mem_addr_top + 1;
parameter s_1_branch_add_top = s_1_branch_add_bot + (MEM_ADDR_WIDTH - 1);

parameter s_1_alu_op_bot = s_1_branch_add_top + 1;
parameter s_1_alu_op_top = s_1_alu_op_bot + 3;

parameter s_1_valid = s_1_alu_op_top + 1;
parameter s_1_mem_r_en = s_1_valid + 1;
parameter s_1_mem_w_en = s_1_mem_r_en + 1;
parameter s_1_reg_w_en = s_1_mem_w_en + 1;
parameter s_1_jump = s_1_reg_w_en + 1;
parameter s_1_branch_on_equal = s_1_jump + 1;
parameter s_1_branch_on_nonequal = s_1_branch_on_equal + 1;
parameter s_1_branch_on_less = s_1_branch_on_nonequal + 1;
parameter s_1_branch_on_greater = s_1_branch_on_less + 1;

logic load_1;

logic[s_1_branch_on_greater:s_1_w_reg_addr_bot] stage_1_buf;

/*
    Stage 2 Definitions
*/
parameter s_2_w_reg_addr_bot = 0;
parameter s_2_w_reg_addr_top = s_2_w_reg_addr_bot + (REG_ADDR_WIDTH - 1);

parameter s_2_value_bot = s_2_w_reg_addr_top + 1;
parameter s_2_value_top = s_2_value_bot + (DATA_WIDTH - 1);

parameter s_2_mem_addr_bot = s_2_value_top + 1;
parameter s_2_mem_addr_top = s_2_mem_addr_bot + (MEM_ADDR_WIDTH - 1);

parameter s_2_pc_bot = s_2_mem_addr_bot;
parameter s_2_pc_top = s_2_mem_addr_top;

parameter s_2_valid = s_2_mem_addr_top + 1;
parameter s_2_mem_r_en = s_2_valid + 1;
parameter s_2_mem_w_en = s_2_mem_r_en + 1;
parameter s_2_reg_w_en = s_2_mem_w_en + 1;
parameter s_2_branch = s_2_reg_w_en + 1;

logic load_2;

logic[s_2_branch:s_2_w_reg_addr_bot] stage_2_buf;


logic valid_s_0;
assign valid_s_0 = stage_0_buf[s_0_valid];

logic valid_s_1;
assign valid_s_1 = stage_1_buf[s_1_valid];

logic valid_s_2;
assign valid_s_2 = stage_2_buf[s_2_valid];

/*
    Opcode Decode Definitions
*/
logic[MEM_ADDR_WIDTH-1:0] mem_addr_dec;
logic[REG_ADDR_WIDTH-1:0] w_reg_addr_dec;
logic[DATA_WIDTH-1:0] op_a_dec;
logic[DATA_WIDTH-1:0] op_b_dec;
logic[MEM_ADDR_WIDTH-1:0] branch_add_dec;
logic mem_r_en_dec;
logic mem_w_en_dec;
logic reg_w_en_dec;
logic reg_r_1_flag_dec;
logic reg_r_2_flag_dec;
logic jump_flag_dec;
logic[3:0] alu_op_dec;
logic branch_on_equal_flag_dec;
logic branch_on_nonequal_flag_dec;
logic branch_on_less_flag_dec;
logic branch_on_greater_flag_dec;

/*
    Program Counter Definitions
*/
logic[MEM_ADDR_WIDTH-1:0] pc;
logic[MEM_ADDR_WIDTH-1:0] pc_buf;
logic retry_pc;
logic pc_branch;
logic pc_stage_0_full;
logic pc_increment;

`ifdef DISPLAY_PC
    assign pc_out = pc;
`endif

/*
    State Machine Definitions
*/
enum logic [1:0] {INSTR, MEM} state;

/*
    ALU Definitions
*/
logic[DATA_WIDTH-1:0] result;
logic equal;
logic less;
logic greater;

/*
    Memory Input Logic
*/
assign mem_addr = (
                    state == INSTR &&
                    stage_2_buf[s_2_valid] == 1'b1 &&
                    (
                        (stage_2_buf[s_2_mem_r_en] == 1'b1 || stage_2_buf[s_2_mem_w_en] == 1'b1) ||
                        stage_2_buf[s_2_branch] == 1'b1
                    )
                  ) ? stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] : pc;

assign mem_data_in = stage_2_buf[s_2_value_top:s_2_value_bot];


assign mem_r_en = ~mem_w_en;

assign mem_w_en = (
                    mem_rdy == 1'b1 && 
                    state == INSTR &&
                    stage_2_buf[s_2_valid] == 1'b1 &&
                    stage_2_buf[s_2_mem_w_en] == 1'b1
                  ) ? 1'b1 : 1'b0;

/*
    Register Input Logic
*/

assign reg_r_addr_1 = stage_0_buf[7:4];
assign reg_r_addr_2 = stage_0_buf[3:0];

assign reg_w_addr = stage_2_buf[s_2_w_reg_addr_top:s_2_w_reg_addr_bot];

assign reg_w_data = (
                        stage_2_buf[s_2_mem_r_en] == 1'b1  
                    ) ? mem_data_out : stage_2_buf[s_2_value_top:s_2_value_bot];

assign reg_w_en = (
                    stage_2_buf[s_2_reg_w_en] == 1'b1 && 
                    stage_2_buf[s_2_valid] == 1'b1
                  ) ? 1'b1 : 1'b0;

/*
    Stage 0 Logic
*/
always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
        stage_0_buf <= ($bits(stage_0_buf))'('b0);
    end
    else
    begin

        if(pc_branch == 1'b1)
        begin
            stage_0_buf[s_0_valid] <= 1'b0;
        end
        else
        if(load_0 == 1'b1)
        begin
            stage_0_buf[s_0_data_top:s_0_data_bot] <= mem_data_out;
            stage_0_buf[s_0_pc_top:s_0_pc_bot] <= pc;
            stage_0_buf[s_0_valid] <= 1'b1;
        end
        else
        begin
            if(load_1 == 1'b1)
            begin
                stage_0_buf[s_0_valid] <= 1'b0;
            end
        end

    end
end

assign load_0 = (
                    state == INSTR && mem_cplt == 1'b1 &&
                    (load_1 == 1'b1 || (load_1 == 1'b0 && stage_0_buf[s_0_valid] == 1'b0)) &&
                    pc_branch == 1'b0
                ) ? 1'b1 : 1'b0;

/*
    Stage 1 Logic
*/
always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
        stage_1_buf <= ($bits(stage_1_buf))'('b0);
    end
    else
    begin

        if(pc_branch == 1'b1)
        begin
            stage_1_buf[s_1_valid] <= 1'b0;
        end
        else
        if(load_1 == 1'b1)
        begin
            stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot] <= mem_addr_dec;
            stage_1_buf[s_1_w_reg_addr_top:s_1_w_reg_addr_bot] <= w_reg_addr_dec;
            stage_1_buf[s_1_op_a_top:s_1_op_a_bot] <= op_a_dec;
            stage_1_buf[s_1_op_b_top:s_1_op_b_bot] <= op_b_dec;
            stage_1_buf[s_1_branch_add_top:s_1_branch_add_bot] <= branch_add_dec;
            stage_1_buf[s_1_alu_op_top:s_1_alu_op_bot] <= alu_op_dec;
            stage_1_buf[s_1_valid] <= 1'b1;
            stage_1_buf[s_1_mem_r_en] <= mem_r_en_dec;
            stage_1_buf[s_1_mem_w_en] <= mem_w_en_dec;
            stage_1_buf[s_1_reg_w_en] <= reg_w_en_dec;
            stage_1_buf[s_1_jump] <= jump_flag_dec;
            stage_1_buf[s_1_branch_on_equal] <= branch_on_equal_flag_dec;
            stage_1_buf[s_1_branch_on_nonequal] <= branch_on_nonequal_flag_dec;
            stage_1_buf[s_1_branch_on_less] <= branch_on_less_flag_dec;
            stage_1_buf[s_1_branch_on_greater] <= branch_on_greater_flag_dec;
        end
        else
        begin
            if(load_2 == 1'b1)
            begin
                stage_1_buf[s_1_valid] <= 1'b0;
            end
        end

    end
end

assign load_1 = (
                    (stage_1_buf[s_1_valid] == 1'b1 && load_2 == 1'b0) ||
                    stage_0_buf[s_0_valid] == 1'b0 ||
                    (
                        stage_0_buf[s_0_valid] == 1'b1 &&
                        (
                            (reg_r_1_flag_dec == 1'b1 && stage_1_buf[s_1_valid] == 1'b1 && stage_1_buf[s_1_reg_w_en] == 1'b1 && stage_1_buf[s_1_w_reg_addr_top:s_2_w_reg_addr_bot] == reg_r_addr_1) ||
                            (reg_r_1_flag_dec == 1'b1 && stage_2_buf[s_2_valid] == 1'b1 && stage_2_buf[s_2_reg_w_en] == 1'b1 && stage_2_buf[s_2_w_reg_addr_top:s_2_w_reg_addr_bot] == reg_r_addr_1) ||
                            (reg_r_2_flag_dec == 1'b1 && stage_1_buf[s_1_valid] == 1'b1 && stage_1_buf[s_1_reg_w_en] == 1'b1 && stage_1_buf[s_1_w_reg_addr_top:s_2_w_reg_addr_bot] == reg_r_addr_2) ||
                            (reg_r_2_flag_dec == 1'b1 && stage_2_buf[s_2_valid] == 1'b1 && stage_2_buf[s_2_reg_w_en] == 1'b1 && stage_2_buf[s_2_w_reg_addr_top:s_2_w_reg_addr_bot] == reg_r_addr_2)
                        )
                    )
                ) ? 1'b0 : 1'b1;


/*
    Stage 2 Logic
*/
always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
        stage_2_buf <= ($bits(stage_2_buf))'('b0);
    end
    else
    begin

        if(load_2 == 1'b1)
        begin
            stage_2_buf[s_2_w_reg_addr_top:s_2_w_reg_addr_bot] <= stage_1_buf[s_1_w_reg_addr_top:s_1_w_reg_addr_bot];
            stage_2_buf[s_2_value_top:s_2_value_bot] <= result;
            if(stage_1_buf[s_1_jump] == 1'b0)
            begin
                stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] <=  stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot];
            end
            else
            begin
                stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] <=  stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot] + stage_1_buf[s_1_branch_add_top:s_1_branch_add_bot];
            end
            stage_2_buf[s_2_valid] <= 1'b1;
            stage_2_buf[s_2_mem_r_en] <= stage_1_buf[s_1_mem_r_en];
            stage_2_buf[s_2_mem_w_en] <= stage_1_buf[s_1_mem_w_en];
            stage_2_buf[s_2_reg_w_en] <= stage_1_buf[s_1_reg_w_en];
            if(stage_1_buf[s_1_branch_on_equal] == 1'b1 && equal == 1'b1)
            begin
                stage_2_buf[s_2_branch] <= 1'b1;
                stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] <=  stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot] + stage_1_buf[s_1_branch_add_top:s_1_branch_add_bot];
            end
            else
            if(stage_1_buf[s_1_branch_on_nonequal] == 1'b1 && equal == 1'b0)
            begin
                stage_2_buf[s_2_branch] <= 1'b1;
                stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] <=  stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot] + stage_1_buf[s_1_branch_add_top:s_1_branch_add_bot];
            end
            else
            if(stage_1_buf[s_1_branch_on_less] == 1'b1 && less == 1'b1)
            begin
                stage_2_buf[s_2_branch] <= 1'b1;
                stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] <=  stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot] + stage_1_buf[s_1_branch_add_top:s_1_branch_add_bot];
            end
            else
            if(stage_1_buf[s_1_branch_on_greater] == 1'b1 && greater == 1'b1)
            begin
                stage_2_buf[s_2_branch] <= 1'b1;
                stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] <=  stage_1_buf[s_1_mem_addr_top:s_1_mem_addr_bot] + stage_1_buf[s_1_branch_add_top:s_1_branch_add_bot];
            end
            else
            begin
                stage_2_buf[s_2_branch] <= stage_1_buf[s_1_jump];
            end
        end
        else
        begin
            if(
                (stage_2_buf[s_2_branch] == 1'b0 && stage_2_buf[s_2_mem_r_en] == 1'b0 && stage_2_buf[s_2_mem_w_en] == 1'b0) ||
                (state == MEM && mem_cplt == 1'b1) ||
                (stage_2_buf[s_2_branch] == 1'b1 && mem_rdy == 1'b1)
              )
            begin
                stage_2_buf[s_2_valid] <= 1'b0;
            end
        end

    end
end

assign load_2 = (
                    stage_1_buf[s_1_valid] == 1'b1 && pc_branch == 1'b0 &&
                    (
                        (state == MEM && mem_cplt == 1'b1) ||
                        (stage_2_buf[s_2_valid] == 1'b1 && stage_2_buf[s_2_branch] == 1'b1 && mem_rdy == 1'b1) || // TODO: This line is redundant as it cant happen with pc_branch == 1'b0
                        (stage_2_buf[s_2_valid] == 1'b1 && stage_2_buf[s_2_branch] == 1'b0 &&  stage_2_buf[s_2_mem_r_en] == 1'b0 && stage_2_buf[s_2_mem_w_en] == 1'b0) ||
                        stage_2_buf[s_2_valid] == 1'b0
                    )
                ) ? 1'b1 : 1'b0;


/*
    Opcode Decode Logic
*/
always_comb
begin

    mem_addr_dec <= ($bits(mem_addr_dec))'('b0); // Can be dont care;
    w_reg_addr_dec <= ($bits(w_reg_addr_dec))'('b0); // Can be dont care
    op_a_dec <= ($bits(op_a_dec))'('b0); // Can be dont care
    op_b_dec <= ($bits(op_b_dec))'('b0); // Can be dont care
    alu_op_dec <= 4'b0000; // Can be dont care
    mem_r_en_dec <= 1'b0;
    mem_w_en_dec <= 1'b0;
    reg_w_en_dec <= 1'b0;
    reg_r_1_flag_dec <= 1'b0;
    reg_r_2_flag_dec <= 1'b0;
    jump_flag_dec <= 1'b0;
    branch_on_equal_flag_dec <= 1'b0;
    branch_on_nonequal_flag_dec <= 1'b0;
    branch_on_less_flag_dec <= 1'b0;
    branch_on_greater_flag_dec <= 1'b0;
    branch_add_dec <= ($bits(branch_add_dec))'('b0); // Can be dont care;

    if(stage_0_buf[15:13] == 3'b000)
    begin
        // Load direct
        mem_addr_dec <= {($bits(mem_addr_dec) - $bits(stage_0_buf[12:4]))'('b0), stage_0_buf[12:4]};
        w_reg_addr_dec <= stage_0_buf[3:0];
        op_a_dec <= ($bits(op_a_dec))'('b0); // Can be dont care
        op_b_dec <= ($bits(op_b_dec))'('b0); // Can be dont care
        alu_op_dec <= 4'b0000; // Can be dont care
        mem_r_en_dec <= 1'b1;
        mem_w_en_dec <= 1'b0;
        reg_w_en_dec <= 1'b1;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b0;
        jump_flag_dec <= 1'b0;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;
    end
    else
    if(stage_0_buf[15:13] == 3'b001)
    begin
        // Jump
        mem_addr_dec <= stage_0_buf[s_0_pc_top:s_0_pc_bot] - ($bits(mem_addr_dec))'('b1);
        w_reg_addr_dec <= ($bits(w_reg_addr_dec))'('b0); // Can be dont care
        op_a_dec <= ($bits(op_a_dec))'('b0); // Can be dont care
        op_b_dec <= ($bits(op_b_dec))'('b0); // Can be dont care
        alu_op_dec <= 4'b0000; // Can be dont care
        branch_add_dec <= {{($bits(branch_add_dec)-$bits(stage_0_buf[12:0])){stage_0_buf[12]}}, stage_0_buf[12:0]}; // sign extended
        mem_r_en_dec <= 1'b0;
        mem_w_en_dec <= 1'b0;
        reg_w_en_dec <= 1'b0;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b0;
        jump_flag_dec <= 1'b1;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;
    end
    else
    if(stage_0_buf[15:13] == 3'b010)
    begin
        // Store direct
        mem_addr_dec <= {($bits(mem_addr_dec) - $bits(stage_0_buf[12:4]))'('b0), stage_0_buf[12:4]};
        w_reg_addr_dec <= ($bits(w_reg_addr_dec))'('b0); // Can be dont care
        op_a_dec <= ($bits(op_a_dec))'('b0);
        op_b_dec <= reg_r_data_2;
        alu_op_dec <= 4'b0000;
        mem_r_en_dec <= 1'b0;
        mem_w_en_dec <= 1'b1;
        reg_w_en_dec <= 1'b0;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b1;
        jump_flag_dec <= 1'b0;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;
    end
    else
    if(stage_0_buf[15:13] == 3'b011)
    begin
        // Load immediate

        mem_addr_dec <= ($bits(mem_addr_dec))'('b0); // Can be dont care
        w_reg_addr_dec <= stage_0_buf[3:0];
        op_a_dec <= ($bits(op_a_dec))'('b0);
        alu_op_dec <= 4'b0000;
        mem_r_en_dec <= 1'b0;
        mem_w_en_dec <= 1'b0;
        reg_w_en_dec <= 1'b1;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b1;
        jump_flag_dec <= 1'b0;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;

        if(stage_0_buf[12] == 1'b0)
        begin
            // Load lower immediate
            op_b_dec <= {reg_r_data_2[15:8], stage_0_buf[11:4]};
        end
        else
        if(stage_0_buf[12] == 1'b1)
        begin
            // Load upper immediate
            op_b_dec <= {stage_0_buf[11:4], reg_r_data_2[7:0]};
        end
    end
    else
    if(stage_0_buf[15:13] == 3'b100)
    begin
        // Branch

        mem_addr_dec <= stage_0_buf[s_0_pc_top:s_0_pc_bot] - ($bits(mem_addr_dec))'('b1);
        w_reg_addr_dec <= ($bits(w_reg_addr_dec))'('b0); // Can be dont care
        op_a_dec <= ($bits(op_a_dec))'('b0); // Can be dont care
        op_b_dec <= ($bits(op_b_dec))'('b0); // Can be dont care
        alu_op_dec <= 4'b0000; // Can be dont care
        branch_add_dec <= {{($bits(branch_add_dec) - $bits(stage_0_buf[10:0])){stage_0_buf[10]}}, stage_0_buf[10:0]}; // sign extended
        mem_r_en_dec <= 1'b0;
        mem_w_en_dec <= 1'b0;
        reg_w_en_dec <= 1'b0;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b0;
        jump_flag_dec <= 1'b0;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;

        if(stage_0_buf[12:11] == 2'b00)
        begin
            // Branch if equal
            branch_on_equal_flag_dec <= 1'b1;
        end
        else
        if(stage_0_buf[12:11] == 2'b01)
        begin
            // Branch if not equal
            branch_on_nonequal_flag_dec <= 1'b1;
        end
        else
        if(stage_0_buf[12:11] == 2'b10)
        begin
            // Branch if less than
            branch_on_less_flag_dec <= 1'b1;
        end
        else
        if(stage_0_buf[12:11] == 2'b11)
        begin
            // Branch if greater than
            branch_on_greater_flag_dec <= 1'b1;
        end
    end
    else
    if(stage_0_buf[15:13] == 3'b101)
    begin
        // Add immediate
        mem_addr_dec <= ($bits(mem_addr_dec))'('b0); // Can be dont care
        w_reg_addr_dec <= stage_0_buf[3:0];
        op_a_dec <= reg_r_data_2;
        op_b_dec <= {($bits(op_b_dec) - $bits(stage_0_buf[12:4]))'('b0), stage_0_buf[12:4]};
        alu_op_dec <= 4'b0000;
        mem_r_en_dec <= 1'b0;
        mem_w_en_dec <= 1'b0;
        reg_w_en_dec <= 1'b1;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b1;
        jump_flag_dec <= 1'b0;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;
    end
    else
    if(stage_0_buf[15:13] == 3'b110)
    begin
        // Sub immediate
        mem_addr_dec <= ($bits(mem_addr_dec))'('b0); // Can be dont care
        w_reg_addr_dec <= stage_0_buf[3:0];
        op_a_dec <= reg_r_data_2;
        op_b_dec <= {($bits(op_b_dec) - $bits(stage_0_buf[12:4]))'('b0), stage_0_buf[12:4]};
        alu_op_dec <= 4'b0001;
        mem_r_en_dec <= 1'b0;
        mem_w_en_dec <= 1'b0;
        reg_w_en_dec <= 1'b1;
        reg_r_1_flag_dec <= 1'b0;
        reg_r_2_flag_dec <= 1'b1;
        jump_flag_dec <= 1'b0;
        branch_on_equal_flag_dec <= 1'b0;
        branch_on_nonequal_flag_dec <= 1'b0;
        branch_on_less_flag_dec <= 1'b0;
        branch_on_greater_flag_dec <= 1'b0;
    end
    else
    if(stage_0_buf[15:13] == 3'b111)
    begin
        // Register instructions

        if(stage_0_buf[12] == 1'b0)
        begin
            // ALU instructions
            
            mem_addr_dec <= ($bits(mem_addr_dec))'('b0); // Can be dont care
            w_reg_addr_dec <= stage_0_buf[3:0];
            op_a_dec <= reg_r_data_2;
            op_b_dec <= reg_r_data_1;
            alu_op_dec <= stage_0_buf[11:8];
            mem_r_en_dec <= 1'b0;
            mem_w_en_dec <= 1'b0;
            reg_w_en_dec <= 1'b1;
            reg_r_1_flag_dec <= 1'b1;
            reg_r_2_flag_dec <= 1'b1;
            jump_flag_dec <= 1'b0;
            branch_on_equal_flag_dec <= 1'b0;
            branch_on_nonequal_flag_dec <= 1'b0;
            branch_on_less_flag_dec <= 1'b0;
            branch_on_greater_flag_dec <= 1'b0;

                
            if(stage_0_buf[11:8] == 4'b0000)
            begin
                // Add
                // DEFAULTS
            end
            else
            if(stage_0_buf[11:8] == 4'b0001)
            begin
                // Sub
                // DEFAULTS
            end
            else
            if(stage_0_buf[11:8] == 4'b0010)
            begin
                // Multiply
                // DEFAULTS
            end
            else
            if(stage_0_buf[11:8] == 4'b0011)
            begin
                // AND
                // DEFAULTS
            end
            else
            if(stage_0_buf[11:8] == 4'b0100)
            begin
                // OR
                // DEFAULTS
            end
            else
            if(stage_0_buf[11:8] == 4'b0101)
            begin
                // XOR
                // DEFAULTS
            end
            else
            if(stage_0_buf[11:8] == 4'b0110)
            begin
                // One's complement
                reg_r_1_flag_dec <= 1'b0;
            end
            else
            if(stage_0_buf[11:8] == 4'b0111)
            begin
                // Two's complement
                reg_r_1_flag_dec <= 1'b0;
            end
            else
            if(stage_0_buf[11:8] == 4'b1000)
            begin
                // Compare
                reg_w_en_dec <= 1'b0;
            end
        end
        else
        if(stage_0_buf[12] == 1'b1)
        begin

            if(stage_0_buf[11:8] == 4'b0000)
            begin
                // Load indirect
                mem_addr_dec <= reg_r_data_1;
                w_reg_addr_dec <= stage_0_buf[3:0];
                op_a_dec <= ($bits(op_a_dec))'('b0); // Can be dont care
                op_b_dec <= ($bits(op_b_dec))'('b0); // Can be dont care
                alu_op_dec <= 4'b0000; // Can be dont care
                mem_r_en_dec <= 1'b1;
                mem_w_en_dec <= 1'b0;
                reg_w_en_dec <= 1'b1;
                reg_r_1_flag_dec <= 1'b1;
                reg_r_2_flag_dec <= 1'b0;
                jump_flag_dec <= 1'b0;
                branch_on_equal_flag_dec <= 1'b0;
                branch_on_nonequal_flag_dec <= 1'b0;
                branch_on_less_flag_dec <= 1'b0;
                branch_on_greater_flag_dec <= 1'b0;
            end
            else
            if(stage_0_buf[11:8] == 4'b0001)
            begin
                // Store indirect
                mem_addr_dec <= reg_r_data_1;
                w_reg_addr_dec <= ($bits(w_reg_addr_dec))'('b0); // Can be dont care
                op_a_dec <= ($bits(op_a_dec))'('b0);
                op_b_dec <= reg_r_data_2;
                alu_op_dec <= 4'b0000;
                mem_r_en_dec <= 1'b0;
                mem_w_en_dec <= 1'b1;
                reg_w_en_dec <= 1'b0;
                reg_r_1_flag_dec <= 1'b1;
                reg_r_2_flag_dec <= 1'b1;
                jump_flag_dec <= 1'b0;
                branch_on_equal_flag_dec <= 1'b0;
                branch_on_nonequal_flag_dec <= 1'b0;
                branch_on_less_flag_dec <= 1'b0;
                branch_on_greater_flag_dec <= 1'b0;
            end
            else
            if(stage_0_buf[11:8] == 4'b0010)
            begin
                // Move
                mem_addr_dec <= ($bits(mem_addr_dec))'('b0); // Can be dont care
                w_reg_addr_dec <= stage_0_buf[3:0];
                op_a_dec <= reg_r_data_1;
                op_b_dec <= ($bits(op_b_dec))'('b0);;
                alu_op_dec <= 4'b0000;
                mem_r_en_dec <= 1'b0;
                mem_w_en_dec <= 1'b0;
                reg_w_en_dec <= 1'b1;
                reg_r_1_flag_dec <= 1'b1;
                reg_r_2_flag_dec <= 1'b0;
                jump_flag_dec <= 1'b0;
                branch_on_equal_flag_dec <= 1'b0;
                branch_on_nonequal_flag_dec <= 1'b0;
                branch_on_less_flag_dec <= 1'b0;
                branch_on_greater_flag_dec <= 1'b0;
            end
        end
    end
    
end



/*
    Program Counter Logic
*/
always_comb
begin

    pc_branch <= 1'b0;
    pc_stage_0_full <= 1'b0;
    pc_increment <= 1'b0;

    if(mem_rdy == 1'b1 && stage_2_buf[s_2_valid] == 1'b1 && stage_2_buf[s_2_branch] == 1'b1)
    begin
        pc_branch <= 1'b1;
    end
    else
    if(mem_cplt == 1'b1 && state == INSTR && load_0 == 1'b0)
    begin
        pc_stage_0_full <= 1'b1;
    end
    else
    if(mem_rdy == 1'b1 && mem_r_en == 1'b1 &&
            (
                stage_2_buf[s_2_mem_r_en] == 1'b0 || 
                stage_2_buf[s_2_valid] == 1'b0 ||
                state == MEM
            )
            )
    begin
        pc_increment <= 1'b1;
    end

end

always_comb
begin

    if(pc_stage_0_full == 1'b1 && retry_pc == 1'b0)
    begin
        pc <= pc_buf - ($bits(pc_buf))'('b1);
    end
    else
    if(pc_increment == 1'b1 && retry_pc == 1'b1 && state == INSTR)
    begin
        pc <= pc_buf + ($bits(pc_buf))'('b1);
    end
    else
    begin
        pc <= pc_buf;
    end

end

always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
        pc_buf <= (MEM_ADDR_WIDTH)'('b0);
        retry_pc <= 1'b0;
    end
    else
    begin
        
        if(pc_branch == 1'b1)
        begin
            pc_buf <= stage_2_buf[s_2_mem_addr_top:s_2_mem_addr_bot] + ($bits(pc_buf))'('b1);
        end
        else
        if(pc_stage_0_full == 1'b1)
        begin
            if(retry_pc == 1'b0)
            begin
                pc_buf <= pc_buf - ($bits(pc_buf))'('b1);
            end
            retry_pc <= 1'b1;
        end
        else
        if(pc_increment == 1'b1 && retry_pc == 1'b1 && state == INSTR)
        begin
            pc_buf <= pc_buf + ($bits(pc_buf))'('d2);
            retry_pc <= 1'b0;
        end
        else
        if(pc_increment == 1'b1)
        begin
            pc_buf <= pc_buf + ($bits(pc_buf))'('b1);
            retry_pc <= 1'b0;
        end

    end
end


/*
    State Machine Logic
*/
always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        state <= INSTR;
    end
    else
    begin
        if(state == INSTR)
        begin
            if(mem_rdy == 1'b1 && stage_2_buf[s_2_valid] == 1'b1 && (stage_2_buf[s_2_mem_r_en] == 1'b1 || stage_2_buf[s_2_mem_w_en] == 1'b1))
            begin
                state <= MEM;
            end
        end
        else if(state == MEM)
        begin
            if(mem_cplt == 1'b1)
            begin
                state <= INSTR;
            end
        end
    end
end


alu #(
		.DATA_WIDTH(DATA_WIDTH),
		.OPCODE_WIDTH(4)
	)
	ALU
	(
        .clk(clk),
        .rst(rst),
		.op_a(stage_1_buf[s_1_op_a_top:s_1_op_a_bot]),
		.op_b(stage_1_buf[s_1_op_b_top:s_1_op_b_bot]),
        .opcode(stage_1_buf[s_1_alu_op_top:s_1_alu_op_bot]),
        .alu_active(stage_1_buf[s_1_valid]),

		.result(result),
		.equal(equal),
        .less(less),
        .greater(greater)
	);


endmodule
