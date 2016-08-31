# AutoItScripts
A repository to store useful AutoIt Scripts

Secure_Screenshot
Add Hot Key to capture screenshot and encrypt it with provided RSA public key
Add Hot Key to prompt a template popup for user to paste predefined text

Secure_Viewer
A viewer to view the encrypted picture of Secure_screenshot

Unittest_Screenshot
Add Hot Key to capture screenshot and Add Hot Key to quickly change the folder of the screenshot

# Reference
Gen key pair:
>keytool -genkeypair -alias screenshot -keypass password -keysize 2048 -keyalg RSA -keystore test2.jks -validity 1460
Extract public key pem file (for secure_screenshot)
>keytool -exportcert -alias screenshot -keypass password -keystore test2.jks -storepass password -rfc -file keytool_crt.pem
>openssl x509 -inform pem -in keytool_crt.pem -pubkey -noout -out test.pem -outform PEM > public.v20160803a.pem
Extract private key as p8 keystore (for secure_viewer)
>keytool -importkeystore -srckeystore test2.jks -destkeystore intermediate.p12 -deststoretype PKCS12
>openssl pkcs12 -in intermediate.p12 -nodes -nocerts -passin pass:password | openssl rsa | openssl pkcs8 -topk8 -out private.pkcs8

The openssl command that executed in the secure_screenshot, secure_viewer:

Encrypt Session Key
>openssl rsautl -encrypt -inkey public.pem -pubin -in key.bin -out key.bin.enc
Encrypt Image File
>openssl enc -aes-256-cbc -salt -in Lighthouse.jpg -out Lighthouse.jpg.enc -pass file:./key.bin
Decrypt Session Key
>openssl rsautl -decrypt -inkey -in private.pkcs8 -out key_dec.bin -passin pass:password)
Decrypt Image File
>openssl enc -d -aes-256-cbc -in Lighthouse.jpg.enc -out Lighthouse.dec.jpg -pass file:./key_dec.bin

