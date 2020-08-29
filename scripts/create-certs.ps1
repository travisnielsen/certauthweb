# Use a unique password for your certificates
$mypwd = ConvertTo-SecureString -String "dsOxs#4!6S" -Force -AsPlainText

$rootCAFriendlyName = "ca-root-contoso"
$rootCADnsName  = "ca-root-contoso.com"
$intCAFriendlyName = "ca-int-contoso"
$intCADnsName = "ca-int-contoso.com"
$webCertFriendlyName = "mTLS Demo Web Certificate"

# Set this to any specific DNS host you need
$webCertDnsName = "mtlsdemo.nielski.com"

$clientCertFriendlyName = "Contoso User"
$clientCert2FriendlyName = "Fabrikam User"

# Root Cert
$rootCert = New-SelfSignedCertificate -DnsName $rootCADnsName, $rootCADnsName -CertStoreLocation "cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(20) -FriendlyName $rootCADnsName -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature
$thumbprintRoot = $rootCert.Thumbprint
Get-ChildItem -Path cert:\localMachine\my\$thumbprintRoot | Export-PfxCertificate -FilePath "${rootCAFriendlyName}.pfx" -Password $mypwd
Export-Certificate -Cert cert:\localMachine\my\$thumbprintRoot -FilePath "${rootCAFriendlyName}.crt"

# Intermediate Cert
$parentcert = ( Get-ChildItem -Path cert:\LocalMachine\My\$thumbprintRoot )
$intermediateCert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $intCADnsName -Signer $parentcert -NotAfter (Get-Date).AddYears(20) -FriendlyName $intCAFriendlyName -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -TextExtension @("2.5.29.19={text}CA=1&pathlength=1")
$thumbprintInt = $intermediateCert.Thumbprint

Get-ChildItem -Path cert:\localMachine\my\$thumbprintInt | Export-PfxCertificate -FilePath "${intCAFriendlyName}.pfx" -Password $mypwd
Export-Certificate -Cert cert:\localMachine\my\$thumbprintInt -FilePath "${intCAFriendlyName}.crt"

# Web Cert
$parentcert = ( Get-ChildItem -Path cert:\LocalMachine\My\$thumbprintInt )
$webcert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $webCertDnsName -Signer $parentcert -NotAfter (Get-Date).AddYears(20) -FriendlyName $webCertFriendlyName
$webThumbprint = $webcert.Thumbprint
Get-ChildItem -Path cert:\localMachine\my\$webThumbprint | Export-PfxCertificate -FilePath "server.pfx" -Password $mypwd -ChainOption BuildChain
Export-Certificate -Cert cert:\localMachine\my\$webThumbprint -FilePath "${webCertDnsName}.crt"


openssl pkcs12 -in mtlsdemo-nielski-com.pfx -nocerts -out webcert.key
openssl pkcs12 -in mtlsdemo-nielski-com.pfx -clcerts -nokeys -out webcert.cer
openssl pkcs12 -export -out mtlsdemo-nielski-com-int.pfx -inkey webcert.key -in webcert.cer -certfile ca-int-contoso.cer

# Client Cert (Contoso)
$parentcert = ( Get-ChildItem -Path cert:\LocalMachine\My\$thumbprintInt )
$clientcert = New-SelfSignedCertificate -certstorelocation cert:\CurrentUser\my -dnsname $clientCertFriendlyName -Signer $parentcert -NotAfter (Get-Date).AddYears(20) -FriendlyName $clientCertFriendlyName -KeyUsageProperty All -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
$clientThumbprint = $clientcert.Thumbprint
Get-ChildItem -Path cert:\CurrentUser\my\$clientThumbprint | Export-PfxCertificate -FilePath "${clientCertFriendlyName}.pfx" -Password $mypwd
Export-Certificate -Cert cert:\Currentuser\my\$clientThumbprint -FilePath "${clientCertFriendlyName}.crt"

# Client Cert (Fabrikam) - This is self-signed for demonstrating auth deny
$clientcert2 = New-SelfSignedCertificate -certstorelocation cert:\CurrentUser\my -dnsname $clientCert2FriendlyName -NotAfter (Get-Date).AddYears(20) -FriendlyName $clientCert2FriendlyName -KeyUsageProperty All -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
$client2Thumbprint = $clientcert2.Thumbprint
Get-ChildItem -Path cert:\CurrentUser\my\$client2Thumbprint | Export-PfxCertificate -FilePath "${clientCert2FriendlyName}.pfx" -Password $mypwd
Export-Certificate -Cert cert:\Currentuser\my\$client2Thumbprint -FilePath "${clientCert2FriendlyName}.crt"
# Need to ensure self-signed client certificate is trusted
Import-Certificate -FilePath "${clientCert2FriendlyName}.crt" -CertStoreLocation Cert:\localmachine\AuthRoot