compiler = ldc2
make:
	$(compiler) -v -of=binsp binsp.d 
	rm -rf *.o
