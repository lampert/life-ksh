#!/bin/ksh
# game of life in ksh93 just for fun
# paul lampert 2020-Dec-24

set -u  # no undeclared vars

typeset -a cells1 cells0       # cell map.  Encoded &256=live cell, neighbor count &255
typeset -i ysiz xsiz
typeset -i tick=0

function initialize
{
    # get terminal size and "pixel" size for 2x2 blocks
    (( tysiz=$(tput lines)-1 ))  # terminal size
    (( txsiz=$(tput cols)-1 ))
    (( ysiz=tysiz*2 )) # board size, each terminal character is 2x2
    (( xsiz=txsiz*2 ))
    typeset -i x y
    # pad arrays with 0's all around for easy neighbor calcs
    for y in {0..$((ysiz+1))}; do
        cells0[y]=($(for x in {0..$((xsiz+1))};do echo -n "0 ";done)) 
    done
    # randomize cells
    for i in {0..$((xsiz*ysiz/5))};do
        (( x=RANDOM%xsiz ))
        (( y=RANDOM%ysiz ))
        (( (cells0[y][x] & 256) == 0 )) && update_cell cells0 $x $y 1
    done
    eval cells1=$(printf "%B" cells0)  #copy array 
}

frame_time=$SECONDS
totticktime=0.0
T_HOME=$(tput home)  # home
T_EL=$(tput el)      # clear to end of line

BL4=(\  ▘ ▝ ▀ ▖ ▌ ▞ ▛ ▗ ▚ ▐ ▜ ▄ ▙ ▟ █) 
# BL4 is array with 2x2 blocks for drawing each cell
# Each bit corresponds to following blocks:
#     +---+---+
#     | 1 | 2 |
#     +---+---+
#     | 4 | 8 |
#     +---+---+



# draw function
#
#   walk given cell array, and convert groups of 2x2 cells to correct display block ($BL4).
#   cell array encodes a live cell with 0x100 (256).  0x0F encodes neighbor count.

function draw
{
    nameref cells=$1 
    echo -n "$T_HOME"
    typeset -i y x b
    for y in {1..$ysiz..2};do
        for x in {1..$xsiz..2};do
            echo -n "${BL4[(cells[y][x]>>8)+(cells[y][x+1]>>7)+(cells[y+1][x]>>6)+(cells[y+1][x+1]>>5)]}"
        done
        echo "$T_EL"
    done
    (( tick++ ))
    (( ticktime=SECONDS-frame_time ))
    (( frame_time=SECONDS ))
    (( totticktime+=ticktime ))
    printf "tick %5d  %6.3f sec  avg %6.3f sec ${xsiz}x${ysiz}$T_EL" $tick $ticktime $((totticktime/tick))
}


# update_cell function
#
#   This updates 'liveness' of a cell, and updates neighbor counts for cells around it.

function update_cell
{
    nameref c=$1  # reference to cell array
    typeset -i x=$2 y=$3 delta=$4      # cell coordinates and change (set 1 or clear -1)
    # encode live or not (&256)
    (( c[y][x]    =c[y][x]+(delta*256) ))
    # update all neighbor counts
    (( c[y-1][x-1]=c[y-1][x-1]+delta ))
    (( c[y-1][x]  =c[y-1][x]+delta ))
    (( c[y-1][x+1]=c[y-1][x+1]+delta ))
    (( c[y][x-1]  =c[y][x-1]+delta ))
    (( c[y][x+1]  =c[y][x+1]+delta ))
    (( c[y+1][x-1]=c[y+1][x-1]+delta ))
    (( c[y+1][x]  =c[y+1][x]+delta ))
    (( c[y+1][x+1]=c[y+1][x+1]+delta ))
}

# next_gen function
#
#   calculate next generation by scanning current active cell array 
#   and updating background cell array.

#   Rules for game of life:
#     live cells with <2 or >3 live neighbors dies because of under or over population.
#     live cell with exactly 2 or 3 neighbors lives to next generation.
#     dead cells with 3 neighbors becomes live cell because of reproduction

function next_gen
{
    nameref cellssrc=$1
    nameref cellsdst=$2
    eval cellsdst=$(printf "%B" cellssrc)  #copy array
    typeset -i n x y c
    for y in {1..$ysiz}; do
        for x in {1..$xsiz};do
            (( c=cellssrc[y][x] ))
            if ((c & 256)); then # live cell
                ((n=c & 255))   # neighbor count
                if (( n<2 || n>3 )); then
                    update_cell cellsdst $x $y -1
                fi
            else #dead cell
                if ((c==3));then
                    update_cell cellsdst $x $y 1
                fi
            fi
        done
    done
}


# Main

clear
initialize  # set up initial cell array with random colony
# main loop, primary array switches from cells0 to cells1 to reduce array copies
while true;do
    if ((tick&1)); then
        next_gen cells1 cells0
        draw cells0
    else
        next_gen cells0 cells1
        draw cells1
    fi
done
