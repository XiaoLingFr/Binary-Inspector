# Binary-Inspector

This is a binary/file inspector. 

It has two primary modes:
document: dumps the ENTIRE hexdump onto the folder.
large: allows you to seek left and right

# Warning: The project is designed to be unsafe. Be very careful of what you modify with this program.

***

Examples of large mode:

example 1:

user@User-MacBook-Pro ~ % binsp read test.txt large
/Users/user/test.txt
Size: 3
Compiled with: LDC | the LLVM D compiler (1.43.0)
OK

\>> poke
\# buffer start offset: 0
48

\>> 1
Operation not recognized

\>> poke
\# buffer start offset: 1
65

\>> poke
\# buffer start offset: 2
6C

\>> poke
\# buffer start offset: 3
6C

\>> poke
\# buffer start offset: 4
6F

\>> poke
\# buffer start offset: 5
0A

\>> quit

user@Users-MacBook-Pro ~ % cat test.txt
Hello

example 2:

user@User-MacBook-Pro ~ % binsp read test.txt large
/Users/user/test.txt
Size: 20
Compiled with: LDC | the LLVM D compiler (1.43.0)
OK
\>> str insert
\# offset: 0
\# str: hi guys, this might be the GREATEST program I have written. Type shi

\>> quit

user@User-MacBook-Pro ~ % cat test.txt
hi guys, this might be the GREATEST program I have written. Type shi

Another example:

/Users/user/test2.txt
Size: 0
Compiled with: LDC | the LLVM D compiler (1.43.0)
OK
\>> str insert
\# offset: 0
\# str: Hello guys

\>> load
0x0000000000000000 | 4865  6C6C | Hell\

0x0000000000000004 | 6F20  6775 | o gu\

0x0000000000000008 | 7973  0A00 | ys��\

...
