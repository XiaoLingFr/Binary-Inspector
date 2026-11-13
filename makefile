compiler = ldc2
make:
	$(compiler) -v -of=binsp binsp.d viewer
	rm -rf *.o
