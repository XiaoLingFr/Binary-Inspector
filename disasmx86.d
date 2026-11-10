module disasmx86;

ubyte[] fetch(File file, ulong max_bytes){
    ubyte[] temp = new ubyte[max_bytes];
    temp.length = (file.rawRead(temp)).length;
    return temp;
}

void binary_disassemble(File file, ulong file_size){
     

    return;
}