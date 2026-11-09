module executable;

import std.stdio;
import std.file;
import details;

/*
    I'm probably going to ignore like every single one of these except for ELFF
*/
enum executable_type : uint{
    elff    = 0x00000001, //Linux ELF File
    peff    = 0x00000002, //Portable Executable Format File
    exef    = 0x00000004, //Executable file
    mchf    = 0x00000008, //Mach-o Files
};

enum endianess : uint{
    na      = 0x00000000,
    little  = 0x00000001,
    big     = 0x00000002,
};

/*
    Ill probably use a library for ARM64
*/
enum executable_architecture : uint{
    x86     = 0x00000001,
    AMD64   = 0x00000002,
    ARM64   = 0x00000004,
};

struct details{
    File origin;
    ulong origin_size;

    File[] sections;
    ulong[] section_size;

    uint file_type;

    uint endian;
    uint version_no;
    bool readable;
};

void disassemble(File file, ulong file_size){
    details exec_details = {origin: file, origin_size: file_size};

    getdata(&exec_details);

    if(exec_details.file_type == executable_type.elff){
        writeln("ELF Detected. Continue?");
        char ch;
        readf("%c",&ch);
        if(ch == 'n' || ch == 'N'){
            goto exit;
        }
    }

    exit:
    return;
}
