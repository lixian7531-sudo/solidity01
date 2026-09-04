"""
非对称加密签名演示（教学用，无第三方依赖）

流程：
  1. PoW：找到 shiguang + nonce，使其 sha256 以 4 个 0 开头
  2. RSA：生成密钥对 -> 私钥签名 -> 公钥验证
  3. ECC(secp256k1)：生成密钥对 -> 私钥签名 -> 公钥验证
"""

import hashlib
import secrets
import time


# ---------- 1. PoW：shiguang + nonce ----------

def find_pow_message(prefix="shiguang", zeros=4):
    target = "0" * zeros
    nonce = 0
    start = time.perf_counter()
    while True:
        message = prefix + str(nonce)
        digest = hashlib.sha256(message.encode("utf-8")).hexdigest()
        if digest.startswith(target):
            elapsed = time.perf_counter() - start
            return message, digest, nonce, elapsed
        nonce += 1


def sha256_int(message):
    """把消息的 sha256 摘要转成一个大整数"""
    return int.from_bytes(
        hashlib.sha256(message.encode("utf-8")).digest(), "big"
    )


# ---------- 2. 数学工具 ----------

def egcd(a, b):
    x0, x1 = 1, 0
    y0, y1 = 0, 1
    while b:
        q = a // b
        a, b = b, a - q * b
        x0, x1 = x1, x0 - q * x1
        y0, y1 = y1, y0 - q * y1
    return a, x0, y0


def modinv(a, m):
    g, x, _ = egcd(a % m, m)
    if g != 1:
        raise ValueError("no modular inverse")
    return x % m


def miller_rabin(n, rounds=40):
    if n < 2:
        return False
    small_primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for p in small_primes:
        if n % p == 0:
            return n == p
    d = n - 1
    r = 0
    while d % 2 == 0:
        d //= 2
        r += 1
    for _ in range(rounds):
        a = secrets.randbelow(n - 3) + 2
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(r - 1):
            x = x * x % n
            if x == n - 1:
                break
        else:
            return False
    return True


def random_prime(bits):
    while True:
        candidate = secrets.randbits(bits) | (1 << (bits - 1)) | 1
        if miller_rabin(candidate):
            return candidate


# ---------- 3. RSA ----------

def rsa_generate_keypair(bits=1024):
    p = random_prime(bits // 2)
    q = random_prime(bits // 2)
    n = p * q
    phi = (p - 1) * (q - 1)
    e = 65537
    d = modinv(e, phi)
    return {
        "public_key": (e, n),
        "private_key": (d, n),
        "p": p,
        "q": q,
    }


def rsa_sign(message, private_key):
    """私钥签名：s = m^d mod n（m 是消息摘要）"""
    d, n = private_key
    m = sha256_int(message)
    return pow(m, d, n)


def rsa_verify(message, signature, public_key):
    """公钥验证：m' = s^e mod n，与消息摘要比较"""
    e, n = public_key
    m = sha256_int(message)
    return pow(signature, e, n) == m


# ---------- 4. ECC(secp256k1) ----------

P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
A = 0
B = 7
G = (
    0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
    0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8,
)
N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141


def ecc_point_add(p1, p2):
    if p1 is None:
        return p2
    if p2 is None:
        return p1
    x1, y1 = p1
    x2, y2 = p2
    if x1 == x2 and (y1 + y2) % P == 0:
        return None
    if p1 == p2:
        lam = (3 * x1 * x1 + A) * pow(2 * y1, P - 2, P) % P
    else:
        lam = (y2 - y1) * pow((x2 - x1) % P, P - 2, P) % P
    x3 = (lam * lam - x1 - x2) % P
    y3 = (lam * (x1 - x3) - y1) % P
    return (x3, y3)


def ecc_scalar_mul(k, point):
    result = None
    addend = point
    while k:
        if k & 1:
            result = ecc_point_add(result, addend)
        addend = ecc_point_add(addend, addend)
        k >>= 1
    return result


def ecc_generate_keypair():
    private_key = secrets.randbelow(N - 1) + 1
    public_key = ecc_scalar_mul(private_key, G)
    return private_key, public_key


def ecc_sign(message, private_key):
    """ECDSA 签名：返回 (r, s)"""
    z = sha256_int(message) % N
    while True:
        k = secrets.randbelow(N - 1) + 1
        x, _ = ecc_scalar_mul(k, G)
        r = x % N
        if r == 0:
            continue
        s = modinv(k, N) * (z + r * private_key) % N
        if s != 0:
            return r, s


def ecc_verify(message, signature, public_key):
    """ECDSA 验签"""
    r, s = signature
    if not (1 <= r < N and 1 <= s < N):
        return False
    z = sha256_int(message) % N
    w = modinv(s, N)
    u1 = z * w % N
    u2 = r * w % N
    point = ecc_point_add(
        ecc_scalar_mul(u1, G),
        ecc_scalar_mul(u2, public_key),
    )
    return point is not None and point[0] % N == r


# ---------- 主流程 ----------

if __name__ == "__main__":
    print("=" * 70)
    print("步骤 0：PoW，寻找 shiguang+nonce（sha256 前 4 位为 0）")
    print("=" * 70)
    message, digest, nonce, pow_elapsed = find_pow_message()
    print("符合 PoW 的消息 : {}".format(message))
    print("sha256           : {}".format(digest))
    print("PoW 耗时         : {:.4f} s".format(pow_elapsed))

    print()
    print("=" * 70)
    print("步骤 1-3：RSA（1024 位，教学演示，无 OAEP/PSS 填充）")
    print("=" * 70)
    rsa = rsa_generate_keypair()
    rsa_e, rsa_n = rsa["public_key"]
    rsa_d, _ = rsa["private_key"]
    print("公钥 e           : {}".format(rsa_e))
    print("公钥 n (hex)     : {}".format(hex(rsa_n)))
    print("私钥 d (hex)     : {}".format(hex(rsa_d)))
    print("p/q 位数         : {} bit / {} bit".format(
        rsa["p"].bit_length(), rsa["q"].bit_length()
    ))

    rsa_signature = rsa_sign(message, rsa["private_key"])
    print("\nRSA 私钥签名      : {}".format(hex(rsa_signature)))
    print("签名长度          : {} bytes".format((rsa_signature.bit_length() + 7) // 8))

    ok = rsa_verify(message, rsa_signature, rsa["public_key"])
    print("RSA 公钥验证通过  : {}".format(ok))
    tamper_ok = rsa_verify(message + "x", rsa_signature, rsa["public_key"])
    print("篡改消息后验证    : {}（应当为 False）".format(tamper_ok))

    print()
    print("=" * 70)
    print("步骤 4-6：ECC(secp256k1) ECDSA 签名")
    print("=" * 70)
    ecc_priv, ecc_pub = ecc_generate_keypair()
    print("ECC 私钥 (hex)   : {}".format(hex(ecc_priv)))
    print("ECC 公钥 x (hex) : {}".format(hex(ecc_pub[0])))
    print("ECC 公钥 y (hex) : {}".format(hex(ecc_pub[1])))

    ecc_sig = ecc_sign(message, ecc_priv)
    print("\nECC 私钥签名 (r,s)")
    print("  r              : {}".format(hex(ecc_sig[0])))
    print("  s              : {}".format(hex(ecc_sig[1])))

    ok = ecc_verify(message, ecc_sig, ecc_pub)
    print("ECC 公钥验证通过  : {}".format(ok))
    tamper_ok = ecc_verify(message + "x", ecc_sig, ecc_pub)
    print("篡改消息后验证    : {}（应当为 False）".format(tamper_ok))


    