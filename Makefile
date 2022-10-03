SRC := $(shell find ./src -type f -regex ".*\.zig")

all: pam_sauron

rsid:
	mkdir -p ./deps/RealSenseID/build/
	cd ./deps/RealSenseID/build && cmake .. -DRSID_SAMPLES=1 -DRSID_DEBUG_CONSOLE=OFF && make -j

pam_sauron: $(SRC)
	zig build

install: pam_sauron
	sudo install -m 755 ./zig-out/lib/security/pam_sauron.so /usr/lib/security/pam_sauron.so

clean:
	rm -rf ./zig-cache/
	rm -rf ./zig-out/
	rm -rf ./deps/RealSenseID/build/

.PHONY: $(all) clean install rsid

