`timescale 1ns / 1ps

module walk(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    // input  [2:0] game_level, //'d1: game1, 'd3: game2, 'd5: game3
    output [3:0] usr_led,
//    output [7:0] snake_x_o,
//    output [7:0] snake_y_o,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
);

// ====================== Body Length =======================
wire [3:0] body_show; // 0-indexed
assign body_show = ~usr_sw; // check
// ====================== Button ============================
// Declare system variables
wire [3:0] btn_level, btn_pressed;
reg  [3:0] prev_btn_level;
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);
debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);
debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);
debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);
//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = btn_level & ~prev_btn_level;// (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ===================== snake movement =========================
reg [7:0] snake_x [8:0];
reg [7:0] snake_y [8:0]; // reg [7:0](8 bits per body) snake_x [8:0] (9 nodes of body)
//assign snake_x_o = snake_x[0]; // assign snake head to output
////assign snake_y_o = snake_y[0]; // assign snake head to output
//assign snake_y_o = snake_y[0];
wire [7:0] snake_x_o = snake_x[0] / 5;
wire [7:0] snake_y_o = snake_y[0] / 5;
wire [2:0] P_score;
wire signed [8:0] score;
wire food1_eaten,food2_eaten,food3_eaten;
wire [4:0] food1_x, food2_x, food3_x, food1_y, food2_y, food3_y;
final score_cal (
    .clk(clk),
    .reset_n(reset_n),
    .snake_x(snake_x_o[4:0]),//(px/10
    .snake_y(snake_y_o[4:0]),
    .btn(btn_pressed), // check 

    .food1_eaten(food1_eaten),
    .food2_eaten(food2_eaten), 
    .food3_eaten(food3_eaten),
    .score(score),
    .P(P_score),
    .food1_x(food1_x), 
    .food2_x(food2_x),
    .food3_x(food3_x),
    .food1_y(food1_y), 
    .food2_y(food2_y), 
    .food3_y(food3_y)
);
assign usr_led[0] = food1_eaten;
assign usr_led[1] = food2_eaten;
assign usr_led[2] = food3_eaten;

// ====================== Sram Logic ========================
// Declare the video buffer size
localparam BUF_W = 160; // background buffer width
localparam BUF_H = 120; // background buffer height
localparam BUF_W_1 = 160; // background buffer width
localparam BUF_H_1 = 120; // background buffer height
localparam BUF_FOOD_W =5;
localparam BUF_FOOD_H =5;
localparam BUF_SCORE_W =20;
localparam BUF_SCORE_H =20;
// declare SRAM control signals
wire [16:0] bg_sram_addr_0; // start
wire [16:0] bg_sram_addr_1;
wire [ 4:0] food1_sram_addr, food2_sram_addr, food3_sram_addr;
wire [10:0] score_sram_addr;
wire [11:0] data_in;
wire [11:0] bg_data_out_0;
wire [11:0] bg_data_out_1, bg_data_out_2, bg_data_out_3, bg_data_out_win, bg_data_out_lose, data_out_food1, data_out_food2, data_out_food3, bg_data_out_score;
wire        sram_we_0, sram_en_0;
wire        sram_we_1, sram_en_1;
reg [17:0] bg_pixel_addr_0, bg_pixel_addr_1;
reg [ 4:0] food1_pixel_addr, food2_pixel_addr, food3_pixel_addr;
reg [10:0] score_pixel_addr;
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 159) // for VGA
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 119) // for VGA
wire food1_region, food2_region, food3_region;
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.

// sram for background 0
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_W*BUF_H), .FILE("start_bg.mem"))
  ram0 (.clk(clk), .we(sram_we_0), .en(sram_en_0),
          .addr(bg_sram_addr_0), .data_i(data_in_0), .data_o(bg_data_out_0));
// sram for background 1
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_W_1*BUF_H_1), .FILE("game_bg1.mem"))
  ram1 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(bg_sram_addr_1), .data_i(data_in_1), .data_o(bg_data_out_1));
          
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_W_1*BUF_H_1), .FILE("game_bg2.mem"))
  ram2 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(bg_sram_addr_1), .data_i(data_in_1), .data_o(bg_data_out_2));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_W_1*BUF_H_1), .FILE("game_bg3.mem"))
  ram3 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(bg_sram_addr_1), .data_i(data_in_1), .data_o(bg_data_out_3));
          
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_W_1*BUF_H_1), .FILE("game_bg_win.mem"))
  ram4 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(bg_sram_addr_1), .data_i(data_in_1), .data_o(bg_data_out_win));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_W_1*BUF_H_1), .FILE("game_bg_lose.mem"))
  ram5 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(bg_sram_addr_1), .data_i(data_in_1), .data_o(bg_data_out_lose));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_FOOD_W*BUF_FOOD_H), .FILE("food.mem"))
  ram6 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(food1_sram_addr), .data_i(data_in_1), .data_o(data_out_food1));


sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_SCORE_W*BUF_SCORE_H*4), .FILE("score.mem"))
  ram7 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(score_sram_addr), .data_i(data_in_1), .data_o(bg_data_out_score));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_FOOD_W*BUF_FOOD_H), .FILE("food.mem"))
  ram8 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(food2_sram_addr), .data_i(data_in_1), .data_o(data_out_food2));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BUF_FOOD_W*BUF_FOOD_H), .FILE("food.mem"))
  ram9 (.clk(clk), .we(sram_we_1), .en(sram_en_1),
          .addr(food3_sram_addr), .data_i(data_in_1), .data_o(data_out_food3));
assign sram_we_0 = usr_btn[2] && usr_btn[1]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_we_1 = usr_btn[3] && usr_btn[0]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en_0 = 1;          // Here, we always enable the SRAM block.
assign sram_en_1 = 1;          // Here, we always enable the SRAM block.
assign bg_sram_addr_1 = bg_pixel_addr_1;
assign bg_sram_addr_0 = bg_pixel_addr_0;
assign food1_sram_addr = food1_pixel_addr;
assign food2_sram_addr = food2_pixel_addr;
assign food3_sram_addr = food3_pixel_addr;
assign score_sram_addr = score_pixel_addr;
assign data_in_0 = 12'h000; // SRAM is read-only so we tie inputs to zeros.
assign data_in_1 = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// ====================== Background ========================
always @ (posedge clk) begin
  if (~reset_n) begin
    bg_pixel_addr_0  <= 0;
    bg_pixel_addr_1  <= 0;
    food1_pixel_addr <= 0;
    food2_pixel_addr <= 0;
    food3_pixel_addr <= 0;
    score_pixel_addr <= 0;
  end else begin
        // Scale up a 320x240 image for the 640x480 display.
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        bg_pixel_addr_0 <= (pixel_y >> 2) * BUF_W + (pixel_x >> 2);
        bg_pixel_addr_1 <= (pixel_y >> 2) * BUF_W + (pixel_x >> 2);
        food1_pixel_addr <= ((pixel_y - food1_y*20) >> 2) * 5 + ((pixel_x - food1_x*20) >> 2);
        food2_pixel_addr <= ((pixel_y - food2_y*20) >> 2) * 5 + ((pixel_x - food2_x*20) >> 2);
        food3_pixel_addr <= ((pixel_y - food3_y*20) >> 2) * 5 + ((pixel_x - food3_x*20) >> 2);
        case (score)
          0      : score_pixel_addr <=         ((pixel_y - 90) >> 2) * 20 + ((pixel_x - 520) >> 2);
          1      : score_pixel_addr <= 400   + ((pixel_y - 90) >> 2) * 20 + ((pixel_x - 520) >> 2);
          2      : score_pixel_addr <= 400*2 + ((pixel_y - 90) >> 2) * 20 + ((pixel_x - 520) >> 2);
          3      : score_pixel_addr <= 400*3 + ((pixel_y - 90) >> 2) * 20 + ((pixel_x - 520) >> 2);
          default: score_pixel_addr <=         ((pixel_y - 90) >> 2) * 20 + ((pixel_x - 520) >> 2);
        endcase
    end
end
// ========================== food region logic ==============

//assign food1_region =(food1_x >  1)&&(food1_y >  1)  &&
//                     (food1_x < 23)&&(food1_y < 23) && (!food1_eaten) &&
//                     ((pixel_x >= food1_x*20) && (pixel_x < 20*(food1_x + 1))) &&
//                     ((pixel_y >= food1_y*20) && (pixel_y < 20*(food1_y + 1)));
//
//assign food2_region =(food2_x > 1)&&(food2_y > 1)  &&
//                     (food2_x < 23)&&(food2_y < 23) && (!food2_eaten) && 
//                     ((pixel_x >= food2_x*20) && (pixel_x < 20*(food2_x + 1))) &&
//                     ((pixel_y >= food2_y*20) && (pixel_y < 20*(food2_y + 1)));
//
//assign food3_region =(food3_x >  1)&&(food3_y >  1) &&
//                     (food3_x < 23)&&(food3_y < 23) && (!food3_eaten) && 
//                     ((pixel_x >= food3_x*20) && (pixel_x < 20*(food3_x + 1))) &&
//                     ((pixel_y >= food3_y*20) && (pixel_y < 20*(food3_y + 1)));
//
assign food1_region = (!food1_eaten) &&
                     ((pixel_x >= food1_x*20) && (pixel_x < 20*(food1_x + 1))) &&
                     ((pixel_y >= food1_y*20) && (pixel_y < 20*(food1_y + 1)));

assign food2_region = (!food2_eaten) && 
                     ((pixel_x >= food2_x*20) && (pixel_x < 20*(food2_x + 1))) &&
                     ((pixel_y >= food2_y*20) && (pixel_y < 20*(food2_y + 1)));

assign food3_region = (!food3_eaten) && 
                     ((pixel_x >= food3_x*20) && (pixel_x < 20*(food3_x + 1))) &&
                     ((pixel_y >= food3_y*20) && (pixel_y < 20*(food3_y + 1)));

//wire food_region = (food1_region | food2_region | food3_region);

//wire score_region = ((pixel_x >= 260*2) & (pixel_x <= (260+41)*2) &
//                     (pixel_y >= 45 *2) & (pixel_y <= ( 45+41)*2));

wire score_region = ((pixel_x >= 260*2) & (pixel_x < (260+40)*2) &
                     (pixel_y >= 45 *2) & (pixel_y < ( 45+40)*2));
// =======================================================================
// FSM to control directions
localparam [2:0] S_START = 0, S_GAME = 1;//,S_DOWN = 2,S_LEFT = 3,S_RIGHT = 4;
reg [2:0] P, P_next;
always@(posedge clk) begin
    if(~reset_n) P <= S_START;
    else P <= P_next;
end

always@(*) begin
    case(P)
        S_START:
            if(btn_level[0]) P_next = S_GAME;
            else P_next = S_START;
        S_GAME:
            P_next = S_GAME;

    endcase
end
//assign usr_led[0] = P[0];
//assign usr_led[1] = P[1];
//assign usr_led[2] = P[2];

function isWallRegion; // TODO: add another two levels' walls
    input [7:0] grid_x;
    input [7:0] grid_y;
    input [1:0] level;
    begin
    case(level)
        2'b01:
            isWallRegion = (grid_x >= 30 && grid_y >= 55 && grid_x <= 85 && grid_y <= 60);
        2'b10: // TODO /2
            isWallRegion = (grid_x >= 30 && grid_y >= 30 && grid_x <= 65 && grid_y <= 50) || (grid_x >= 20 && grid_x <= 75 && grid_y == 85) || (grid_x == 90 && grid_y >=25 && grid_y <= 80);
        2'b11: // TODO
            isWallRegion = (grid_x == 20 && grid_y >= 40 && grid_y <= 90) || (grid_x >= 25 && grid_x <= 85 && grid_y == 90) || (grid_x >= 45 && grid_x <= 90 && grid_y == 45) || (grid_x == 95 && grid_y >= 20 && grid_y <= 75) || (grid_x >= 40 && grid_x <=75 && grid_y >= 60 && grid_y <= 80);
    endcase
    end
endfunction

localparam [1:0] S_UP = 0, S_DOWN = 1, S_RIGHT = 2, S_LEFT = 3;
reg [1:0] Q;
wire [1:0] level = (P_score == 'd1)? 2'b01: (P_score == 'd3)? 2'b10: (P_score == 'd5)? 2'b11: 2'b01; // output from another module, default is 2'b01 // 2'b11; // 01,10,11
always@(posedge clk) begin
    if(~reset_n || (food1_eaten && food2_eaten && food3_eaten)) begin // TODO: add if next level
        Q <= S_RIGHT;
        snake_x[0] <= 50;
        snake_x[1] <= 45;
        snake_x[2] <= 40;
        snake_x[3] <= 35;
        snake_x[4] <= 30;
        snake_x[5] <= 25;
        snake_x[6] <= 20;
        snake_x[7] <= 15;
        snake_x[8] <= 10;
        snake_y[0] <= 105;
        snake_y[1] <= 105;
        snake_y[2] <= 105;
        snake_y[3] <= 105;
        snake_y[4] <= 105;
        snake_y[5] <= 105;
        snake_y[6] <= 105;
        snake_y[7] <= 105;
        snake_y[8] <= 105;
    end else if (btn_pressed && P == S_GAME) begin
        if(btn_pressed[0] && Q != S_DOWN && snake_y[0] - 5 >= 10 && ~isWallRegion(snake_x[0],snake_y[0] - 5,level)) begin // move upwards
            Q <= S_UP;
            snake_y[0] <= snake_y[0] - 5;
            snake_y[1] <= snake_y[0];
            snake_y[2] <= snake_y[1];
            snake_y[3] <= snake_y[2];
            snake_y[4] <= snake_y[3];
            snake_y[5] <= snake_y[4];
            snake_y[6] <= snake_y[5];
            snake_y[7] <= snake_y[6];
            snake_y[8] <= snake_y[7];
            snake_x[1] <= snake_x[0];
            snake_x[2] <= snake_x[1];
            snake_x[3] <= snake_x[2];
            snake_x[4] <= snake_x[3];
            snake_x[5] <= snake_x[4];
            snake_x[6] <= snake_x[5];
            snake_x[7] <= snake_x[6];
            snake_x[8] <= snake_x[7];
        end else if(btn_pressed[1] && Q != S_UP && snake_y[0] + 5 < 110 && ~isWallRegion(snake_x[0],snake_y[0] + 5,level)) begin // move downwards
            Q <= S_DOWN;
            snake_y[0] <= snake_y[0] + 5;
            snake_y[1] <= snake_y[0];
            snake_y[2] <= snake_y[1];
            snake_y[3] <= snake_y[2];
            snake_y[4] <= snake_y[3];
            snake_y[5] <= snake_y[4];
            snake_y[6] <= snake_y[5];
            snake_y[7] <= snake_y[6];
            snake_y[8] <= snake_y[7];
            snake_x[1] <= snake_x[0];
            snake_x[2] <= snake_x[1];
            snake_x[3] <= snake_x[2];
            snake_x[4] <= snake_x[3];
            snake_x[5] <= snake_x[4];
            snake_x[6] <= snake_x[5];
            snake_x[7] <= snake_x[6];
            snake_x[8] <= snake_x[7];
        end else if(btn_pressed[2] && Q != S_RIGHT && snake_x[0] - 5 >= 10 && ~isWallRegion(snake_x[0] - 5,snake_y[0],level)) begin // move left
            Q <= S_LEFT;
            snake_x[0] <= snake_x[0] - 5;
            snake_y[1] <= snake_y[0];
            snake_y[2] <= snake_y[1];
            snake_y[3] <= snake_y[2];
            snake_y[4] <= snake_y[3];
            snake_y[5] <= snake_y[4];
            snake_y[6] <= snake_y[5];
            snake_y[7] <= snake_y[6];
            snake_y[8] <= snake_y[7];
            snake_x[1] <= snake_x[0];
            snake_x[2] <= snake_x[1];
            snake_x[3] <= snake_x[2];
            snake_x[4] <= snake_x[3];
            snake_x[5] <= snake_x[4];
            snake_x[6] <= snake_x[5];
            snake_x[7] <= snake_x[6];
            snake_x[8] <= snake_x[7];
        end else if(btn_pressed[3] && Q != S_LEFT && snake_x[0] + 5 < 110 && ~isWallRegion(snake_x[0] + 5,snake_y[0],level)) begin // move right
            Q <= S_RIGHT;
            snake_x[0] <= snake_x[0] + 5;
            snake_y[1] <= snake_y[0];
            snake_y[2] <= snake_y[1];
            snake_y[3] <= snake_y[2];
            snake_y[4] <= snake_y[3];
            snake_y[5] <= snake_y[4];
            snake_y[6] <= snake_y[5];
            snake_y[7] <= snake_y[6];
            snake_y[8] <= snake_y[7];
            snake_x[1] <= snake_x[0];
            snake_x[2] <= snake_x[1];
            snake_x[3] <= snake_x[2];
            snake_x[4] <= snake_x[3];
            snake_x[5] <= snake_x[4];
            snake_x[6] <= snake_x[5];
            snake_x[7] <= snake_x[6];
            snake_x[8] <= snake_x[7];
        end
    end
end
// ======================== VGA Control ==========================
// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// Send data to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

function is_in_a_grid;
    input [9:0] pixel_x;
    input [9:0] pixel_y;
    input [7:0] grid_x;
    input [7:0] grid_y;
    begin 
       is_in_a_grid = (pixel_x >= grid_x && pixel_x <= grid_x + 4 && pixel_y >= grid_y && pixel_y <= grid_y + 4);
    end
endfunction
    
function is_in_game_field;
    input [9:0] pixel_x;
    input [9:0] pixel_y;
    begin 
       is_in_game_field = (pixel_x >= 10 && pixel_x <= 110 && pixel_y <= 110 && pixel_y >= 10);
    end
endfunction

always @(*) begin
  if (~video_on) begin
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  end else if (P == S_START) begin
    rgb_next = bg_data_out_0;
//  end else if (~is_in_game_field(pixel_x>>1,pixel_y>>1)) begin // background
//    rgb_next = bg_data_out_1; //12'h000;
  end else if (P_score == 'd6) begin // win
    rgb_next = bg_data_out_win;
  end else if (P_score == 'd7) begin // lose
    rgb_next = bg_data_out_lose;
  end else if(score_region)begin
    rgb_next = bg_data_out_score;
  end else if (is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[1],snake_y[1]) | is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[2],snake_y[2]) | is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[3],snake_y[3]) | is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[4],snake_y[4]) | (is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[5],snake_y[5]) & body_show[0]) | (is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[6],snake_y[6]) & body_show[1]) | (is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[7],snake_y[7]) & body_show[2]) | (is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[8],snake_y[8]) & body_show[3])) begin
    rgb_next = 12'h3a4;
  end else if (is_in_a_grid(pixel_x>>2,pixel_y>>2,snake_x[0],snake_y[0])) begin
    rgb_next = 12'h163;
  end else if (food1_region) begin
    rgb_next = data_out_food1;
  end else if (food2_region) begin
    rgb_next = data_out_food2;
  end else if (food3_region) begin
    rgb_next = data_out_food3;
  end else if(level == 2'b01) begin // background
    rgb_next = bg_data_out_1; //12'h000;
  end else if(level == 2'b10) begin
    rgb_next = bg_data_out_2;
  end else if(level == 2'b11) begin
    rgb_next = bg_data_out_3;
  end else begin
    rgb_next = 12'h000; // nothing by default
  end
end
endmodule
