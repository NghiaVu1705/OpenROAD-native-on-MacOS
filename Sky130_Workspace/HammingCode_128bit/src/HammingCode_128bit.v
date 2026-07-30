// ============================================================
// Project  : HammingCode_128bit
// Design   : Hamming(137,128) SEC-DED Encoder / Decoder
// Platform : Sky130HD | Clock: 100 MHz (10 ns)
// Tool     : OpenROAD native macOS M1
//
// Codeword flat format (137 bits):
//   [136]   = p0  (overall parity, SEC-DED)
//   [135:8] = data_in[127:0]
//   [7:0]   = {p128, p64, p32, p16, p8, p4, p2, p1}
//             (bit7=p128, bit6=p64, ..., bit0=p1)
//
// Standard Hamming codeword positions (1..136):
//   Parity at: 1, 2, 4, 8, 16, 32, 64, 128
//   Data at:   all remaining positions
//   data_in[0] → cw_pos 3, data_in[1] → cw_pos 5, ...
//
// Bugs fixed vs original:
//   1. parity_in extraction: [8:0] wrong → [7:0]={p8..p1}, [136]=p0
//   2. recalc parity: incomplete XOR trees → full 128-bit coverage
//   3. Error correction: wrong position mapping → case statement lookup
//   4. SEC vs DED disambiguation: overall parity now used correctly
//   5. Encoder parity[3..8]: range errors → correct data_in indices
// ============================================================

