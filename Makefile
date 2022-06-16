CFLAGS += -I./libgit2/include
LDFLAGS += -L./libgit2/build
LIBRARIES += -lgit2

a.out: main.c libgit2/build/libgit2.so
	gcc $(CFLAGS) main.c $(LDFLAGS) $(LIBRARIES)

libgit2/build/libgit2.so: libgit2/build
	cd libgit2/build && cmake .. && cmake --build .

libgit2/build:
	mkdir libgit2/build

.PHONY: clean
clean:
	git clean -fxd
	cd ./libgit2 && git clean -fxd
