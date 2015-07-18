BIN = interpreter compiler-x64 compiler-arm jit0 jit_x64 jit_arm

CROSS_COMPILE = arm-linux-gnueabihf-
QEMU_ARM = qemu-arm -L /usr/arm-linux-gnueabihf

all: $(BIN)

#CFLAGS = -Wall -Werror -std=gnu99 -I.
CFLAGS = -Werror -std=gnu99 -I.

interpreter: interpreter.c util.c
	$(CC) $(CFLAGS) -o $@ $^

compiler-x64: compiler-x64.c util.c stack.c
	$(CC) $(CFLAGS) -o $@ $^

compiler-arm: compiler-arm.c util.c stack.c
	$(CC) $(CFLAGS) -o $@ $^

hello: compiler-x64 compiler-arm
	./compiler-x64 progs/hello.b > hello.s
	$(CC) -o hello-x64 hello.s
	@echo 'x64: ' `./hello-x64`
	./compiler-arm progs/hello.b > hello.s
	$(CROSS_COMPILE)gcc -o hello-arm hello.s
	@echo 'arm: ' `$(QEMU_ARM) hello-arm`

jit0: jit0.c
	$(CC) $(CFLAGS) -o $@ $^

jit_arm: dynasm-driver.c jit_arm.h util.c
	$(CROSS_COMPILE)gcc $(CFLAGS) $(CPPFLAGS) -o jit_arm -DNDEBUG -DJIT=\"jit_arm.h\" \
		dynasm-driver.c util.c

jit_x64: dynasm-driver.c jit_x64.h util.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o jit_x64 -DJIT=\"jit_x64.h\" \
		dynasm-driver.c util.c

jit_arm.h: jit_arm.dasc
	        lua dynasm/dynasm.lua jit_arm.dasc > jit_arm.h

jit_x64.h: jit_x64.dasc
	        lua dynasm/dynasm.lua jit_x64.dasc > jit_x64.h

hello_arm:
	qemu-arm -L /usr/arm-linux-gnueabihf ./jit_arm progs/hello.b

mandelbrot_arm:
	qemu-arm -L /usr/arm-linux-gnueabihf ./jit_arm progs/mandelbrot.b 

arm_obj:
	arm-linux-gnueabihf-objdump -D -b binary -marm /tmp/jitcode > obj 

hello_x64:
	./jit_x64 progs/hello.b

test: test_vector test_stack
	./test_vector && ./test_stack

test_vector: tests/test_vector.c vector.c
	$(CC) $(CFLAGS) -o $@ $^
test_stack: tests/test_stack.c stack.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	$(RM) $(BIN) \
	      hello-x64 hello-arm hello.s \
	      test_vector test_stack \
	      jit_x64.h jit_arm.h
