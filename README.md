# ENGR 599 Lab 1: Hardware Trojans
Adapted from Swarup Bhunia at the University of Florida.

**Due: 11:59 PM, Friday Feb 7, 2025**

## Overview
We describe an experiment on hardware Trojan attacks, in the form of malicious modifications of electronic hardware, that post major security concerns in the electronics industry.

## Getting Started
Log onto a Linux machine in IF4111 or IF3111 and type the following into the command line:

```
$ git clone https://github.com/ENGR599/P1_Hardware_Trojan.git
$ cd P1_Hardware_Trojan
$ make
$ vivado vivado/vivado.xpr
```

The provided starter code implements a Data Encryption Standard (DES) and Universal Asynchronous Receiver/Transmitter (UART) interface in hardware. A rough block diagram is shown in the figure below.

*** TODO: Add image ***

### Programming the Basys3 Board
Please refer to the [ENGR 210 documentation](https://engr210.github.io/projects/vivado_tutorial) to generate the bitstream + program the Basys3 board.

### Connecting with UART
You should now be able to connect via UART with your Basys3 board, and use it to encrypt some data:
```
$ cd Python
$ python3 des_hw.py

key: 0123456789abcdef
plaintext: feedfacedeadbeef
ciphertext: 167c4586e73882e6
sw_ciphertext: 167c4586e73882e6
@@@Passed
```

## Assignment Description
Your task is to add two hardware Trojans to the reference design. These trojans are activated by using the Basys3 switches. 

### Combinational Trojan
First, insert a combinational Trojan as described below into your system DES. This trojan should be activated only when `sw[0]` is `1`.

The trigger condition of the Trojan is when the least significant 4 bits of the 'L' value are `4'b0110`, i.e. `L[28:32] == 'b0110`.

**When the Trojan is triggered,** the least significant bit (LSB) of the key for the DES is inverted. One way to do that is shown below. Declare a new *Trojan* register, and concatenate it with the remainder of the "key" vector. Your circuit will control the value of Trojan.

```
// Select a subkey from key.
key_sel u1 (
    .K_sub(K_sub),
    .K({key[55:1], trojan}), // <- New register Trojan acting in place of LSB of key
    .roundSel(roundSel),
    .decrypt(decrypt)
);
```

**As soon as the trigger condition is not true**, the key becomes the original key.

### Sequential Trojan
Next, insert a sequential Trojan into the DES. This trojan should be activated only when `sw[1]` is 1. 

The trigger condition of the Trojan is when the least significant 2 bits of output "P" of the Feistal Function output go through the sequence `2'b01`, `2'b10`, and `2'b11` over consecutive clock cycles. After the Trojan is triggered, the LSB of the key for the DES will always be inverted.

The Feistal function is responsible for both the substitution and premutations of each round of DES.

*** TODO: Add image ***

In the DES module provided, the Feistal function is found in the `des_o` module as a `crp` submodule instantiated as `u0`. In this verilog, the P output is assigned to a signal called `out` so your Trojan needs to trigger off of the `out` signal. 

```
module des_o(desOut, desIn, key, decrypt, roundSel, clk, clk_in);
    output  [63:0] desOut;
    input   [63:0] desIn;
    input   [55:0] key;
    input          decrypt;
    input   [3:0]  roundSel;
    input          clk;
    input          clk_in;

    wire [1:48] K_sub;
    wire [1:64] IP, FP;
    reg [1:32] L, R;
    wire [1:32] Xin;
    wire [1:32] Lout, Rout;
    wire [1:32] out;

    reg trojan;

    assign Lout = (roundSel == 0) ? IP[33:64] : R;
    assign Xin = (roundSel == 0) ? IP[01:32] : L;
    assign Rout = Xin ^ out;
    assign FP = {Rout, Lout};

    // Fiestal Function
    crp u0(.P(out), .R(Lout), .K_sub(K_sub));
```

For your sequential Trojan to work properly it is important that you set up a proper state machine - do not cut corners.

## Input Pattern Search
Now that you have implemented your Trojans, you need to find 20 64-bit plaintext inputs that will trigger the combinational Trojan and 2 64-bit plaintext words that trigger the sequential Trojan. We suggest implementing a Python program that randomly generates input plaintexts, computes the software DES ciphertext and compares it to the hardware DES ciphertext.

## What to turn in
Please upload a zipped folder to Canvas containing the following:
- Your modified `DES.v` source code.
- Your Python input search source code
- A 1-2 page report detailing the following:
    - What you changed in `DES.v`
    - What inputs your input pattern search program found that triggered each of the Trojans.
    - How long did search program take to run?

Each group should submit to Canvas. Once one member of the group has submitted, it should appear as submitted for everyone.