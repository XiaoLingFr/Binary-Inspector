module viewer;

import std.stdio;
import std.file;
import std.uni;
import std.conv;
import std.string;

const FILE_ORIGIN = 0;
const SEPERATION = 2;

void interpreter(File file, string filename){
    //I lowkey want to get an BASIC kind of thingy;
    ulong file_size;
    try{
        file_size = getSize(filename);
    }
    catch(FileException FE){
        writeln("File cannot be accessed");
        return;
    }

    writeln(filename);
    write("Size: ");
    writeln(file_size);
    writeln("Compiled with: LDC | the LLVM D compiler (1.43.0)");
    writeln("OK");

    bool exit = false;
    string userinput;
    ulong current_byte = 0;
    ulong display_byte = 4;

    ubyte[] buffer = new ubyte[4096];

    while(!exit){
        stdout.flush();
        write(">> ");
        userinput = readln();
        userinput = userinput.strip();
        userinput = toLower(userinput);

        switch(userinput){
            case "quit":
                exit = true;
                break;
            case "exit":
                exit = true;
                break;
            case "set size buffer":
                write(">> ");
                try{
                    ulong size;
                    readf("%s", &size);
                    if(size <= 4096 && size >= 8){
                        buffer.length = size;
                    }
                    else{
                        writeln("Buffer cannot be below 8 bytes and cannto exceed 4096 bytes");
                    }
                }
                catch(ConvException CE){
                    writeln("Invalid input.");
                }
                break;

            case "set display bytes":
                write(">> ");
                try{
                    ulong size;
                    readf("%s", &size);
                    if(size <= 8 && size >= 1){
                        display_byte = size;
                    }
                    else{
                        writeln("Buffer cannot exceed 8 bytes or less than 1 byte");
                    }
                }
                catch(ConvException CE){
                    writeln("Invalid input.");
                }
                break;
            
            case "seek left":
                /*
                    Case 1: the size of the file is less than the buffer
                    Case 2: doing a full segment left is not possible 
                    case 3: its okay!
                */
                if(file_size < buffer.length){
                    current_byte = 0;
                }
                else if(current_byte < buffer.length - 1){
                    current_byte = 0;
                }
                else{
                    current_byte = current_byte - buffer.length;
                }
                
                file.seek(current_byte, FILE_ORIGIN);
                ulong save = current_byte;
                //loads contents
                ubyte[] read = file.rawRead(buffer);
                file.seek(save, FILE_ORIGIN);

                goto case "print";
            
            case "seek right":
                /*
                    Case 1: the size of the file is less than the buffer
                    Case 2: doing a full segment right is not possible 
                    case 3: its okay!
                */
                if(file_size < buffer.length){
                    current_byte = 0;
                }
                else if(file_size - current_byte < buffer.length){
                    current_byte = file_size - buffer.length - 1;
                }
                else{
                    current_byte = current_byte + buffer.length;
                }

                file.seek(current_byte, FILE_ORIGIN);
                ulong save = current_byte;

                //loads contents
                ubyte[] read = file.rawRead(buffer);
                file.seek(save, FILE_ORIGIN);
                goto case "print";

            case "print":
                //prints the contents in buffer
                ulong temp = current_byte;
                ubyte[] temp_buf = new ubyte[display_byte];

                ulong ptr = 0;
                bool EOB = false;
                while(!EOB){
                    //load into temp_buf
                    for(int t = 0; t<temp_buf.length && ptr < buffer.length; t++){
                        temp_buf[t] = buffer[ptr];
                        ptr++;
                    }

                    if(ptr >= buffer.length){
                        EOB = true;
                    }

                    //print address
                    writef("0x%016X", temp);
                    write(" | ");
                    writef(convertToHex(temp_buf, SEPERATION, temp_buf.length));
                    write(" | ");

                    temp = temp + temp_buf.length;
                    
                    for(int t = 0; t<temp_buf.length; t++){
                        if(temp_buf[t] >= 0x20 && temp_buf[t] <= 0x7E){
                            write(temp_buf);
                        }
                        else{
                            write("\uFFFD");
                        }
                    }

                    //clear temp_buf
                    for(int t = 0; t<temp_buf.length; t++){
                        temp_buf[t] = 0;
                    }
                    writeln();
                }

                break;
            default:
                writeln("Operation not recognized");
        }
        writeln();
    }

    exit:
        return;
}

const char[] hexchar = 
[
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F'
];
string convertToHex(ubyte[] buffer, ulong seperation, ulong num){
    string hex;
    for(int i = 0; i<(num); i++){
        if(i % seperation == 0 && i!= 0){
            hex ~= "  ";
            goto cont;
        }
        if(i % 2 == 0 && i != 0){
            hex ~= " ";
            goto cont;
        }
        cont:
        hex ~= hexchar[((buffer[i] >> 4) & 0xF)];
        hex ~= hexchar[(buffer[i] & 0xF)];
    }
    return hex;
}