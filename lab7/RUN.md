iverilog -g2012 -s fwd_tb -s dump -o fwd.out src/*.v provided/*.v dump.v
vvp fwd.out
gtkwave fwd.vcd