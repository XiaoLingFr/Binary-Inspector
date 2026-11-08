compiler = ldc2
make:
	$(compiler) -of=binsp binsp.d 
	$(compiler) -of=binsparm binsparm.d
	rm -rf *.o
