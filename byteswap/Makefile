cmake:
	cmake -Bbuild -H.

all: cmake
	cd build && make -j4

clean:
	rm -rf build

run: all
	cd build && make run

synth_%: cmake
	cd build && make synth_$(*F)

elaborate_%: cmake
	cd build && make elaborate_$(*F)

