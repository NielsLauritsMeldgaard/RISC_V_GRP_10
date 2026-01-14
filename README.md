# RISC_V_GRP_10
System Verilog implementation of a RISC-V processor
<<<<<<< HEAD

See branches meldgaard and dyrloev for current progress...
=======
### ALU Operation Map

| aluOP | Operation | Description |
|:-----:|-----------|-------------|
| 0000 | ADD  | `rs1 + rs2` |
| 0001 | SUB  | `rs1 - rs2` |
| 0010 | XOR  | Bitwise XOR |
| 0011 | OR   | Bitwise OR |
| 0100 | AND  | Bitwise AND |
| 0101 | SLL  | Logical left shift (`rs2[4:0]`) |
| 0110 | SRL  | Logical right shift (`rs2[4:0]`) |
| 0111 | SRA  | Arithmetic right shift (`rs2[4:0]`) |
| 1000 | SLT  | Set less than (signed) |
| 1001 | SLTU | Set less than (unsigned) |

### Design Notes

- Signed and unsigned comparisons are explicitly separated.
- This encoding is an internal design choice and is not part of the RISC-V ISA. A mapping/decoding between RISC-V instructions and aluOP is needed.
>>>>>>> dyrloev