`default_nettype none

// ------------------------------------------------------------------
// Encoder: 128-bit data → 137-bit codeword (combinational)
// ------------------------------------------------------------------
module hamming_encoder_128 (
    input  wire [127:0] data_in,
    output wire [136:0] codeword_out
);
    // parity[k] = pk+1 (p1=parity[0], p2=parity[1], ..., p128=parity[7])
    wire [7:0] parity;

    // ----------------------------------------------------------------
    // p1 (bit0=1 in codeword position space): 67 data bits
    // ----------------------------------------------------------------
    assign parity[0] = ^{data_in[0],   data_in[1],   data_in[3],   data_in[4],
                          data_in[6],   data_in[8],   data_in[10],  data_in[11],
                          data_in[13],  data_in[15],  data_in[17],  data_in[19],
                          data_in[21],  data_in[23],  data_in[25],  data_in[26],
                          data_in[28],  data_in[30],  data_in[32],  data_in[34],
                          data_in[36],  data_in[38],  data_in[40],  data_in[42],
                          data_in[44],  data_in[46],  data_in[48],  data_in[50],
                          data_in[52],  data_in[54],  data_in[56],  data_in[57],
                          data_in[59],  data_in[61],  data_in[63],  data_in[65],
                          data_in[67],  data_in[69],  data_in[71],  data_in[73],
                          data_in[75],  data_in[77],  data_in[79],  data_in[81],
                          data_in[83],  data_in[85],  data_in[87],  data_in[89],
                          data_in[91],  data_in[93],  data_in[95],  data_in[97],
                          data_in[99],  data_in[101], data_in[103], data_in[105],
                          data_in[107], data_in[109], data_in[111], data_in[113],
                          data_in[115], data_in[117], data_in[119], data_in[120],
                          data_in[122], data_in[124], data_in[126]};

    // ----------------------------------------------------------------
    // p2 (bit1=1): 67 data bits
    // ----------------------------------------------------------------
    assign parity[1] = ^{data_in[0],   data_in[2],   data_in[3],   data_in[5],
                          data_in[6],   data_in[9],   data_in[10],  data_in[12],
                          data_in[13],  data_in[16],  data_in[17],  data_in[20],
                          data_in[21],  data_in[24],  data_in[25],  data_in[27],
                          data_in[28],  data_in[31],  data_in[32],  data_in[35],
                          data_in[36],  data_in[39],  data_in[40],  data_in[43],
                          data_in[44],  data_in[47],  data_in[48],  data_in[51],
                          data_in[52],  data_in[55],  data_in[56],  data_in[58],
                          data_in[59],  data_in[62],  data_in[63],  data_in[66],
                          data_in[67],  data_in[70],  data_in[71],  data_in[74],
                          data_in[75],  data_in[78],  data_in[79],  data_in[82],
                          data_in[83],  data_in[86],  data_in[87],  data_in[90],
                          data_in[91],  data_in[94],  data_in[95],  data_in[98],
                          data_in[99],  data_in[102], data_in[103], data_in[106],
                          data_in[107], data_in[110], data_in[111], data_in[114],
                          data_in[115], data_in[118], data_in[119], data_in[121],
                          data_in[122], data_in[125], data_in[126]};

    // ----------------------------------------------------------------
    // p4 (bit2=1): 67 data bits
    // ----------------------------------------------------------------
    assign parity[2] = ^{data_in[1],   data_in[2],   data_in[3],   data_in[7],
                          data_in[8],   data_in[9],   data_in[10],  data_in[14],
                          data_in[15],  data_in[16],  data_in[17],  data_in[22],
                          data_in[23],  data_in[24],  data_in[25],  data_in[29],
                          data_in[30],  data_in[31],  data_in[32],  data_in[37],
                          data_in[38],  data_in[39],  data_in[40],  data_in[45],
                          data_in[46],  data_in[47],  data_in[48],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[60],
                          data_in[61],  data_in[62],  data_in[63],  data_in[68],
                          data_in[69],  data_in[70],  data_in[71],  data_in[76],
                          data_in[77],  data_in[78],  data_in[79],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[92],
                          data_in[93],  data_in[94],  data_in[95],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[116],
                          data_in[117], data_in[118], data_in[119], data_in[123],
                          data_in[124], data_in[125], data_in[126]};

    // ----------------------------------------------------------------
    // p8 (bit3=1): 64 data bits
    // ----------------------------------------------------------------
    assign parity[3] = ^{data_in[4],   data_in[5],   data_in[6],   data_in[7],
                          data_in[8],   data_in[9],   data_in[10],  data_in[18],
                          data_in[19],  data_in[20],  data_in[21],  data_in[22],
                          data_in[23],  data_in[24],  data_in[25],  data_in[33],
                          data_in[34],  data_in[35],  data_in[36],  data_in[37],
                          data_in[38],  data_in[39],  data_in[40],  data_in[49],
                          data_in[50],  data_in[51],  data_in[52],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[64],
                          data_in[65],  data_in[66],  data_in[67],  data_in[68],
                          data_in[69],  data_in[70],  data_in[71],  data_in[80],
                          data_in[81],  data_in[82],  data_in[83],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[96],
                          data_in[97],  data_in[98],  data_in[99],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119], data_in[127]};

    // ----------------------------------------------------------------
    // p16 (bit4=1): 63 data bits
    // ----------------------------------------------------------------
    assign parity[4] = ^{data_in[11],  data_in[12],  data_in[13],  data_in[14],
                          data_in[15],  data_in[16],  data_in[17],  data_in[18],
                          data_in[19],  data_in[20],  data_in[21],  data_in[22],
                          data_in[23],  data_in[24],  data_in[25],  data_in[41],
                          data_in[42],  data_in[43],  data_in[44],  data_in[45],
                          data_in[46],  data_in[47],  data_in[48],  data_in[49],
                          data_in[50],  data_in[51],  data_in[52],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[72],
                          data_in[73],  data_in[74],  data_in[75],  data_in[76],
                          data_in[77],  data_in[78],  data_in[79],  data_in[80],
                          data_in[81],  data_in[82],  data_in[83],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[104],
                          data_in[105], data_in[106], data_in[107], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119]};

    // ----------------------------------------------------------------
    // p32 (bit5=1): 63 data bits
    // ----------------------------------------------------------------
    assign parity[5] = ^{data_in[26],  data_in[27],  data_in[28],  data_in[29],
                          data_in[30],  data_in[31],  data_in[32],  data_in[33],
                          data_in[34],  data_in[35],  data_in[36],  data_in[37],
                          data_in[38],  data_in[39],  data_in[40],  data_in[41],
                          data_in[42],  data_in[43],  data_in[44],  data_in[45],
                          data_in[46],  data_in[47],  data_in[48],  data_in[49],
                          data_in[50],  data_in[51],  data_in[52],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[88],
                          data_in[89],  data_in[90],  data_in[91],  data_in[92],
                          data_in[93],  data_in[94],  data_in[95],  data_in[96],
                          data_in[97],  data_in[98],  data_in[99],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[104],
                          data_in[105], data_in[106], data_in[107], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119]};

    // ----------------------------------------------------------------
    // p64 (bit6=1): 63 data bits
    // ----------------------------------------------------------------
    assign parity[6] = ^{data_in[57],  data_in[58],  data_in[59],  data_in[60],
                          data_in[61],  data_in[62],  data_in[63],  data_in[64],
                          data_in[65],  data_in[66],  data_in[67],  data_in[68],
                          data_in[69],  data_in[70],  data_in[71],  data_in[72],
                          data_in[73],  data_in[74],  data_in[75],  data_in[76],
                          data_in[77],  data_in[78],  data_in[79],  data_in[80],
                          data_in[81],  data_in[82],  data_in[83],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[88],
                          data_in[89],  data_in[90],  data_in[91],  data_in[92],
                          data_in[93],  data_in[94],  data_in[95],  data_in[96],
                          data_in[97],  data_in[98],  data_in[99],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[104],
                          data_in[105], data_in[106], data_in[107], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119]};

    // ----------------------------------------------------------------
    // p128 (bit7=1): 8 data bits (codeword positions 129..136)
    // ----------------------------------------------------------------
    assign parity[7] = ^{data_in[120], data_in[121], data_in[122], data_in[123],
                          data_in[124], data_in[125], data_in[126], data_in[127]};

    // ----------------------------------------------------------------
    // p0: overall parity = XOR of all 136 bits (p1..p128 + all data)
    //     Ensures XOR of all 137 codeword bits = 0
    // ----------------------------------------------------------------
    wire p0;
    assign p0 = ^parity ^ ^data_in;

    // ----------------------------------------------------------------
    // Output: {p0, data[127:0], p128..p1}
    //   bit[136]   = p0
    //   bit[135:8] = data_in[127:0]
    //   bit[7:0]   = {p128,p64,p32,p16,p8,p4,p2,p1} = parity[7:0]
    // ----------------------------------------------------------------
    assign codeword_out = {p0, data_in, parity[7:0]};

endmodule


// ------------------------------------------------------------------
// Decoder: 137-bit codeword → 128-bit data + error flags
// (combinational)
// ------------------------------------------------------------------
module hamming_decoder_128 (
    input  wire [136:0] codeword_in,
    output reg  [127:0] data_out,
    output reg          sec,           // single error corrected
    output reg          ded,           // double error detected
    output reg  [7:0]   error_cw_pos  // codeword position of error (0=none)
);
    // ----------------------------------------------------------------
    // Extract received fields
    // ----------------------------------------------------------------
    wire        p0_received;
    wire [127:0] data_in;
    wire [7:0]   parity_received;  // {p128..p1}

    assign p0_received    = codeword_in[136];
    assign data_in        = codeword_in[135:8];
    assign parity_received = codeword_in[7:0];   // bit0=p1, bit7=p128

    // ----------------------------------------------------------------
    // Recalculate parity bits from received data (same equations as encoder)
    // ----------------------------------------------------------------
    wire [7:0] recalc;

    // recalc[0] = recalculated p1
    assign recalc[0] = ^{data_in[0],   data_in[1],   data_in[3],   data_in[4],
                          data_in[6],   data_in[8],   data_in[10],  data_in[11],
                          data_in[13],  data_in[15],  data_in[17],  data_in[19],
                          data_in[21],  data_in[23],  data_in[25],  data_in[26],
                          data_in[28],  data_in[30],  data_in[32],  data_in[34],
                          data_in[36],  data_in[38],  data_in[40],  data_in[42],
                          data_in[44],  data_in[46],  data_in[48],  data_in[50],
                          data_in[52],  data_in[54],  data_in[56],  data_in[57],
                          data_in[59],  data_in[61],  data_in[63],  data_in[65],
                          data_in[67],  data_in[69],  data_in[71],  data_in[73],
                          data_in[75],  data_in[77],  data_in[79],  data_in[81],
                          data_in[83],  data_in[85],  data_in[87],  data_in[89],
                          data_in[91],  data_in[93],  data_in[95],  data_in[97],
                          data_in[99],  data_in[101], data_in[103], data_in[105],
                          data_in[107], data_in[109], data_in[111], data_in[113],
                          data_in[115], data_in[117], data_in[119], data_in[120],
                          data_in[122], data_in[124], data_in[126]};

    // recalc[1] = recalculated p2
    assign recalc[1] = ^{data_in[0],   data_in[2],   data_in[3],   data_in[5],
                          data_in[6],   data_in[9],   data_in[10],  data_in[12],
                          data_in[13],  data_in[16],  data_in[17],  data_in[20],
                          data_in[21],  data_in[24],  data_in[25],  data_in[27],
                          data_in[28],  data_in[31],  data_in[32],  data_in[35],
                          data_in[36],  data_in[39],  data_in[40],  data_in[43],
                          data_in[44],  data_in[47],  data_in[48],  data_in[51],
                          data_in[52],  data_in[55],  data_in[56],  data_in[58],
                          data_in[59],  data_in[62],  data_in[63],  data_in[66],
                          data_in[67],  data_in[70],  data_in[71],  data_in[74],
                          data_in[75],  data_in[78],  data_in[79],  data_in[82],
                          data_in[83],  data_in[86],  data_in[87],  data_in[90],
                          data_in[91],  data_in[94],  data_in[95],  data_in[98],
                          data_in[99],  data_in[102], data_in[103], data_in[106],
                          data_in[107], data_in[110], data_in[111], data_in[114],
                          data_in[115], data_in[118], data_in[119], data_in[121],
                          data_in[122], data_in[125], data_in[126]};

    // recalc[2] = recalculated p4
    assign recalc[2] = ^{data_in[1],   data_in[2],   data_in[3],   data_in[7],
                          data_in[8],   data_in[9],   data_in[10],  data_in[14],
                          data_in[15],  data_in[16],  data_in[17],  data_in[22],
                          data_in[23],  data_in[24],  data_in[25],  data_in[29],
                          data_in[30],  data_in[31],  data_in[32],  data_in[37],
                          data_in[38],  data_in[39],  data_in[40],  data_in[45],
                          data_in[46],  data_in[47],  data_in[48],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[60],
                          data_in[61],  data_in[62],  data_in[63],  data_in[68],
                          data_in[69],  data_in[70],  data_in[71],  data_in[76],
                          data_in[77],  data_in[78],  data_in[79],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[92],
                          data_in[93],  data_in[94],  data_in[95],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[116],
                          data_in[117], data_in[118], data_in[119], data_in[123],
                          data_in[124], data_in[125], data_in[126]};

    // recalc[3] = recalculated p8
    assign recalc[3] = ^{data_in[4],   data_in[5],   data_in[6],   data_in[7],
                          data_in[8],   data_in[9],   data_in[10],  data_in[18],
                          data_in[19],  data_in[20],  data_in[21],  data_in[22],
                          data_in[23],  data_in[24],  data_in[25],  data_in[33],
                          data_in[34],  data_in[35],  data_in[36],  data_in[37],
                          data_in[38],  data_in[39],  data_in[40],  data_in[49],
                          data_in[50],  data_in[51],  data_in[52],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[64],
                          data_in[65],  data_in[66],  data_in[67],  data_in[68],
                          data_in[69],  data_in[70],  data_in[71],  data_in[80],
                          data_in[81],  data_in[82],  data_in[83],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[96],
                          data_in[97],  data_in[98],  data_in[99],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119], data_in[127]};

    // recalc[4] = recalculated p16
    assign recalc[4] = ^{data_in[11],  data_in[12],  data_in[13],  data_in[14],
                          data_in[15],  data_in[16],  data_in[17],  data_in[18],
                          data_in[19],  data_in[20],  data_in[21],  data_in[22],
                          data_in[23],  data_in[24],  data_in[25],  data_in[41],
                          data_in[42],  data_in[43],  data_in[44],  data_in[45],
                          data_in[46],  data_in[47],  data_in[48],  data_in[49],
                          data_in[50],  data_in[51],  data_in[52],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[72],
                          data_in[73],  data_in[74],  data_in[75],  data_in[76],
                          data_in[77],  data_in[78],  data_in[79],  data_in[80],
                          data_in[81],  data_in[82],  data_in[83],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[104],
                          data_in[105], data_in[106], data_in[107], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119]};

    // recalc[5] = recalculated p32
    assign recalc[5] = ^{data_in[26],  data_in[27],  data_in[28],  data_in[29],
                          data_in[30],  data_in[31],  data_in[32],  data_in[33],
                          data_in[34],  data_in[35],  data_in[36],  data_in[37],
                          data_in[38],  data_in[39],  data_in[40],  data_in[41],
                          data_in[42],  data_in[43],  data_in[44],  data_in[45],
                          data_in[46],  data_in[47],  data_in[48],  data_in[49],
                          data_in[50],  data_in[51],  data_in[52],  data_in[53],
                          data_in[54],  data_in[55],  data_in[56],  data_in[88],
                          data_in[89],  data_in[90],  data_in[91],  data_in[92],
                          data_in[93],  data_in[94],  data_in[95],  data_in[96],
                          data_in[97],  data_in[98],  data_in[99],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[104],
                          data_in[105], data_in[106], data_in[107], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119]};

    // recalc[6] = recalculated p64
    assign recalc[6] = ^{data_in[57],  data_in[58],  data_in[59],  data_in[60],
                          data_in[61],  data_in[62],  data_in[63],  data_in[64],
                          data_in[65],  data_in[66],  data_in[67],  data_in[68],
                          data_in[69],  data_in[70],  data_in[71],  data_in[72],
                          data_in[73],  data_in[74],  data_in[75],  data_in[76],
                          data_in[77],  data_in[78],  data_in[79],  data_in[80],
                          data_in[81],  data_in[82],  data_in[83],  data_in[84],
                          data_in[85],  data_in[86],  data_in[87],  data_in[88],
                          data_in[89],  data_in[90],  data_in[91],  data_in[92],
                          data_in[93],  data_in[94],  data_in[95],  data_in[96],
                          data_in[97],  data_in[98],  data_in[99],  data_in[100],
                          data_in[101], data_in[102], data_in[103], data_in[104],
                          data_in[105], data_in[106], data_in[107], data_in[108],
                          data_in[109], data_in[110], data_in[111], data_in[112],
                          data_in[113], data_in[114], data_in[115], data_in[116],
                          data_in[117], data_in[118], data_in[119]};

    // recalc[7] = recalculated p128
    assign recalc[7] = ^{data_in[120], data_in[121], data_in[122], data_in[123],
                          data_in[124], data_in[125], data_in[126], data_in[127]};

    // ----------------------------------------------------------------
    // Syndrome: recalc XOR received_parity
    // syndrome value = codeword position of error (0 = no parity error)
    // ----------------------------------------------------------------
    wire [7:0] syndrome;
    assign syndrome = recalc ^ parity_received;

    // ----------------------------------------------------------------
    // Overall parity check: XOR of all received bits [135:0]
    //   = XOR of data_in[127:0] XOR parity_received[7:0]
    //   compare with received p0
    // ----------------------------------------------------------------
    wire overall_error;
    assign overall_error = (^data_in ^ ^parity_received) ^ p0_received;

    // ----------------------------------------------------------------
    // SEC-DED decode logic
    //   syndrome==0, !overall_error → no error
    //   syndrome!=0,  overall_error → single bit error (correctable)
    //   syndrome!=0, !overall_error → double bit error (detected)
    //   syndrome==0,  overall_error → p0 only wrong (data ok)
    // ----------------------------------------------------------------
    wire has_syndrome;
    assign has_syndrome = |syndrome;

    always @(*) begin
        data_out      = data_in;   // default: pass through data
        sec           = 1'b0;
        ded           = 1'b0;
        error_cw_pos  = 8'd0;

        if (has_syndrome && overall_error) begin
            // Single bit error — correct it
            sec          = 1'b1;
            error_cw_pos = syndrome;

            // syndrome value = codeword position of error
            // Map to data_in index and flip the bit
            // Parity positions (1,2,4,8,16,32,64,128): no data flip needed
            case (syndrome)
                8'd  3: data_out[  0] = ~data_in[  0];
                8'd  5: data_out[  1] = ~data_in[  1];
                8'd  6: data_out[  2] = ~data_in[  2];
                8'd  7: data_out[  3] = ~data_in[  3];
                8'd  9: data_out[  4] = ~data_in[  4];
                8'd 10: data_out[  5] = ~data_in[  5];
                8'd 11: data_out[  6] = ~data_in[  6];
                8'd 12: data_out[  7] = ~data_in[  7];
                8'd 13: data_out[  8] = ~data_in[  8];
                8'd 14: data_out[  9] = ~data_in[  9];
                8'd 15: data_out[ 10] = ~data_in[ 10];
                8'd 17: data_out[ 11] = ~data_in[ 11];
                8'd 18: data_out[ 12] = ~data_in[ 12];
                8'd 19: data_out[ 13] = ~data_in[ 13];
                8'd 20: data_out[ 14] = ~data_in[ 14];
                8'd 21: data_out[ 15] = ~data_in[ 15];
                8'd 22: data_out[ 16] = ~data_in[ 16];
                8'd 23: data_out[ 17] = ~data_in[ 17];
                8'd 24: data_out[ 18] = ~data_in[ 18];
                8'd 25: data_out[ 19] = ~data_in[ 19];
                8'd 26: data_out[ 20] = ~data_in[ 20];
                8'd 27: data_out[ 21] = ~data_in[ 21];
                8'd 28: data_out[ 22] = ~data_in[ 22];
                8'd 29: data_out[ 23] = ~data_in[ 23];
                8'd 30: data_out[ 24] = ~data_in[ 24];
                8'd 31: data_out[ 25] = ~data_in[ 25];
                8'd 33: data_out[ 26] = ~data_in[ 26];
                8'd 34: data_out[ 27] = ~data_in[ 27];
                8'd 35: data_out[ 28] = ~data_in[ 28];
                8'd 36: data_out[ 29] = ~data_in[ 29];
                8'd 37: data_out[ 30] = ~data_in[ 30];
                8'd 38: data_out[ 31] = ~data_in[ 31];
                8'd 39: data_out[ 32] = ~data_in[ 32];
                8'd 40: data_out[ 33] = ~data_in[ 33];
                8'd 41: data_out[ 34] = ~data_in[ 34];
                8'd 42: data_out[ 35] = ~data_in[ 35];
                8'd 43: data_out[ 36] = ~data_in[ 36];
                8'd 44: data_out[ 37] = ~data_in[ 37];
                8'd 45: data_out[ 38] = ~data_in[ 38];
                8'd 46: data_out[ 39] = ~data_in[ 39];
                8'd 47: data_out[ 40] = ~data_in[ 40];
                8'd 48: data_out[ 41] = ~data_in[ 41];
                8'd 49: data_out[ 42] = ~data_in[ 42];
                8'd 50: data_out[ 43] = ~data_in[ 43];
                8'd 51: data_out[ 44] = ~data_in[ 44];
                8'd 52: data_out[ 45] = ~data_in[ 45];
                8'd 53: data_out[ 46] = ~data_in[ 46];
                8'd 54: data_out[ 47] = ~data_in[ 47];
                8'd 55: data_out[ 48] = ~data_in[ 48];
                8'd 56: data_out[ 49] = ~data_in[ 49];
                8'd 57: data_out[ 50] = ~data_in[ 50];
                8'd 58: data_out[ 51] = ~data_in[ 51];
                8'd 59: data_out[ 52] = ~data_in[ 52];
                8'd 60: data_out[ 53] = ~data_in[ 53];
                8'd 61: data_out[ 54] = ~data_in[ 54];
                8'd 62: data_out[ 55] = ~data_in[ 55];
                8'd 63: data_out[ 56] = ~data_in[ 56];
                8'd 65: data_out[ 57] = ~data_in[ 57];
                8'd 66: data_out[ 58] = ~data_in[ 58];
                8'd 67: data_out[ 59] = ~data_in[ 59];
                8'd 68: data_out[ 60] = ~data_in[ 60];
                8'd 69: data_out[ 61] = ~data_in[ 61];
                8'd 70: data_out[ 62] = ~data_in[ 62];
                8'd 71: data_out[ 63] = ~data_in[ 63];
                8'd 72: data_out[ 64] = ~data_in[ 64];
                8'd 73: data_out[ 65] = ~data_in[ 65];
                8'd 74: data_out[ 66] = ~data_in[ 66];
                8'd 75: data_out[ 67] = ~data_in[ 67];
                8'd 76: data_out[ 68] = ~data_in[ 68];
                8'd 77: data_out[ 69] = ~data_in[ 69];
                8'd 78: data_out[ 70] = ~data_in[ 70];
                8'd 79: data_out[ 71] = ~data_in[ 71];
                8'd 80: data_out[ 72] = ~data_in[ 72];
                8'd 81: data_out[ 73] = ~data_in[ 73];
                8'd 82: data_out[ 74] = ~data_in[ 74];
                8'd 83: data_out[ 75] = ~data_in[ 75];
                8'd 84: data_out[ 76] = ~data_in[ 76];
                8'd 85: data_out[ 77] = ~data_in[ 77];
                8'd 86: data_out[ 78] = ~data_in[ 78];
                8'd 87: data_out[ 79] = ~data_in[ 79];
                8'd 88: data_out[ 80] = ~data_in[ 80];
                8'd 89: data_out[ 81] = ~data_in[ 81];
                8'd 90: data_out[ 82] = ~data_in[ 82];
                8'd 91: data_out[ 83] = ~data_in[ 83];
                8'd 92: data_out[ 84] = ~data_in[ 84];
                8'd 93: data_out[ 85] = ~data_in[ 85];
                8'd 94: data_out[ 86] = ~data_in[ 86];
                8'd 95: data_out[ 87] = ~data_in[ 87];
                8'd 96: data_out[ 88] = ~data_in[ 88];
                8'd 97: data_out[ 89] = ~data_in[ 89];
                8'd 98: data_out[ 90] = ~data_in[ 90];
                8'd 99: data_out[ 91] = ~data_in[ 91];
                8'd100: data_out[ 92] = ~data_in[ 92];
                8'd101: data_out[ 93] = ~data_in[ 93];
                8'd102: data_out[ 94] = ~data_in[ 94];
                8'd103: data_out[ 95] = ~data_in[ 95];
                8'd104: data_out[ 96] = ~data_in[ 96];
                8'd105: data_out[ 97] = ~data_in[ 97];
                8'd106: data_out[ 98] = ~data_in[ 98];
                8'd107: data_out[ 99] = ~data_in[ 99];
                8'd108: data_out[100] = ~data_in[100];
                8'd109: data_out[101] = ~data_in[101];
                8'd110: data_out[102] = ~data_in[102];
                8'd111: data_out[103] = ~data_in[103];
                8'd112: data_out[104] = ~data_in[104];
                8'd113: data_out[105] = ~data_in[105];
                8'd114: data_out[106] = ~data_in[106];
                8'd115: data_out[107] = ~data_in[107];
                8'd116: data_out[108] = ~data_in[108];
                8'd117: data_out[109] = ~data_in[109];
                8'd118: data_out[110] = ~data_in[110];
                8'd119: data_out[111] = ~data_in[111];
                8'd120: data_out[112] = ~data_in[112];
                8'd121: data_out[113] = ~data_in[113];
                8'd122: data_out[114] = ~data_in[114];
                8'd123: data_out[115] = ~data_in[115];
                8'd124: data_out[116] = ~data_in[116];
                8'd125: data_out[117] = ~data_in[117];
                8'd126: data_out[118] = ~data_in[118];
                8'd127: data_out[119] = ~data_in[119];
                8'd129: data_out[120] = ~data_in[120];
                8'd130: data_out[121] = ~data_in[121];
                8'd131: data_out[122] = ~data_in[122];
                8'd132: data_out[123] = ~data_in[123];
                8'd133: data_out[124] = ~data_in[124];
                8'd134: data_out[125] = ~data_in[125];
                8'd135: data_out[126] = ~data_in[126];
                8'd136: data_out[127] = ~data_in[127];
                // Parity positions 1,2,4,8,16,32,64,128 → data unchanged
                default: ; // data_out = data_in (already assigned above)
            endcase

        end else if (has_syndrome && !overall_error) begin
            // Double bit error — detected, uncorrectable
            ded          = 1'b1;
            error_cw_pos = syndrome; // approximate (not exact for DED)

        end
        // else: no error or p0-only error → data_out = data_in (already set)
    end

endmodule


// ------------------------------------------------------------------
// Top: Registered pipeline wrapper (1-cycle latency)
// ------------------------------------------------------------------
module HammingCode_128bit (
    input  wire         clk,
    input  wire         rst_n,
    // Encode port
    input  wire [127:0] enc_data_in,
    input  wire         enc_valid,
    output reg  [136:0] enc_codeword,
    output reg          enc_out_valid,
    // Decode port
    input  wire [136:0] dec_codeword_in,
    input  wire         dec_valid,
    output reg  [127:0] dec_data_out,
    output reg          dec_sec,
    output reg          dec_ded,
    output reg  [7:0]   dec_error_pos,
    output reg          dec_out_valid
);
    wire [136:0] enc_cw_w;
    wire [127:0] dec_data_w;
    wire         dec_sec_w, dec_ded_w;
    wire [7:0]   dec_ep_w;

    hamming_encoder_128 u_enc (
        .data_in     (enc_data_in),
        .codeword_out(enc_cw_w)
    );

    hamming_decoder_128 u_dec (
        .codeword_in  (dec_codeword_in),
        .data_out     (dec_data_w),
        .sec          (dec_sec_w),
        .ded          (dec_ded_w),
        .error_cw_pos (dec_ep_w)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_codeword   <= 137'd0;
            enc_out_valid  <= 1'b0;
            dec_data_out   <= 128'd0;
            dec_sec        <= 1'b0;
            dec_ded        <= 1'b0;
            dec_error_pos  <= 8'd0;
            dec_out_valid  <= 1'b0;
        end else begin
            enc_out_valid  <= enc_valid;
            enc_codeword   <= enc_cw_w;
            dec_out_valid  <= dec_valid;
            dec_data_out   <= dec_data_w;
            dec_sec        <= dec_sec_w;
            dec_ded        <= dec_ded_w;
            dec_error_pos  <= dec_ep_w;
        end
    end

endmodule

`default_nettype wire
