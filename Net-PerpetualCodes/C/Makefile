default: fast

test_encoder: test_encoder.c gf8.c gf16_32.c perpetual.c
	gcc -O3 -o test_encoder $^

fast: test_decoder.c gf8.c gf16_32.c perpetual.c
	gcc -O3 -o test_decoder $^

profiled: test_decoder.c gf8.c gf16_32.c perpetual.c
	gcc -no-pie -fprofile-arcs -ftest-coverage -pg -o test_decoder $^

clean:
	rm *.o test_decoder

test_maths: test_maths.c gf16_32.c
	gcc -no-pie -fprofile-arcs -ftest-coverage -pg -o test_maths $^
