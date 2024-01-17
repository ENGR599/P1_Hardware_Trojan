#Helpful LInk:
# https://simewu.com/des/

from Crypto.Cipher import DES
import serial

key = '0123456789abcdef'
key = bytearray.fromhex(key)
print ('key:', key.hex())

plaintext = 'feedfacedeadbeef'
plaintext = bytearray.fromhex(plaintext)
print ('plaintext:', plaintext.hex())

ser = serial.Serial("/dev/ttyUSB3", 115200)

ser.write(plaintext)

ciphertext = ser.read(8)
print ('ciphertext:', ciphertext.hex()) 

cipher = DES.new(key, mode=DES.MODE_ECB)
sw_ciphertext = cipher.encrypt(plaintext) 
print ('sw_ciphertext:', sw_ciphertext.hex()) 

assert(ciphertext == sw_ciphertext)
print ("@@@Passed")
