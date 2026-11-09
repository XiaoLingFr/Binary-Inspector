module executable;

import std.stdio;
import std.file;

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

struct details{
    File origin;
    ulong origin_size;

    File[] sections;
    ulong[] section_size;
    uint file_type;
    uint endian;
    uint version_no;
}

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

void getdata(details *exec_details){
    ubyte[] metadata;
    metadata.length = 16;
    try{
        File temp = exec_details.origin;
        
    }

    return;
}

