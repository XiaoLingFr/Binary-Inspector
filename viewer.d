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
            case "help":
                writeln("set size buffer: set the amount of bytes you want to read from the file at a time | Min: 8, Max: 4096");
                writeln("set display bytes: set the number of bytes you want to display per line | Min: 1, Max: 8");
                writeln("seek left: shift the buffer backwards on the list by 1 buffer size");
                writeln("seek right: shift the buffer forward on the list by 1 buffer size");
                writeln("print: prints the buffer onto the screen");
                break;
            case "set size buffer":
                write("# buffer size: ");
                try{
                    ulong size;
                    readf("%s\n", &size);
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
                write("# display bytes: ");
                try{
                    ulong size;
                    readf("%s\n", &size);
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
            case "poke":
                ulong current_pos = current_byte;
                write("# buffer start offset: ");
                int offset;
                ubyte data;
                string temp;
                try{
                    readf("%s\n", &offset);
                }
                catch(ConvException CE){
                    writeln("Invalid input");
                    goto cont;
                }

                if( !(offset >=0 && offset <= buffer.length - 1) ){
                    writeln("negative offsets or out of bounds offsets are not allowed");
                    goto cont;
                }
                
                try{
                    readf("%s\n", temp);
                }
                catch(ConvException CE){
                    writeln("Invalid input");
                    goto cont;
                }

                if(temp.length > 2 || temp.length < 2){
                    writeln("Not enough arguments given");
                    goto cont;
                }

                if(
                    ((temp[0] >= '0' && temp[0] <= '9') || (temp[0] >= 'A' && temp[0] <= 'F')) &&
                    ((temp[1] >= '0' && temp[1] <= '9') || (temp[1] >= 'A' && temp[1] <= 'F'))
                ){
                    
                    //convert to ubyte
                    data = convertToByte(temp);
                    //move file pointer to location
                    file.seek(offset,SEEK_CUR);
                    file.rawWrite([data]);
                    file.seek(-1, SEEK_CUR);
                    file.seek(-offset,SEEK_CUR);

                    //update buffer
                    buffer[offset] = data;

                }
                else{
                    writeln("Input is not in uppercase hexadecimal for 1 byte, please try again");
                }

                cont:
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
                break;
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

ubyte convertToByte(string num){
    ubyte data = 0;
    switch(num[0]){
        case '0':
            data = 0;
            break;
        case '1':
            data = 1;
            break;
        case '2':
            data = 2;
            break;
        case '3':
            data = 3;
            break;
        case '4':
            data = 4;
            break;
        case '5':
            data = 5;
            break;
        case '6':
            data = 6;
            break;
        case '7':
            data = 7;
            break;
        case '8':
            data = 8;
            break;
        case '9':
            data = 9;
            break;
        case 'A':
            data = 10;
            break;
        case 'B':
            data = 11;
            break;
        case 'C':
            data = 12;
            break;
        case 'D':
            data = 13;
            break;
        case 'E':
            data = 14;
            break;
        case 'F':
            data = 15;
            break;
        default:
            break;
    }
    data = cast(ubyte)(data<<4);

    switch(num[1]){
        case '0':
            data = cast(ubyte)(data + 0);
            break;
        case '1':
            data = cast(ubyte)(data + 1);
            break;
        case '2':
            data = cast(ubyte)(data + 2);
            break;
        case '3':
            data = cast(ubyte)(data + 3);
            break;
        case '4':
            data = cast(ubyte)(data + 4);
            break;
        case '5':
            data = cast(ubyte)(data + 5);
            break;
        case '6':
            data = cast(ubyte)(data + 6);
            break;
        case '7':
            data = cast(ubyte)(data + 7);
            break;
        case '8':
            data = cast(ubyte)(data + 8);
            break;
        case '9':
            data = cast(ubyte)(data + 9);
            break;
        case 'A':
            data = cast(ubyte)(data + 10);
            break;
        case 'B':
            data = cast(ubyte)(data + 11);
            break;
        case 'C':
            data = cast(ubyte)(data + 12);
            break;
        case 'D':
            data = cast(ubyte)(data + 13);
            break;
        case 'E':
            data = cast(ubyte)(data + 14);
            break;
        case 'F':
            data = cast(ubyte)(data + 15);
            break;
        default:
            break;
    }
    return data;
}