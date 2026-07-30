// =============================================================
// Project  : CamAI_SNN
// Design   : Spiking Neural Network Inference Accelerator
// Platform : Sky130HD
// Desc     : LIF (Leaky Integrate-and-Fire) neuron array
//            4 input neurons, 4 hidden neurons, 2 output neurons
// =============================================================

module CamAI_SNN #(
    parameter N_IN     = 4,
    parameter N_HIDDEN = 4,
    parameter N_OUT    = 2,
    parameter DATA_W   = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [N_IN*DATA_W-1:0]  spike_in,
    input  wire                 valid_in,
    output wire [N_OUT-1:0]     spike_out,
    output wire                 valid_out
);

    // LIF membrane potential threshold
    localparam THRESHOLD = 8'hC0;
    localparam LEAK      = 8'h08;

    // Hidden layer membrane potentials
    reg [DATA_W-1:0] mem_hidden [0:N_HIDDEN-1];
    reg [DATA_W-1:0] mem_out    [0:N_OUT-1];
    reg [N_OUT-1:0]  spike_reg;
    reg              valid_reg;

    // Simple fixed synaptic weights (hidden layer)
    wire [DATA_W-1:0] w_ih [0:N_IN-1][0:N_HIDDEN-1];
    assign w_ih[0][0] = 8'h20; assign w_ih[0][1] = 8'h10;
    assign w_ih[0][2] = 8'h30; assign w_ih[0][3] = 8'h08;
    assign w_ih[1][0] = 8'h18; assign w_ih[1][1] = 8'h28;
    assign w_ih[1][2] = 8'h10; assign w_ih[1][3] = 8'h20;
    assign w_ih[2][0] = 8'h08; assign w_ih[2][1] = 8'h30;
    assign w_ih[2][2] = 8'h20; assign w_ih[2][3] = 8'h18;
    assign w_ih[3][0] = 8'h30; assign w_ih[3][1] = 8'h08;
    assign w_ih[3][2] = 8'h18; assign w_ih[3][3] = 8'h28;

    // Output layer weights
    wire [DATA_W-1:0] w_ho [0:N_HIDDEN-1][0:N_OUT-1];
    assign w_ho[0][0] = 8'h40; assign w_ho[0][1] = 8'h10;
    assign w_ho[1][0] = 8'h10; assign w_ho[1][1] = 8'h40;
    assign w_ho[2][0] = 8'h30; assign w_ho[2][1] = 8'h20;
    assign w_ho[3][0] = 8'h20; assign w_ho[3][1] = 8'h30;

    integer i, j;

    // Hidden layer: LIF dynamics
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N_HIDDEN; i = i + 1)
                mem_hidden[i] <= 8'h00;
        end else if (valid_in) begin
            for (i = 0; i < N_HIDDEN; i = i + 1) begin
                reg [DATA_W+1:0] sum;
                sum = mem_hidden[i] - LEAK;
                for (j = 0; j < N_IN; j = j + 1)
                    if (spike_in[j*DATA_W +: DATA_W] > 8'h80)
                        sum = sum + w_ih[j][i];
                mem_hidden[i] <= (sum[DATA_W+1]) ? 8'h00 :
                                 (sum > THRESHOLD) ? 8'h00 : sum[DATA_W-1:0];
            end
        end
    end

    // Output layer: LIF dynamics + spike generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N_OUT; i = i + 1)
                mem_out[i] <= 8'h00;
            spike_reg <= 0;
            valid_reg <= 0;
        end else begin
            valid_reg <= valid_in;
            for (i = 0; i < N_OUT; i = i + 1) begin
                reg [DATA_W+1:0] sum_out;
                sum_out = mem_out[i] - LEAK;
                for (j = 0; j < N_HIDDEN; j = j + 1)
                    if (mem_hidden[j] >= THRESHOLD)
                        sum_out = sum_out + w_ho[j][i];
                if (sum_out > THRESHOLD) begin
                    spike_reg[i] <= 1'b1;
                    mem_out[i]   <= 8'h00;
                end else begin
                    spike_reg[i] <= 1'b0;
                    mem_out[i]   <= sum_out[DATA_W-1:0];
                end
            end
        end
    end

    assign spike_out  = spike_reg;
    assign valid_out  = valid_reg;

endmodule
