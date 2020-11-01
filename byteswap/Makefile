all:
	cmake -Bbuild -H.
	cd build && make VERBOSE=1 -j4

clean:
	rm -rf build

run: all
	cd build && make run
