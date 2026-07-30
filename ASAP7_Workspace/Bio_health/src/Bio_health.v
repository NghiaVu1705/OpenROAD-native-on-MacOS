// =============================================================
// Project  : Bio_health
// Design   : Biosignal Processor (ECG/PPG Peak Detector)
// Platform : Sky130HD
// Desc     : Moving average filter + threshold-based peak
//            detection for ECG/PPG signals (12-bit ADC input)
// =============================================================

module Bio_health #(
    parameter DATA_W    = 12,
    parameter WIN_SIZE  = 8,     // Moving average window
    parameter FIFO_DEPTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [DATA_W-1:0]    adc_in,
    input  wire                 adc_valid,
    output reg  [DATA_W-1:0]    filtered_out,
    output reg                  peak_detected,
    output reg                  hr_valid,
    output reg  [7:0]           heart_rate      // BPM (beats per minute)
);

    // Moving average filter
    reg [DATA_W-1:0]    window [0:WIN_SIZE-1];
    reg [DATA_W+3-1:0]  sum_reg;
    reg [3:0]           win_idx;

    // Peak detection state
    reg [DATA_W-1:0]    prev_sample;
    reg [DATA_W-1:0]    threshold;
    reg                 rising;

    // Heart rate counter
    reg [15:0]          rr_counter;
    reg [15:0]          rr_interval;

    // Adaptive threshold (75% of recent max)
    reg [DATA_W-1:0]    local_max;
    reg [7:0]           max_decay;

    integer i;

    // Moving average filter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg  <= 0;
            win_idx  <= 0;
            filtered_out <= 0;
            for (i = 0; i < WIN_SIZE; i = i + 1)
                window[i] <= 0;
        end else if (adc_valid) begin
            sum_reg     <= sum_reg - window[win_idx] + adc_in;
            window[win_idx] <= adc_in;
            win_idx     <= (win_idx == WIN_SIZE-1) ? 0 : win_idx + 1;
            filtered_out <= sum_reg[DATA_W+3-1:3]; // divide by 8
        end
    end

    // Adaptive threshold update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            local_max <= 0;
            threshold <= 12'h400;
            max_decay <= 0;
        end else if (adc_valid) begin
            if (filtered_out > local_max)
                local_max <= filtered_out;
            max_decay <= max_decay + 1;
            if (max_decay == 8'hFF) begin
                local_max <= local_max - (local_max >> 4);
            end
            threshold <= {1'b0, local_max[DATA_W-1:1]} +
                         {2'b0, local_max[DATA_W-1:2]}; // 75%
        end
    end

    // Peak detection (slope sign change above threshold)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sample   <= 0;
            rising        <= 0;
            peak_detected <= 0;
            rr_counter    <= 0;
            rr_interval   <= 0;
            heart_rate    <= 0;
            hr_valid      <= 0;
        end else if (adc_valid) begin
            peak_detected <= 0;
            hr_valid      <= 0;
            rr_counter    <= rr_counter + 1;

            if (filtered_out > prev_sample)
                rising <= 1;
            else if (filtered_out < prev_sample && rising &&
                     prev_sample > threshold) begin
                // Peak found
                rising        <= 0;
                peak_detected <= 1;
                rr_interval   <= rr_counter;
                rr_counter    <= 0;

                // HR = 60 * Fs / RR_interval (Fs=500Hz -> 30000/RR)
                if (rr_counter > 0)
                    heart_rate <= 30000 / rr_counter;
                hr_valid <= 1;
            end
            prev_sample <= filtered_out;
        end
    end

endmodule
