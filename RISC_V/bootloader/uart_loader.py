#!/usr/bin/env python3
"""
UART Bootloader Binary Transmitter
Transmits a compiled RISC-V binary via UART to the bootloader.

Usage:
    # Transmit to actual UART port
    python uart_loader.py <binary_file> --port COM3 --baud 115200
    
    # Or generate byte sequence files for reference
    python uart_loader.py <binary_file> -o <output_file>
"""

import argparse
import sys
import time
from pathlib import Path

try:
    import serial
    HAS_SERIAL = True
except ImportError:
    HAS_SERIAL = False


def binary_to_uart_bytes(binary_data):
    """
    Convert raw binary instruction data to UART byte sequence.
    
    UART bootloader expects little-endian 32-bit instructions assembled from bytes.
    Example: Instruction 0x12345678 is transmitted as: 0x78, 0x56, 0x34, 0x12
    
    Args:
        binary_data: Raw bytes from binary file
        
    Yields:
        Individual bytes in transmission order
    """
    # Ensure data is word-aligned (pad if necessary)
    while len(binary_data) % 4 != 0:
        binary_data += b'\x00'
    
    # Convert to little-endian bytes (bootloader assembles LSB first)
    for i in range(0, len(binary_data), 4):
        word = int.from_bytes(binary_data[i:i+4], byteorder='little')
        # Transmit as 4 individual bytes (LSB first)
        yield (word >> 0) & 0xFF    # Byte 0
        yield (word >> 8) & 0xFF    # Byte 1
        yield (word >> 16) & 0xFF   # Byte 2
        yield (word >> 24) & 0xFF   # Byte 3


def write_uart_file(bytes_sequence, output_path):
    """Write bytes as plaintext (one per line) for testbench injection."""
    with open(output_path, 'w') as f:
        for byte in bytes_sequence:
            f.write(f"{byte:02X}\n")
    print(f"✓ UART byte sequence: {output_path}")


