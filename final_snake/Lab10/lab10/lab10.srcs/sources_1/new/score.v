`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/11 01:56:49
// Design Name: 
// Module Name: final_project
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



//(x,y) = px/10
module final(
input clk,
    input reset_n,
    input [4:0] snake_x,//(px/10
    input [4:0] snake_y,//(px/10
    input  [3:0] btn, 

    output reg food1_eaten, food2_eaten, food3_eaten,
    output reg signed [8:0]  score,
    output reg [2:0] P, // added
    output reg [4:0] food1_x, 
    output reg [4:0] food2_x,
    output reg [4:0] food3_x,
    output reg [4:0] food1_y, 
    output reg [4:0] food2_y, 
    output reg [4:0] food3_y
);

reg  [2:0]  P_next; //P, 
localparam [2:0] idle = 'd0, game1 = 'd1, wait1 = 'd2,
                             game2 = 'd3, wait2 = 'd4,
                             game3 = 'd5,
                             pass = 'd6, game_over = 'd7;

wire eat_done;


//FSM for game level////////////////////////////////////
always @(posedge clk) begin
    if (~reset_n) P <= idle;
    else          P <= P_next;
end
always @(*) begin
    case (P)
        idle:begin
            if (btn[0])             P_next = game1;
            else                    P_next = idle;
        end 
        game1:begin
            if(eat_done)            P_next = wait1;
            else if (score < 0)    P_next = game_over;
            else P_next = game1;
            end
        wait1:  P_next = game2;
        game2:begin
            if(eat_done)            P_next = wait2;
            else if (score < 0)    P_next = game_over;
            else P_next = game2;
            end
        wait2:   P_next = game3;
        game3:begin
            if(eat_done)            P_next = pass;
            else if (score < 0)    P_next = game_over;
            else P_next = game3;
            end
        pass:      P_next = pass;
        game_over: P_next = game_over;
    endcase
end
/////////////////////////////////////////////////////


reg[4:0] obstacle_x[0:9];
reg[4:0] obstacle_y[0:9];

// set obsitacle position(x,y) for each game

always @(*) begin//原clk
    case (P)
        idle:   begin // pick a num > 24
            obstacle_x[0] = 'd31;   obstacle_y[0] = 'd31;
            obstacle_x[1] = 'd31;   obstacle_y[1] = 'd31;
            obstacle_x[2] = 'd31;   obstacle_y[2] = 'd31;
            obstacle_x[3] = 'd31;   obstacle_y[3] = 'd31;
            obstacle_x[4] = 'd31;   obstacle_y[4] = 'd31;
            obstacle_x[5] = 'd31;   obstacle_y[5] = 'd31;
            obstacle_x[6] = 'd31;   obstacle_y[6] = 'd31;
            obstacle_x[7] = 'd31;   obstacle_y[7] = 'd31;
            obstacle_x[8] = 'd31;   obstacle_y[8] = 'd31;
            obstacle_x[9] = 'd31;   obstacle_y[9] = 'd31;
        end
        game1: begin
            obstacle_x[0] =  3;   obstacle_y[0] =  3;
            obstacle_x[1] =  5;   obstacle_y[1] =  6;
            obstacle_x[2] = 16;   obstacle_y[2] =  7;
            obstacle_x[3] = 20;   obstacle_y[3] = 14;
            obstacle_x[4] =  4;   obstacle_y[4] = 17;
        end
        game2: begin
            obstacle_x[0] =  3;   obstacle_y[0] =  6;
            obstacle_x[1] = 12;   obstacle_y[1] =  4;
            obstacle_x[2] = 14;   obstacle_y[2] =  5;
            obstacle_x[3] = 20;   obstacle_y[3] =  3;
            obstacle_x[4] = 17;   obstacle_y[4] = 16;
            obstacle_x[5] = 19;   obstacle_y[5] = 19; 
            obstacle_x[6] = 11;   obstacle_y[6] = 20;
            obstacle_x[7] =  2;   obstacle_y[7] = 17;
            obstacle_x[8] =  3;   obstacle_y[8] = 17;
            obstacle_x[9] =  6;   obstacle_y[9] = 13;
        end
        game3: begin
            obstacle_x[0] = 19;   obstacle_y[0] =  2;
            obstacle_x[1] =  4;   obstacle_y[1] =  4;
            obstacle_x[2] =  3;   obstacle_y[2] =  6;
            obstacle_x[3] =  2;   obstacle_y[3] =  8;
            obstacle_x[4] =  6;   obstacle_y[4] =  9;
            obstacle_x[5] = 18;   obstacle_y[5] =  8;
            obstacle_x[6] =  3;   obstacle_y[6] = 24;
            obstacle_x[7] = 17;   obstacle_y[7] = 11;
            obstacle_x[8] = 18;   obstacle_y[8] = 17;
            obstacle_x[9] = 13;   obstacle_y[9] = 21;
        end
    endcase
end

reg pre_hit_obstacle, hit_obstacle;

integer i;
always @(posedge clk) begin
    if (~reset_n) begin
        hit_obstacle <= 0;
        pre_hit_obstacle <= 0;
    end
    else begin
        pre_hit_obstacle <= hit_obstacle;
        hit_obstacle <= 0;
        for (i = 0; i < 10; i = i+1) begin
            
            if ((snake_x == obstacle_x[i]) && 
                (snake_y == obstacle_y[i])) 
                hit_obstacle <= 1;
        end
    end
    
end


//////////////////////////////////////////////////////


reg [4:0] food1_x, food2_x, food3_x;
reg [4:0] food1_y, food2_y, food3_y;
// set food position(x,y) for each game
always @(*) begin//原CLK   
    case (P)
        idle:begin
            food1_x <= 30;  food1_y <= 30;
            food2_x <= 30;  food2_y <= 30;
            food3_x <= 30;  food3_y <= 30;
        end
        game1: begin            
            food1_x <= (food1_eaten)? 30 :  2;  food1_y <= (food1_eaten)? 30 :  2;
            food2_x <= (food2_eaten)? 30 : 18;  food2_y <= (food2_eaten)? 30 : 12;
            food3_x <= (food3_eaten)? 30 : 15;  food3_y <= (food3_eaten)? 30 : 21;
        end
        game2:begin
            food1_x <= (food1_eaten)? 30 : 13;  food1_y <= (food1_eaten)? 30 :  5;
            food2_x <= (food2_eaten)? 30 : 17;  food2_y <= (food2_eaten)? 30 : 15;
            food3_x <= (food3_eaten)? 30 :  2;  food3_y <= (food3_eaten)? 30 : 20;
        end
        game3:begin
            food1_x <= (food1_eaten)? 30 : 21;  food1_y <= (food1_eaten)? 30 :  3;
            food2_x <= (food2_eaten)? 30 :  3;  food2_y <= (food2_eaten)? 30 :  5;
            food3_x <= (food3_eaten)? 30 : 18;  food3_y <= (food3_eaten)? 30 : 10;
        end
    endcase
end
//////////////////////////////////////////////////////


//eaten////////////////////////////////////////////////
reg pre_food1_eaten, pre_food2_eaten, pre_food3_eaten;

always @(posedge clk) begin
    if (~reset_n) begin
        food1_eaten <= 0;
        food2_eaten <= 0;
        food3_eaten <= 0;
        pre_food1_eaten <= 0;
        pre_food2_eaten <= 0;
        pre_food3_eaten <= 0;
    end
    else begin
        pre_food1_eaten <= food1_eaten;
        pre_food2_eaten <= food2_eaten;
        pre_food3_eaten <= food3_eaten;

        if ((P == game1)&&(P_next == wait1) ||
             (P == game2)&&(P_next == wait2) ) 
             begin
                food1_eaten <= 0;
                food2_eaten <= 0;
                food3_eaten <= 0;
             end
        else if ((P == game1)|(P == game2)|(P==game3)) begin
            if      ((snake_x == food1_x)&(snake_y == food1_y))
                food1_eaten <= 1;
            else if ((snake_x == food2_x)&(snake_y == food2_y))
                food2_eaten <= 1;
            else if ((snake_x == food3_x)&(snake_y == food3_y))
                food3_eaten <= 1;
            end
    end
    
end


assign eat_done = (food1_eaten & food2_eaten & food3_eaten);
//////////////////////////////////////////////////////



//source_cal/////////////////////////////////////////
always @(posedge clk) begin
    if (~reset_n)   score <= 0;
    else begin
        if ((P == game1) & (P_next == wait1)|
            (P == game2) & (P_next == wait2))    score <= 0;
        else if ((!pre_hit_obstacle)&(hit_obstacle))      score <= score -1;
        else if (((!pre_food1_eaten)&(food1_eaten)) |
                 ((!pre_food2_eaten)&(food2_eaten)) |
                 ((!pre_food3_eaten)&(food3_eaten)) )     score <= score +1;
    end
end
endmodule

/*
//VGA////////////////////////////////////
//food_eaten => not show
//snake > food  = obstacle >  background
//score show

//stam: 
//data_snake_out        snake
//data_food_out         food
//data_s0_out (0-3)     score 0~3
//data_pass_out         pass_background
//data_b1_out (1-3)     background level1-3

always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if  (P == pass)  rgb_next = data_pass_out;
  else  begin
    if      (snake_region)          rgb_next = data_snake_out;
    else if (food_region)           rgb_next = data_food_out;
        else if (source_region) begin
        case (score)
            0: rgb_next = data_s0_out;
            1: rgb_next = data_s1_out;
            2: rgb_next = data_s2_out;
            3: rgb_next = data_s3_out;
        endcase
    end
    else begin
        case (P)
            game1: rgb_next = data_b1_out;
            game2: rgb_next = data_b2_out;
            game3: rgb_next = data_b3_out;
        endcase
    end 
  end
end
// End of the video data display code.
*/
