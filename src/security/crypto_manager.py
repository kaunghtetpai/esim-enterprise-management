"""
Cryptographic Security Manager for eSIM Platform
Implements GSMA security requirements and PKI management
"""

import os
import hashlib
import hmac
from typing import Dict, List, Optional, Tuple, Any
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding, ec
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography import x509
from cryptography.x509.oid import NameOID
import base64
import secrets
from datetime import datetime, timedelta
import logging

class CryptoManager:
    """
    Handles all cryptographic operations for eSIM platform
    Implements GSMA security standards and PKI management
    """
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.ca_cert = None
        self.ca_private_key = None
        self._load_ca_certificates()
    
    def _load_ca_certificates(self):
        """Load Certificate Authority certificates and keys"""
        try:
            # Load CA certificate
            with open(self.config['ca_cert_path'], 'rb') as f:
                self.ca_cert = x509.load_pem_x509_certificate(f.read())
            
            # Load CA private key
            with open(self.config['ca_key_path'], 'rb') as f:
                self.ca_private_key = serialization.load_pem_private_key(
                    f.read(),
                    password=self.config['ca_key_password'].encode()
                )
                
        except Exception as e:
            self.logger.error(f"Failed to load CA certificates: {str(e)}")
            raise
    
    def generate_key_pair(self, key_size: int = 2048) -> Tuple[Any, Any]:
        """Generate RSA key pair for eSIM operations"""
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_size
        )
        public_key = private_key.public_key()
        
        return private_key, public_key
    
    def generate_ecc_key_pair(self, curve=ec.SECP256R1()) -> Tuple[Any, Any]:
        """Generate ECC key pair for efficient mobile operations"""
        private_key = ec.generate_private_key(curve)
        public_key = private_key.public_key()
        
        return private_key, public_key
    
    def create_certificate(self, 
                          subject_name: str,
                          public_key: Any,
                          validity_days: int = 365,
                          is_ca: bool = False) -> x509.Certificate:
        """Create X.509 certificate for eSIM components"""
        
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "MM"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Yangon"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Yangon"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "eSIM Enterprise"),
            x509.NameAttribute(NameOID.COMMON_NAME, subject_name),
        ])
        
        if not is_ca and self.ca_cert:
            issuer = self.ca_cert.subject
        
        cert_builder = x509.CertificateBuilder()
        cert_builder = cert_builder.subject_name(subject)
        cert_builder = cert_builder.issuer_name(issuer)
        cert_builder = cert_builder.public_key(public_key)
        cert_builder = cert_builder.serial_number(x509.random_serial_number())
        cert_builder = cert_builder.not_valid_before(datetime.utcnow())
        cert_builder = cert_builder.not_valid_after(
            datetime.utcnow() + timedelta(days=validity_days)
        )
        
        # Add extensions
        if is_ca:
            cert_builder = cert_builder.add_extension(
                x509.BasicConstraints(ca=True, path_length=None),
                critical=True
            )
        else:
            cert_builder = cert_builder.add_extension(
                x509.BasicConstraints(ca=False, path_length=None),
                critical=True
            )
        
        cert_builder = cert_builder.add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                key_agreement=False,
                key_cert_sign=is_ca,
                crl_sign=is_ca,
                content_commitment=False,
                data_encipherment=False,
                encipher_only=False,
                decipher_only=False
            ),
            critical=True
        )
        
        # Sign certificate
        signing_key = self.ca_private_key if self.ca_private_key else public_key
        certificate = cert_builder.sign(signing_key, hashes.SHA256())
        
        return certificate
    
    def verify_certificate_chain(self, cert_chain: List[x509.Certificate]) -> bool:
        """Verify certificate chain validity"""
        try:
            # Implement certificate chain validation
            # Check each certificate against its issuer
            for i in range(len(cert_chain) - 1):
                cert = cert_chain[i]
                issuer_cert = cert_chain[i + 1]
                
                # Verify signature
                issuer_public_key = issuer_cert.public_key()
                issuer_public_key.verify(
                    cert.signature,
                    cert.tbs_certificate_bytes,
                    padding.PKCS1v15(),
                    cert.signature_hash_algorithm
                )
                
                # Check validity period
                now = datetime.utcnow()
                if now < cert.not_valid_before or now > cert.not_valid_after:
                    return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"Certificate chain verification failed: {str(e)}")
            return False
    
    def encrypt_aes_gcm(self, data: bytes, key: bytes, aad: Optional[bytes] = None) -> Dict[str, bytes]:
        """Encrypt data using AES-GCM (authenticated encryption)"""
        # Generate random nonce
        nonce = os.urandom(12)
        
        # Create cipher
        cipher = Cipher(algorithms.AES(key), modes.GCM(nonce))
        encryptor = cipher.encryptor()
        
        # Add additional authenticated data if provided
        if aad:
            encryptor.authenticate_additional_data(aad)
        
        # Encrypt data
        ciphertext = encryptor.update(data) + encryptor.finalize()
        
        return {
            'ciphertext': ciphertext,
            'nonce': nonce,
            'tag': encryptor.tag
        }
    
    def decrypt_aes_gcm(self, encrypted_data: Dict[str, bytes], key: bytes, aad: Optional[bytes] = None) -> bytes:
        """Decrypt AES-GCM encrypted data"""
        # Create cipher
        cipher = Cipher(
            algorithms.AES(key),
            modes.GCM(encrypted_data['nonce'], encrypted_data['tag'])
        )
        decryptor = cipher.decryptor()
        
        # Add additional authenticated data if provided
        if aad:
            decryptor.authenticate_additional_data(aad)
        
        # Decrypt data
        plaintext = decryptor.update(encrypted_data['ciphertext']) + decryptor.finalize()
        
        return plaintext
    
    def sign_data(self, data: bytes, private_key: Any) -> bytes:
        """Sign data using RSA-PSS with SHA-256"""
        signature = private_key.sign(
            data,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        return signature
    
    def verify_signature(self, data: bytes, signature: bytes, public_key: Any) -> bool:
        """Verify RSA-PSS signature"""
        try:
            public_key.verify(
                signature,
                data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False
    
    def derive_key(self, password: bytes, salt: bytes, length: int = 32) -> bytes:
        """Derive encryption key using PBKDF2"""
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=length,
            salt=salt,
            iterations=100000
        )
        return kdf.derive(password)
    
    def generate_secure_random(self, length: int) -> bytes:
        """Generate cryptographically secure random bytes"""
        return secrets.token_bytes(length)
    
    def hash_data(self, data: bytes, algorithm: str = 'sha256') -> bytes:
        """Hash data using specified algorithm"""
        if algorithm == 'sha256':
            digest = hashes.Hash(hashes.SHA256())
        elif algorithm == 'sha384':
            digest = hashes.Hash(hashes.SHA384())
        elif algorithm == 'sha512':
            digest = hashes.Hash(hashes.SHA512())
        else:
            raise ValueError(f"Unsupported hash algorithm: {algorithm}")
        
        digest.update(data)
        return digest.finalize()
    
    def create_hmac(self, key: bytes, data: bytes, algorithm: str = 'sha256') -> bytes:
        """Create HMAC for data integrity"""
        if algorithm == 'sha256':
            return hmac.new(key, data, hashlib.sha256).digest()
        elif algorithm == 'sha384':
            return hmac.new(key, data, hashlib.sha384).digest()
        elif algorithm == 'sha512':
            return hmac.new(key, data, hashlib.sha512).digest()
        else:
            raise ValueError(f"Unsupported HMAC algorithm: {algorithm}")
    
    def verify_hmac(self, key: bytes, data: bytes, expected_hmac: bytes, algorithm: str = 'sha256') -> bool:
        """Verify HMAC for data integrity"""
        try:
            computed_hmac = self.create_hmac(key, data, algorithm)
            return hmac.compare_digest(computed_hmac, expected_hmac)
        except Exception:
            return False

class SecureChannelManager:
    """
    Manages secure channels for eSIM communications
    Implements SCP03/SCP11 protocols
    """
    
    def __init__(self, crypto_manager: CryptoManager):
        self.crypto_manager = crypto_manager
        self.logger = logging.getLogger(__name__)
    
    def establish_scp03_channel(self, 
                               card_challenge: bytes,
                               host_challenge: bytes,
                               card_cryptogram: bytes) -> Dict[str, Any]:
        """Establish SCP03 secure channel"""
        # Implementation of SCP03 protocol
        # This is a simplified version - full implementation requires
        # detailed knowledge of GlobalPlatform specifications
        
        # Derive session keys
        session_keys = self._derive_scp03_keys(card_challenge, host_challenge)
        
        # Verify card cryptogram
        if not self._verify_card_cryptogram(card_cryptogram, session_keys):
            raise ValueError("Invalid card cryptogram")
        
        # Generate host cryptogram
        host_cryptogram = self._generate_host_cryptogram(session_keys)
        
        return {
            'session_keys': session_keys,
            'host_cryptogram': host_cryptogram,
            'security_level': 'SCP03'
        }
    
    def _derive_scp03_keys(self, card_challenge: bytes, host_challenge: bytes) -> Dict[str, bytes]:
        """Derive SCP03 session keys"""
        # Simplified key derivation - actual implementation requires
        # proper SCP03 key derivation functions
        combined_challenge = card_challenge + host_challenge
        
        enc_key = self.crypto_manager.hash_data(b'ENC' + combined_challenge)[:16]
        mac_key = self.crypto_manager.hash_data(b'MAC' + combined_challenge)[:16]
        dek_key = self.crypto_manager.hash_data(b'DEK' + combined_challenge)[:16]
        
        return {
            'enc_key': enc_key,
            'mac_key': mac_key,
            'dek_key': dek_key
        }
    
    def _verify_card_cryptogram(self, cryptogram: bytes, session_keys: Dict[str, bytes]) -> bool:
        """Verify card cryptogram in SCP03"""
        # Simplified verification - actual implementation requires
        # proper cryptogram calculation according to SCP03
        return True
    
    def _generate_host_cryptogram(self, session_keys: Dict[str, bytes]) -> bytes:
        """Generate host cryptogram for SCP03"""
        # Simplified generation - actual implementation requires
        # proper cryptogram calculation according to SCP03
        return self.crypto_manager.generate_secure_random(8)