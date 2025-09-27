
# Dlab-Final: Snake Game on FPGA

## Overview  
This project implements a classic **Snake Game** on FPGA hardware as the final assignment for the Dlab course. The game consists of **six screens** (start, three levels, win, lose). The player navigates the snake to eat food, avoid obstacles and walls, and progress through levels.  

Key features include:  
- Each level contains three food items, obstacles, and walls  
- Eating all three food items advances to the next level  
- If the snake collides (or score becomes negative), the game ends  
- Player input via buttons (up, down, left, right)  
- Snake length adjustable via switches (range: 5 to 9) — higher length = higher difficulty  
- Optional: snake body can turn hollow  

## Repository Structure  
```
├── final_snake/              # Main implementation for the snake game
├── final_snake_old/          # Legacy version or previous iterations
├── lab10_for_student/        # Supporting files / lab materials
├── mem/                       # Memory modules
├── mem_half/                  # Memory variants
├── mem_new/                   # Updated memory modules
├── pic/                       # Graphics / image assets
├── pic_half/                  # Alternative graphics
├── pic_new/                   # New graphics
├── ppm/                       # PPM image files
├── ppm_half/                  # Half-size PPM
├── ppm_new/                   # New PPMs
├── scoring code/             # Score calculation modules
├── walk.v                     # Movement / path logic module
└── README.md                  # This file
```

## Requirements / Tools  
- FPGA development environment (Vivado or equivalent)  
- Verilog / VHDL synthesis toolchain  
- Input devices: buttons and switches  
- VGA or display interface for output  

## Usage / How to Run  
1. Synthesize the design for your target FPGA board.  
2. Load (program) the FPGA with the compiled bitstream.  
3. Use the input buttons to move the snake (up/down/left/right).  
4. Use switches to set the initial snake length (5 to 9).  
5. Navigate through levels by eating all food items; avoid obstacles or walls.  
6. On win or loss, appropriate screen is displayed.  

## Future Improvements  
- Add more levels with increasing difficulty  
- Add sound or audio feedback  
- Implement smoother animations or transitions  
- Add high-score storage or replay function  

