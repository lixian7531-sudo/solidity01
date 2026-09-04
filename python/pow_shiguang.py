import hashlib
import time

PREFIX = "shiguang"


def mine(target_zeros: str):
    """Search nonce from 0 until sha256(PREFIX + str(nonce)) starts with target_zeros."""
    nonce = 0
    start = time.perf_counter()
    while True:
        message = PREFIX + str(nonce)
        digest = hashlib.sha256(message.encode("utf-8")).hexdigest()
        if digest.startswith(target_zeros):
            elapsed = time.perf_counter() - start
            print(
                "[target: {} leading zeros] nonce = {}, sha256({!r}) = {}".format(
                    len(target_zeros), nonce, message, digest
                )
            )
            print(
                "[target: {} leading zeros] elapsed = {:.6f} s ({} hashes tried)".format(
                    len(target_zeros), elapsed, nonce + 1
                )
            )
            return
        nonce += 1


if __name__ == "__main__":
    print("=== Mining for 4 leading zeros (expected ~2^16 tries) ===")
    mine("0000")
    print()
    print("=== Mining for 5 leading zeros (expected ~2^20 tries) ===")
    mine("00000")