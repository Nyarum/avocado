
build/go/password:
	cd bindings/password; go build -o encrypt_password .; cp encrypt_password ../../bin