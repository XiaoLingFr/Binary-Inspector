/*
    This module is pertained to the 8086.
*/

module disasm8086;

import std.file;
import std.stdio;


/*
    These are intel instruction prefixes before
*/
enum prefix : ubyte{
    repe            = 0xF3, //NOTE: ALSO CONTAINS the following instructions: rep, repz
    repne           = 0xF2,  //NOTE: ALSO CONTAINS the following instructions: repnz
    lock            = 0xF0

    //for now I'll exclude floating points.
    //Note: if there is any code after this, its probably prefixes pertaining to the 8087 FPU coprocessor
};

/*
    Okay, I'm like genuinely tweaking about the modrm byte. From my understanding, it looks like this:

    0 0 | 0 0 0 | 0 0 0
    The first two bits (first half nibble) is the MOD
    the middle three describe registers
    the last three describe either register or memory addresses

    listen bro I'm fucking larping this bullshit is killing me
*/
enum modrm : ubyte{
    //MOD segment

    nodisplacement  = 0x00, 
    registermode    = 0xC0,
    byteaddressing  = 0x40,
    maxaddressing   = 0x80,

    //FOR REG segment ....

    //16 bit registers
    regAX           = 0x00,
    regCX           = 0x08,
    regDX           = 0x10,
    regBX           = 0x18,
    regSP           = 0x20,
    regBP           = 0x28,
    regSI           = 0x30,
    regDI           = 0x38,

    //8 bit registers
    regAL           = 0x00,
    regCL           = 0x08,
    regDL           = 0x10,
    regBL           = 0x18,
    regAH           = 0x20,
    regCH           = 0x28,
    regDH           = 0x30,
    regBH           = 0x38,

    regES           = 0x00,
    regCS           = 0x08,
    regSS           = 0x10,
    regDS           = 0x18,

    //FOR R/M segment when MOD != 0b11000000

    BXSI            = 0x00,
    BXDI            = 0x01,
    BPSI            = 0x02,
    BPDI            = 0x03,
    SIonly          = 0x04,
    DIonly          = 0x05,
    BPonly          = 0x06,
    BXonly          = 0x07,

    //useful bitmasks
    bitmask1        = 0xC0,
    bitmask2        = 0x38,
    bitmask3        = 0x07
};

/*
    I'm just happy intel put a whole new byte for prefix just for these guys or else I would crash the fuck out
    This sits in front of the opcode
    
    if these exist, then it tells the 8086 CPU to lowkey lock in and use one of these segment registers ALONGSIDE the R/M
    so mov byte [ES:DI], al probably exists lmao
*/
enum SOP : ubyte{
    SOPES           = 0x26,
    SOPCS           = 0x2E,
    SOPSS           = 0x36,
    SOPDS           = 0x3E
};

//struct for ts
struct interpreter_information{
    string  code;
    ulong   num_bytes;
};

void binary_disassemble(File file, ulong file_size){
    //fuck it we ball
    ubyte[] section_data;
    try{
        section_data = new ubyte[file_size];
        file.rawRead(section_data);
    }
    catch(FileException FE){
        writeln("unable to access file");
        goto exit;
    }

    ulong counter = 0;

    //holy fucking shit I dont know how I did it
    while(counter < file_size){
        ubyte[] temp_slice;
        try{
            temp_slice = section_data[counter .. counter + 15];
        }
        catch(ArraySliceError ASE){
            temp_slice = section_data[counter .. $];
        }

        interpreter_information* info = interpreter_information(temp_slice);

        writef("0x%04X", counter);
        write(" | ");
        for(int i = 0; i < info.num_bytes; i++){
            writef("0x%02X", section_data[counter + i]);
        }
        for(int i = 0; i < 15 - section.num_bytes; i++){
            write(" ");
            write(" ");
        }
        write(" | ")
        write(info.code);

        counter = counter + section.num_bytes;
    }

    exit:
    return;
}

interpreter_information* interpreter(ubyte[] opcodes){
    interpreter_information* temp = new interpreter_information;
    //does logic
    string instruction;
    for(int b = 0; b<opcodes.length; b++){
        
    }

    return temp;
}

// Source: http://www.mlsite.net/8086/#addr_G
