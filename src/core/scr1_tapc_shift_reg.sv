/// Copyright by Syntacore LLC © 2016, 2017. See LICENSE for details
/// @file       <scr1_tapc_shift_reg.sv>
/// @brief      TAPC Shift register. Parameterized implementation of JTAG TAPC's Shift Register.
///

module scr1_tapc_shift_reg #(
    parameter   int unsigned            SCR1_WIDTH       = 8,   // Register width, bits
    parameter   logic [SCR1_WIDTH-1:0]  SCR1_RESET_VALUE = '0   // Register's value after reset
) (
    input  logic                    clk,            // Clock
    input  logic                    rst_n,          // Async reset
    input  logic                    rst_n_sync,     // Sync reset
                                                    // TAP FSM's control signals:
    input  logic                    fsm_dr_select,  //   - for this DR selection (operation enabling);
    input  logic                    fsm_dr_capture, //   - to capture parallel input's data into shift register;
    input  logic                    fsm_dr_shift,   //   - to enable data shifting;
                                                    // Inputs:
    input  logic                    din_serial,     //   - serial (shift_reg[msb/SCR1_WIDTH]);
    input  logic [SCR1_WIDTH-1:0]   din_parallel,   //   - parallel (shift register's input).
                                                    // Outputs:
    output logic                    dout_serial,    //   - serial (shift_reg[0]);
    output logic [SCR1_WIDTH-1:0]   dout_parallel   //   - parallel (shift register's output).
);

//-------------------------------------------------------------------------------
// Local signals declaration
//-------------------------------------------------------------------------------
logic [SCR1_WIDTH-1:0]   shift_reg;

//-------------------------------------------------------------------------------
// Shift register
//-------------------------------------------------------------------------------
generate
    if (SCR1_WIDTH > 1)
    begin : dr_shift_reg

        always_ff @(posedge clk, negedge rst_n)
        begin
            if (~rst_n) begin
                shift_reg <= SCR1_RESET_VALUE;
            end
            else if (~rst_n_sync) begin
                shift_reg <= SCR1_RESET_VALUE;
            end
            else if (fsm_dr_select & fsm_dr_capture) begin
                shift_reg <= din_parallel;
            end
            else if (fsm_dr_select & fsm_dr_shift) begin
                shift_reg <= {din_serial, shift_reg[SCR1_WIDTH-1:1]};
            end
        end

    end
    else begin : dr_shift_reg

        always_ff @(posedge clk, negedge rst_n)
        begin
            if (~rst_n) begin
                shift_reg <= SCR1_RESET_VALUE;
            end
            else if (~rst_n_sync) begin
                shift_reg <= SCR1_RESET_VALUE;
            end
            else if (fsm_dr_select & fsm_dr_capture) begin
                shift_reg <= din_parallel;
            end
            else if (fsm_dr_select & fsm_dr_shift) begin
                shift_reg <= din_serial;
            end
        end

    end
endgenerate

//-------------------------------------------------------------------------------
// Parallel output
//-------------------------------------------------------------------------------
assign dout_parallel = shift_reg;

//-------------------------------------------------------------------------------
// Serial output
//-------------------------------------------------------------------------------
assign dout_serial = shift_reg[0];

`ifdef SCR1_SYN_OFF_EN
// pragma synthesis_off
//-------------------------------------------------------------------------------
// Assertion
//-------------------------------------------------------------------------------

// X checks
SCR1_SVA_TAPC_SHIFTREG_XCHECK : assert property (
    @(posedge clk) disable iff (~rst_n)
    !$isunknown({
        rst_n_sync,
        fsm_dr_select,
        fsm_dr_capture,
        fsm_dr_shift,
        din_serial,
        din_parallel
    })
) else begin
    $error("TAPC Shift Reg error: unknown values");
    //$finish();
end

// pragma synthesis_on
`endif // SCR1_SYN_OFF_EN

endmodule : scr1_tapc_shift_reg
