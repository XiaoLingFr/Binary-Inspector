compiler = ldc2
make:
	$(compiler) -v -of=binsp binsp.d executable
	rm -rf *.o
