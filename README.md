# MIPS Minesweeper

A simple 5x5 Minesweeper game implemented in MIPS assembly for educational simulators such as MARS.

## Repository Structure

```text
mips-minesweeper/
├── .gitignore
├── README.md
└── minesweeper.asm
```

## Features

- Menu with Play, Exit, and About options
- 5x5 board
- Three fixed mines
- Row and column validation from `0` to `4`
- Repeated-move detection
- Adjacent-mine counting
- Loss detection
- Victory detection after all 22 safe cells are revealed
- Full board display after a mine is selected

The fixed mine coordinates are:

```text
(0, 0)
(2, 1)
(3, 4)
```

## Running

This repository does not include a MIPS simulator.

### MARS GUI

1. Open `minesweeper.asm` in MARS.
2. Assemble the program.
3. Run it.
4. Enter integer values in the Run I/O console.

### MARS command line

If you already have a MARS JAR locally, run from this repository directory:

```text
java -jar <path-to-MARS.jar> nc minesweeper.asm
```

The exact JAR filename and path depend on the MARS installation on your machine.

## Input Notes

Menu choices and coordinates are validated when they are integers.

The program uses MIPS syscall `5` to read integers. Behavior for non-numeric console input depends on the simulator, so non-numeric text input is not handled by the program itself.

## Verification Status

The source was reviewed for:

- broken label references;
- invalid control flow;
- board indexing;
- visibility indexing;
- adjacent-mine counting;
- victory count;
- register preservation around subroutine calls;
- stack-frame alignment;
- inconsistent Portuguese identifiers and comments.

The board contains 25 cells, 3 mines, and 22 safe cells, which matches the victory condition.

No MARS or SPIM executable was provided with the source, so simulator assembly and runtime behavior still need to be verified locally.

## Suggested Commit Message

```text
fix: standardize Minesweeper logic and English naming
```
