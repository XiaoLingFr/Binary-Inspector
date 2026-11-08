import std.stdio;
import std.file;
void disassemble(File executable, ulong exec_size);
void main(string[] args){
    if(args.length < 2){
        writeln("Maintained by XiaoLingFr (Chengfu Zhao)");
        return;
    }

    string executable_path;
    File executable;
    ulong exec_size;
    try{
        executable_path = (getcwd()~args[1]);
    }
    catch(FileException FE){
        writeln("Cannot get current working directory");
        goto exit;
    }

    if(!(exists(executable_path))){
        writeln(("Argument given does not exist in directory: " ~ executable_path));
        goto exit;
    }

    if(isDir(executable_path)){
        writeln("Argument given is a directory.");
        goto exit;
    }

    if(isSymlink(executable_path)){
        writeln("Argument given is a symbolic link.\nContinue? [y/N]");
        char ch;
        readf("%c",&ch);
        if(ch == 'n' || ch == 'N'){
            goto exit;
        }
    }

    try{
        executable = File(executable_path, "r");
        exec_size = getSize(executable_path);
    }
    catch(FileException FE){
        writeln("No permission to open and access file.");
        goto exit;
    }

    disassemble(executable, exec_size);

    exit:
    return;
}

void disassemble(File executable, ulong exec_size){
    return;
}