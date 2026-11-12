/*
    This module is pertained to the 8086.
*/

module disasm8086;

import std.file;
import std.stdio;
import std.conv;

/*
    Direction of the instructions
*/
enum direction : int{
    from = 0,
    to
};


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

    //note: nodisplacement followed by BPonly results in DIRECT 16 bit addressing
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
    
    //we need two things: the entire translated string and a flag to indicate that the instruction has halted
    string instruction;
    bool SOP_found;
    ulong amount = 0;

    ulong ptr = 0;
    //we start at operand at opcodes[0] and we build a tree as such:

    //1. check for prefixes, if so, increment ptr:
    switch(opcodes[ptr]){
        //genuinely gonna get slimed out you'll have to check the next byte
        case (prefix.repe):
            ptr = ptr + 1;
            switch(opcodes[ptr]){
                //cmpsb
                case 0xA6:
                    instruction = "repe ";
                    break;
                //cmpsw
                case 0xA7:
                    instruction = "repe ";
                    break;
                //scasb
                case 0xAE:
                    instruction = "repe ";
                    break;
                //scasw
                case 0xAF:
                    instruction = "repe ";
                    break;
                //movsb, movsw, stosb, stosw, lodsb, lodsw
                //while cmpsb and the other comparions are valid for rep, they are considered shorthand and I dont like that lmao
                default:
                    instruction = "rep "
                    break;
            }
            break;
        case(prefix.repne):
            instruction = "repne ";
            ptr++;
            break;
        
        case(prefix.lock):
            instruction = "lock ";
            ptr++;
            break;
        default:
            //does not touch PTR
            break;
    }

    //check for Segment override prefix
    switch(opcodes[ptr]){
        case SOP.SOPES:
            goto case;
        case SOP.SOPCS:
            goto case;
        case SOP.SOPDS:
            goto case;
        case SOP.SOPSS:
            SOP_found = true;
            ptr++;
            break;
        default:
            //does not touch ptr
            break;
    }
    return temp;

    int modrm_byte = 0;
    int displacement = 0;
    int immediate = 0;

    int direction;
    ubyte opcode = opcodes[ptr];

    string[2] operands; //follows a strict dest, source 
    /*
        now we can finally start decoding
        every single instruction is 1 byte large
        when an instruction is given, the 8086 CPU will check for the next byte if the CPU needs it
        typically in this order:
        [prefixes] -> [instruction | 1 Byte] -> [ModR/M | 1 byte] -> [displacement | 1 or 2 Bytes] -> [Immediate -> | 1 or 2 bytes]

        So what I'm gonna do is for each instruction, im going to update thse guys lmao

        the LONGEST instruction known to man MIGHT be this instruction
        mov word [bx + si + 0xAA55], 0xA432

        note: after this I need more logic. But for now this is pretty good.
    */

    switch(opcode){
        case 0x00:
            instruction ~= "add ";
            break;
        case 0x01:
            instruction ~= "add ";
            break;
        case 0x02:
            instruction ~= "add ";
            break;
        case 0x03:
            instruction ~= "add ";
            break;
        case 0x04:
            instruction ~= "add ";
            break;
        case 0x05:
            instruction ~= "add ";
            break;
        
        case 0x06:
            instruction ~= "push es ";
            break;
        case 0x07:
            instruction ~= "pop es ";
            break;

        case 0x08:
            instruction ~= "or ";
            break;
        case 0x09:
            instruction ~= "or ";
            break;
        case 0x0A:
            instruction ~= "or ";
            break;
        case 0x0B:
            instruction ~= "or ";
            break;
        case 0x0C:
            instruction ~= "or ";
            break;
        case 0x0D:
            instruction ~= "or ";
            break;

        case 0x0E:
            instruction ~= "push cs";
            break;
        case 0x0F:
            instruction ~= "pop cs";
            break;

        case 0x10:
            instruction ~= "adc ";
            break;
        case 0x11:
            instruction ~= "adc ";
            break;
        case 0x12:
            instruction ~= "adc ";
            break;
        case 0x13:
            instruction ~= "adc ";
            break;
        case 0x14:
            instruction ~= "adc ";
            break;
        case 0x15:
            instruction ~= "adc ";
            break;

        case 0x16:
            instruction ~= "push ss";
            break;
        case 0x17:
            instruction ~= "pop ss";
            break;
        
        case 0x18:
            instruction ~= "sbb ";
            break;
        case 0x19:
            instruction ~= "sbb ";
            break;
        case 0x1A:
            instruction ~= "sbb ";
            break;
        case 0x1B:
            instruction ~= "sbb ";
            break;
        case 0x1C:
            instruction ~= "sbb ";
            break;
        case 0x1D:
            instruction ~= "sbb ";
            break;
        
        case 0x1E:
            instruction ~= "push ds";
            break;
        case 0x1F:
            instruction ~= "pop ds";
            break;

        case 0x20:
            instruction ~= "and ";
            break;
        case 0x21:
            instruction ~= "and ";
            break;
        case 0x22:
            instruction ~= "and ";
            break;
        case 0x23:
            instruction ~= "and ";
            break;
        case 0x24:
            instruction ~= "and ";
            break;
        case 0x25:
            instruction ~= "and ";
            break;
        
        case 0x26:
            break;
        case 0x27:
            instruction ~= "daa";
            break;
        
        case 0x28:
            instruction ~= "sub ";
            break;
        case 0x29:
            instruction ~= "sub ";
            break;
        case 0x2A:
            instruction ~= "sub ";
            break;
        case 0x2B:
            instruction ~= "sub ";
            break;
        case 0x2C:
            instruction ~= "sub ";
            break;
        case 0x2D:
            instruction ~= "sub ";
            break;

        case 0x2E:
            break;
        case 0x2F:
            instruction ~= "das";
            break;

        case 0x30:
            instruction ~= "xor";
            break;
        case 0x31:
            instruction ~= "xor ";
            break;
        case 0x32:
            instruction ~= "xor ";
            break;
        case 0x33:
            instruction ~= "xor ";
            break;
        case 0x34:
            instruction ~= "xor ";
            break;
        case 0x35:
            instruction ~= "xor ";
            break;

        case 0x36:
            break;
        case 0x37:
            instruction ~= "aaa";
            break;

        case 0x38:
            instruction ~= "cmp ";
            break;
        case 0x39:
            instruction ~= "cmp ";
            break;
        case 0x3A:
            instruction ~= "cmp ";
            break;
        case 0x3B:
            instruction ~= "cmp ";
            break;
        case 0x3C:
            instruction ~= "cmp ";
            break;
        case 0x3D:
            instruction ~= "cmp ";
            break;

        case 0x3E:
            break;
        case 0x3F:
            instruction ~= "aas";
            break;

        case 0x40:
            instruction ~= "inc ax";
            break;
        case 0x41:
            instruction ~= "inc cx";
            break;
        case 0x42:
            instruction ~= "inc dx";
            break;
        case 0x43:
            instruction ~= "inc bx";
            break;
        case 0x44:
            instruction ~= "inc sp";
            break;
        case 0x45:
            instruction ~= "inc bp";
            break;
        case 0x46:
            instruction ~= "inc si";
            break;
        case 0x47:
            instruction ~= "inc di";
            break;

        case 0x48:
            instruction ~= "dec ax";
            break;
        case 0x49:
            instruction ~= "dec cx";
            break;
        case 0x4A:
            instruction ~= "dec dx";
            break;
        case 0x4B:
            instruction ~= "dec bx";
            break;
        case 0x4C:
            instruction ~= "dec sp";
            break;
        case 0x4D:
            instruction ~= "dec bp";
            break;
        case 0x4E:
            instruction ~= "dec si";
            break;
        case 0x4F:
            instruction ~= "dec di";
            break;
        
        case 0x50:
            instruction ~= "push ax";
            break;
        case 0x51:
            instruction ~= "push cx";
            break;
        case 0x52:
            instruction ~= "push dx";
            break;
        case 0x53:
            instruction ~= "push bx";
            break;
        case 0x54:
            instruction ~= "push sp";
            break;
        case 0x55:
            instruction ~= "push bp";
            break;
        case 0x56:
            instruction ~= "push si";
            break;
        case 0x57:
            instruction ~= "push di";
            break;

        case 0x58:
            instruction ~= "pop ax";
            break;
        case 0x59:
            instruction ~= "pop cx";
            break;
        case 0x5A:
            instruction ~= "pop dx";
            break;
        case 0x5B:
            instruction ~= "pop bx";
            break;
        case 0x5C:
            instruction ~= "pop sp";
            break;
        case 0x5D:
            instruction ~= "pop bp";
            break;
        case 0x5E:
            instruction ~= "pop si";
            break;
        case 0x5F:
            instruction ~= "pop di";
            break;
    
        //thank the intel engineers that 0x60 ~ 0x6F is invalid lmao

        case 0x70:
            instruction ~= "jo ";
            break;
        case 0x71:
            instruction ~= "jno ";
            break;
        case 0x72:
            instruction ~= "jb ";
            break;
        case 0x73:
            instruction ~= "jnb ";
            break;
        case 0x74:
            instruction ~= "jz ";
            break;
        case 0x75:
            instruction ~= "jnz ";
            break;
        case 0x76:
            instruction ~= "jbe ";
            break;
        case 0x77:
            instruction ~= "ja ";
            break;

        case 0x78:
            instruction ~= "js ";
            break;
        case 0x79:
            instruction ~= "jns ";
            break;
        case 0x7A:
            instruction ~= "jpe ";
            break;
        case 0x7B:
            instruction ~= "jpo ";
            break;
        case 0x7C:
            instruction ~= "jl ";
            break;
        case 0x7D:
            instruction ~= "jge ";
            break;
        case 0x7E:
            instruction ~= "jle ";
            break;
        case 0x7F:
            instruction ~= "jg ";
            break;

        //all the pain and suffering from dealing with 0x60 has been transfered to 0x80
        case 0x80:
            break;
        case 0x81:
            break;
        case 0x82:
            break;
        case 0x83:
            break;

        case 0x84:
            instruction ~= "test ";
            break;
        case 0x85:
            instruction ~= "test ";
            break;

        case 0x86:
            instruction ~= "xchg ";
            break;
        case 0x87:
            instruction ~= "xchg ";
            break;

        case 0x88:
            instruction ~= "mov ";
            break;
        case 0x89:
            instruction ~= "mov ";
            break;
        case 0x8A:
            instruction ~= "mov ";
            break;
        case 0x8B:
            instruction ~= "mov ";
            break;
        case 0x8C:
            instruction ~= "mov ";
            break;

        case 0x8D:
            instruction ~= "lea ";
            break;

        case 0x8E:
            instruction ~= "mov ";
            break;
        case 0x8F:
            instruction ~= "pop ";
            break;
        
        //0x90~0x9F is genuinely like the reward after witnessing the WORST design decision of ALL time
        case 0x90:
            instruction ~= "nop";
            break;
        
        case 0x91:
            instruction ~= "xchg CX, AX";
            break;
        case 0x92:
            instruction ~= "xchg DX, AX";
            break;
        case 0x93:
            instruction ~= "xchg BX, AX";
            break;
        case 0x94:
            instruction ~= "xchg SP, AX";
            break;
        case 0x95:
            instruction ~= "xchg BP, AX";
            break;
        case 0x96:
            instruction ~= "xchg SI, AX";
            break;
        case 0x97:
            instruction ~= "xchg DI, AX";
            break;

        case 0x98:
            instruction ~= "cbw";
            break
        case 0x99:
            instruction ~= "cwd";
            break;
        
        case 0x9A:
            instruction ~= "call ";
            break;

        case 0x9B:
            instruction ~= "wait";
            break;
        case 0x9C:
            instruction ~= "pushf";
            break;
        case 0x9D:
            instruction ~= "popf";
            break;
        case 0x9E:
            instruction ~= "sahf";
            break;
        case 0x9F:
            instruction ~= "LAHF";
            break;
    
        case 0xA0:
            instruction ~= "mov al, ";
            break;
        case 0xA1:
            instruction ~= "mov ax, ";
            break;
        //in this case, we're gonna just fetch the next byte instead to simplify the model
        case 0xA2:
            instruction ~= "mov [0x";
            instruction ~= [opcodes[ptr + 1]].toHexString(); //here: https://forum.dlang.org/thread/ghwlquntplrpzojoptuy@forum.dlang.org
            instruction ~= "], al";
            break;
        case 0xA3:
            instruction ~= "mov [0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString(); //here: https://forum.dlang.org/thread/ghwlquntplrpzojoptuy@forum.dlang.org
            instruction ~= "], ax";
            break;
        
        case 0xA4:
            instruction ~= "movsb";
            break;
        case 0xA5:
            instruction ~= "movsw";
            break;
        case 0xA6:
            instruction ~= "cmpsb";
            break;
        case 0xA7:
            instruction ~= "cmpsw";
            break;

        case 0xA8:
            instruction ~= "test al, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xA9:
            instruction ~= "test al, 0x";
            instruction ~= [opcodes[ptr+1],opcodes[ptr+2]].toHexString();
            break;
    
        case 0xAA:
            instruction ~= "stosb";
            break;
        case 0xAB:
            instruction ~= "stosw";
            break;
        case 0xAC:
            instruction ~= "lodsb";
            break;
        case 0xAD:
            instruction ~= "lodsw";
            break;
        case 0xAE:
            instruction ~= "scasb";
            break;
        case 0xAF:
            instruction ~= "scansw";
            break;
        
        //another GOATED instruction level. I love 0xB0~0xBF
        case 0xB0:
            instruction ~= "mov al, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB1:
            instruction ~= "mov cl, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB2:
            instruction ~= "mov dl, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB3:
            instruction ~= "mov bl, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB4:
            instruction ~= "mov ah, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB5:
            instruction ~= "mov ch, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB6:
            instruction ~= "mov dh, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xB7:
            instruction ~= "mov bh, 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        
        case 0xB8:
            instruction ~= "mov ax, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xB9:
            instruction ~= "mov cx, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xBA:
            instruction ~= "mov dx, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xBB:
            instruction ~= "mov bx, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xBC:
            instruction ~= "mov sp, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xBD:
            instruction ~= "mov bp, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xBE:
            instruction ~= "mov si, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xBF:
            instruction ~= "mov di, 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;

        //undocumented??
        case 0xC0:
            break;
        case 0xC1:
            break;

        case 0xC2:
            instruction ~= "ret ";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xC3:
            instruction ~= "ret";
            break;
        
        case 0xC4:
            instruction ~= "les";
            break;
        case 0xC5:
            instruction ~= "lds";
            break;
        case 0xC6:
            instruction ~= "mov ";
            break;
        case 0xC7:
            instruction ~= "mov ";

        case 0xCA:
            instruction ~= "retf 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xCB:
            instruction ~= "retf";
            break;
        
        case 0xCC:
            instruction ~= "int 3";
            break;

        case 0xCD:
            instruction ~= "int 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;

        case 0xCE:
            instruction ~= "intO";
            break;
        case 0xCF:
            instruction ~= "iret";
            break;
        
        //GRP 2, Byte argument
        case 0xD0:
            break;
        //GRP 2, word argument
        case 0xD1:
            break;

        //GRP 2, CL argument
        case 0xD2:
            break;
        //GRP 2, CL argument, somehow with a word argument?
        case 0xD3:
            break;

        case 0xD4:
            instruction ~= "aam 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;

        case 0xD5:
            instruction ~= "aad 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        
        case 0xD6:
            break;
        
        case 0xD7:
            instruction ~= "xlat";
            break;
        
        //invalid opcodes
        case 0xD8:
            break;
        case 0xD9:
            break;
        case 0xDA:
            break;
        case 0xDB:
            break;
        case 0xDC:
            break;
        case 0xDD:
            break;
        case 0xDE:
            break;
        case 0xDF:
            break;
        
        case 0xE0:
            instruction ~= "loopnz $ + 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xE1:
            instruction ~= "loopz $ + 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xE2:
            instruction ~= "loop $ + 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xE3:
            instruction ~= "jcxz $ + 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        
        case 0xE4:
            instruction ~= "in al, 0x"
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xE5:
            instruction ~= "in ax, 0x"
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        case 0xE6:
            instruction ~= "out 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            instruction ~= ", al";
            break;
        case 0xE7:
            instruction ~= "out 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            instruction ~= ", ax";
            break;
        
        case 0xE8:
            instruction ~= "call $ + 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xE9:
            instruction ~= "jmp $ + 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xEA:
            instruction ~= "jmp 0x";
            instruction ~= [opcodes[ptr+2], opcodes[ptr+1]].toHexString();
            break;
        case 0xEB:
            instruction ~= "jmp 0x";
            instruction ~= [opcodes[ptr+1]].toHexString();
            break;
        
        case 0xEC:
            instruction ~= "in al, dx";
            break;
        case 0xED:
            instruction ~= "in ax, dx";
            break;
        case 0xEE:
            instruction ~= "out dx, al";
            break;
        case 0xEF:
            instruction ~= "out dx, ax";
            break;
        
        case 0xF0:
            break;
        
        case 0xF1:
            break;
        
        case 0xF2:
            break;
        case 0xF3:
            break;
        case 0xF4:
            instruction ~= "hlt";
            break;
        case 0xF5:
            instruction ~= "cmc";
            break;
        //GRP 3A
        case 0xF6:
            break;
        //GRP 3B
        case 0xF7:
            break;
        
        case 0xF8:
            instruction ~= "CLC";
            break;
        case 0xF9:
            instruction ~= "STC";
            break;
        case 0xFA:
            instruction ~= "CLI";
            break;
        case 0xFB:
            instruction ~= "STI";
            break;
        case 0xFC:
            instruction ~= "CLD";
            break;
        case 0xFD:
            instruction ~= "STD";
            break;
        
        //GRP 4A
        case 0xFE:
            break;
        //GRP 4B
        case 0xFF:
            break;      
        default:
            instruction ~= "illegal instruction";
            break;  
    }     
    
    ptr++;
}

// Source: http://www.mlsite.net/8086/#addr_G