def write_coe_file(bytes_sequence, output_path):
    """Write in Vivado COE format for readmemb simulation."""
    with open(output_path, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        bytes_list = list(bytes_sequence)
        for i, byte in enumerate(bytes_list):
            if i == len(bytes_list) - 1:
                f.write(f"{byte:02X};\n")  # Last line with semicolon
            else:
                f.write(f"{byte:02X}\n")   # Other lines with newline
    print(f"✓ COE format: {output_path}")


def write_hex_dump(bytes_sequence, output_path):
    """Write human-readable hex dump."""
    with open(output_path, 'w') as f:
        bytes_list = list(bytes_sequence)
        f.write(f"Total bytes: {len(bytes_list)}\n")
        f.write(f"Total instructions: {len(bytes_list) // 4}\n")
        f.write("\nByte sequence (UART transmission order):\n")
        
        for i, byte in enumerate(bytes_list):
            if i % 4 == 0:
                if i > 0:
                    f.write("\n")
                # Reconstruct instruction from 4 bytes
                if i + 3 < len(bytes_list):
                    instr = (bytes_list[i] | (bytes_list[i+1] << 8) | 
                            (bytes_list[i+2] << 16) | (bytes_list[i+3] << 24))
                    f.write(f"Instr[{i//4}] @ 0x{0x10000000 + i:08x}: ")
                    f.write(f"[{instr:08x}] → bytes: ")
            
            f.write(f"{byte:02X} ")
    
    print(f"✓ Hex dump: {output_path}")


def transmit_uart(binary_data, port, baud_rate=115200, verbose=False):
    """
    Transmit binary data via UART to bootloader.
    
    Args:
        binary_data: Raw bytes to transmit
        port: Serial port name (COM3, /dev/ttyUSB0, etc.)
        baud_rate: UART baud rate (default 115200)
        verbose: Print progress information
        
    Returns:
        True if successful, False otherwise
    """
    if not HAS_SERIAL:
        print("Error: pyserial not installed. Run: pip install pyserial", file=sys.stderr)
        return False
    
    try:
        # Open serial port
        ser = serial.Serial(port, baud_rate, timeout=1)
        time.sleep(0.5)  # Wait for port to stabilize
        
        if verbose:
            print(f"✓ Connected to {port} @ {baud_rate} baud")
        
        # Pad binary to word boundary
        while len(binary_data) % 4 != 0:
            binary_data += b'\x00'
        
        total_bytes = 0
        total_instructions = len(binary_data) // 4
        
        # Transmit each instruction as 4 bytes (little-endian)
        for instr_idx in range(total_instructions):
            word = int.from_bytes(binary_data[instr_idx*4:(instr_idx+1)*4], byteorder='little')
            
            # Extract and transmit bytes LSB first
            bytes_to_send = [
                (word >> 0) & 0xFF,    # Byte 0
                (word >> 8) & 0xFF,    # Byte 1
                (word >> 16) & 0xFF,   # Byte 2
                (word >> 24) & 0xFF,   # Byte 3
            ]
            
            for byte_val in bytes_to_send:
                ser.write(bytes([byte_val]))
                total_bytes += 1
                
                if verbose and total_bytes % 16 == 0:
                    print(f"  Transmitted {total_bytes} bytes ({instr_idx+1}/{total_instructions} instructions)", 
                          end='\r')
        
        # Send termination byte
        ser.write(bytes([0xFF]))
        total_bytes += 1
        
        if verbose:
            print(f"✓ Transmitted {total_bytes} bytes ({total_instructions} instructions) to {port}")
        
        ser.close()
        return True
        
    except serial.SerialException as e:
        print(f"Error: Failed to open serial port '{port}': {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Transmit RISC-V binary via UART to bootloader"
    )
    parser.add_argument("binary", help="Input binary file")
    
    # UART transmission options
    parser.add_argument("--port", "-p", 
                       help="Serial port to transmit to (e.g., COM3, /dev/ttyUSB0)")
    parser.add_argument("--baud", "-b", type=int, default=115200,
                       help="Baud rate (default: 115200)")
    parser.add_argument("-v", "--verbose", action="store_true",
                       help="Show transmission progress")
    
    # File output options (for reference/debugging)
    parser.add_argument("-o", "--output", 
                       help="Output file base name for byte sequence files")
    parser.add_argument("--coe", action="store_true", 
                       help="Also generate COE format file")
    parser.add_argument("--hex", action="store_true", 
                       help="Also generate hex dump file")
    
    args = parser.parse_args()
    
    # Read binary file
    try:
        with open(args.binary, 'rb') as f:
            binary_data = f.read()
    except FileNotFoundError:
        print(f"Error: File '{args.binary}' not found", file=sys.stderr)
        sys.exit(1)
    
    print(f"Binary size: {len(binary_data)} bytes ({len(binary_data)//4} instructions)")
    
    # Option 1: Transmit via UART
    if args.port:
        if not transmit_uart(binary_data, args.port, args.baud, args.verbose):
            sys.exit(1)
        print("✓ Transmission complete!")
        print(f"  Bootloader should now jump to 0x1000_0000 and execute program")
    
    # Option 2: Generate output files
    if args.output:
        uart_bytes = list(binary_to_uart_bytes(binary_data))
        write_uart_file(uart_bytes, f"{args.output}.uart")
        
        if args.coe:
            write_coe_file(uart_bytes, f"{args.output}.coe")
        
        if args.hex:
            write_hex_dump(uart_bytes, f"{args.output}.hex")
        
        print(f"\n✓ Byte sequence files generated with base name: {args.output}")
    
    # If neither option specified, show usage
    if not args.port and not args.output:
        print("\n⚠ No action specified:")
        print("  Use --port to transmit via UART")
        print("  Use --output to generate byte sequence files")
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
