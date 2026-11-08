compiler = ldc2
make:
	$(compiler) -of=binsp main.d 
	rm -rf *.o
