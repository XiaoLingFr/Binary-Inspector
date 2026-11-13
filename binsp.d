module binsp;

import std.stdio;
import std.file;

char[] hexchar = 
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

void print_as_hex(ubyte[] buffer, ulong seperation, ulong num);
void standard_file(File file, ulong file_size);

void main(string[] args){
    //yo I PRAY to the heavens this is gonna work lmao
    if(args.length < 2){
        writeln("No arguments given.");
        return;
    }

    string operation = args[1];
    if(operation == "help"){
        writeln("binsp {operation} {arg1} {arg2}");
        writeln("binsp help");
        writeln("binsp about");
        writeln("binsp read <file name> <file type>");
        //writeln("File types include: document, executable");
        //writeln("binsp disasm <file name> <architecture>");
        //writeln("Supported architectures: x86");
    }
    else if(operation == "about"){
        writeln("Contributors: \nChengfu Zhao (XiaolingFr)");
    }
    else if(operation == "read"){
        File file;
        ulong file_size;

        string filename;
        string filetype;
        if(args.length != 4){
            writeln("Not enough or too many arguments.");
            goto exit;
        }
        
        try{
            filetype = args[3];
            filename = getcwd() ~ "/" ~ args[2];
        }
        catch(FileException fexp){
            writeln("Cannot find current working directory.");
            goto exit;
        }
        
        if(!(exists(filename))){
            writeln(("Argument given does not exist in directory: " ~ filename));
            goto exit;
        }

        if(isDir(filename)){
            writeln("Argument given is a directory.");
            goto exit;
        }

        if(isSymlink(filename)){
            writeln("Argument given is a symbolic link.\nContinue? [y/N]");
            char ch;
            readf("%c",&ch);
            if(ch == 'n' || ch == 'N'){
                goto exit;
            }
        }

        try{
            file = File(filename, "r");
            file_size = getSize(filename);
        }
        catch(FileException FE){
            writeln(("Could not access file: " ~ filename));
            goto exit;
        }

        if(filetype == "document"){
            standard_file(file, file_size);
        }
        /*
        else if(filetype == "executable"){
            //do smth for now
            executable.disassemble(file, file_size);
        }
        */
        else{
            writeln("File type not specified.");
        }

        file.close();
    }
    /*
    else if(operation == "disasm"){
        if(args.length < 4){
            writeln("Not enough arguments given.");
        }

        if(file_type == "bin-8086"){
            disasmx8086.binary_disassemble(file, file_size);
        }
    }
    */
    else{
        writeln("Operation does not exist.");
    }
    exit:
    return;
}

/*
    My shit is so fried I cant tell the end of functions.
    YO BIG ZHAO THE MAIN FUNCTION ENDS HERE
*/

void standard_file(File file, ulong file_size){
    ubyte[32] buffer;
    ulong remainder = file_size % 32;

    ulong counter = 0;

    //load into buffer 32 bytes at a time
    try{
        for(int i = 0; i<(file_size/32); i++){
            auto num_bytes = file.rawRead(buffer);
            if(num_bytes.length == 0){
                goto conclusion;
            }
            writef  ("0x%016X", counter);
            write(" | ");
            print_as_hex(num_bytes, 8, num_bytes.length);
            write(" | ");

            char[] temp = cast(char[])num_bytes;
            for(int ch = 0; ch<temp.length; ch++){
                if(temp[ch] >= 0x20 && temp[ch] <= 0x7E){
                    write(temp[ch]);
                }
                else{
                    write("\uFFFD");
                }
            }
            writeln();
            counter = counter + 32;
        }
    }
    catch(Exception error){
        writeln("Could not load file into buffer: ", error);
        goto conclusion;
    }

    //I need to do it one more time
    try{
        auto num_bytes = file.rawRead(buffer);
        if(num_bytes.length == 0){
            goto conclusion;
        }
        writef  ("0x%016X", counter);
        write(" | ");
        print_as_hex(num_bytes, 8, num_bytes.length);
        write(" | ");

        char[] temp = cast(char[])num_bytes;
        for(int ch = 0; ch<temp.length; ch++){
            if(temp[ch] >= 0x20 && temp[ch] <= 0x7E){
                write(temp[ch]);
            }
            else{
                write("\uFFFD");
            }
        }
        writeln();
        counter = counter + num_bytes.length;
    }
    catch(Exception error){
        writeln("Could not load file into buffer: ", error);
        goto conclusion;
    }
    
    conclusion:
    return;
}

void print_as_hex(ubyte[] buffer, ulong seperation, ulong num){
    for(int i = 0; i<(num); i++){
        if(i % seperation == 0 && i!= 0){
            write("  ");
            goto cont;
        }
        if(i % 2 == 0 && i != 0){
            write(" ");
            goto cont;
        }
        cont:
        write(hexchar[((buffer[i] >> 4) & 0xF)]);
        write(hexchar[(buffer[i] & 0xF)]);
    }
    return;
}