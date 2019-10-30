default: fast

fast: gf8.c gf16_32.c perpetual.c test_decoder.c
	gcc -O3 -o test_decoder $^

profiled: gf8.c gf16_32.c perpetual.c test_decoder.c
	gcc -no-pie -fprofile-arcs -ftest-coverage -pg -o test_decoder $^

clean:
	rm *.o test_decoder
