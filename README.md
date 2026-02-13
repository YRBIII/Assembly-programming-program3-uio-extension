# Program 3 — ARM Assembly Input/Conversion

## Course
Assembly Language Programming

## Overview
This program extends the `uio.s` module to handle validated numeric input and number-base conversion using **ARM assembly** and **Linux system calls**.

## Features
- Accepts only numeric characters (`0–9`)
- Re-prompts on invalid input
- Supports **1–3 digit decimal input**
- Converts decimal → binary (stored in register)
- Converts binary → decimal and prints to STDOUT
- Prevents buffer overflow by limiting input size

## Environment
- ARM Linux (Raspberry Pi or ARM VM)
- GNU assembler / linker

## Build
```bash
as -o program3.o src/program3.s
ld -o program3 program3.o
./program3
