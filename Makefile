SRC := $(shell find ./src -type f -regex ".*\.zig")

all: pam_sauron

pam_sauron: $(SRC)
	zig build

install: pam_sauron
	sudo install -m 755 ./zig-out/lib/security/pam_sauron.so /usr/lib/security/pam_sauron.so

clean:
	rm -rf ./zig-cache/
	rm -rf ./zig-out/

.PHONY: $(all) clean install

