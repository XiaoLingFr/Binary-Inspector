import std.stdio;
import std.file;

void standard_file(File file);

void main(string[] args){
    //yo I PRAY to the heavens this is gonna work lmao
    string operation = args[1];
    if(operation == "help"){
        writeln("binsp {operation} {arg1} {arg2}");
        writeln("binsp help");
        writeln("binsp about");
        writeln("binsp read <file name> <file type>");
        writeln("File types include: document, executable");
    }
    else if(operation == "about"){
        writeln("Contributors: \nChengfu Zhao (DaRealXiaoLing)");
    }
    else if(operation == "read"){
        File file;
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
        }
        catch(FileException){
            writeln(("Could not access file: " ~ filename));
            goto exit;
        }

        if(filetype == "document"){
            standard_file(file);
        }
        else if(filetype == "executable"){
            standard_file(file);
        }
        else{
            writeln("File type not specified.");
        }

        file.close();
    }
    else{
        writeln("Operation does not exist.");
    }

    exit:
    return;
}

void standard_file(File file){
    byte[16] buffer;

    //load into buffer 16 bytes at a time
    
    
    return;
}