package main

import (
	"crypto/cipher"
	"crypto/des"
	"crypto/md5"
	"encoding/hex"
	"flag"
	"fmt"
	"os"
	"strings"
)

type ecb struct {
	b         cipher.Block
	blockSize int
}

func newECB(b cipher.Block) *ecb {
	return &ecb{
		b:         b,
		blockSize: b.BlockSize(),
	}
}

type ecbEncrypter ecb

func newECBEncrypter(b cipher.Block) cipher.BlockMode {
	return (*ecbEncrypter)(newECB(b))
}

func (x *ecbEncrypter) BlockSize() int {
	return x.blockSize
}

func (x *ecbEncrypter) CryptBlocks(dst, src []byte) {
	if len(src)%x.blockSize != 0 {
		panic("crypto/cipher: input not full blocks")
	}

	if len(dst) < len(src) {
		panic("crypto/cipher: output smaller than input")
	}

	for len(src) > 0 {
		x.b.Encrypt(dst, src[:x.blockSize])
		src = src[x.blockSize:]
		dst = dst[x.blockSize:]
	}
}

func EncryptPassword(key, str string) (string, error) {
	strBytes := []byte(str)

	null := make([]byte, 8-len(strBytes)%des.BlockSize)
	strBytes = append(strBytes, null...)

	block, err := des.NewTripleDESCipher([]byte(key))
	if err != nil {
		return "", err
	}

	ciphertext := make([]byte, len(strBytes))
	mode := newECBEncrypter(block)
	mode.CryptBlocks(ciphertext, strBytes)

	return string(ciphertext), nil
}

func main() {
	key := flag.String("password", "", "password in clear view")
	value := flag.String("value", "", "value for triple des ecb")
	flag.Parse()

	if key == nil || value == nil {
		fmt.Fprintf(os.Stderr, "%s", "nil key or value")
		return
	}

	md5Init := md5.Sum([]byte(*key))
	passMd5 := hex.EncodeToString(md5Init[:])

	result, err := EncryptPassword(strings.ToUpper(passMd5[:24]), *value)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s", err.Error())
		return
	}

	fmt.Fprintf(os.Stdout, "%s", result)
}
