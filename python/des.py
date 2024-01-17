#Helpful LInk:
# https://simewu.com/des/

from Crypto.Cipher import DES

key = '0123456789abcdef'
key = bytearray.fromhex(key)
print ('key:', key.hex())

cipher = DES.new(key, mode=DES.MODE_ECB)
plaintext = 'feedfacedeadbeef'
plaintext = bytearray.fromhex(plaintext)
print ('plaintext:', plaintext.hex())

ciphertext = cipher.encrypt(plaintext) 
print ('ciphertext:', ciphertext.hex()) 
