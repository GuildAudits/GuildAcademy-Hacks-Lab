import os
from web3 import Web3
import rlp

# Parameters from the on-chain transaction
TX = {
    'chainId': int('0xa4b1', 16),
    'nonce': int('0x22a19', 16),
    'maxPriorityFeePerGas': int('0x2e90edd000', 16),
    'maxFeePerGas': int('0x2e90edd000', 16),
    'gas': int('0x1044e31', 16),
    'to': '0x75E42e6f01baf1D6022bEa862A28774a9f8a4A0C',
    'value': 0,
    'data': '0x11d9444a0000000000000000000000007d3bd50336f64b7a473c51f54e7f0bd6771cc3550000000000000000000000000000000000000000000000000000000000000005000000000000000000000000d4266f8f82f7405429ee18559e548979d49160f3',
    'accessList': []
}

# Signature values from the on-chain tx
SIG = {
    'r': int('0x2865cbbdc0e3bda645ca840d5ac1433ef44f84163b0f3f0549d8786eb12aacba', 16),
    's': int('0x35b3d53b3d9030953b9394137b09f118262ec22ada354d2dce61c6b8d673d995', 16),
    'yParity': int('0x0', 16)
}

ANVIL_RPC = os.environ.get('ANVIL_RPC', 'http://127.0.0.1:8545')

w3 = Web3(Web3.HTTPProvider(ANVIL_RPC))

if not w3.is_connected():
    print('ERROR: cannot connect to anvil at', ANVIL_RPC)
    exit(1)

# Construct the signed raw tx for EIP-1559 (type 0x2)
unsigned_tx = {
    'chainId': TX['chainId'],
    'nonce': TX['nonce'],
    'maxPriorityFeePerGas': TX['maxPriorityFeePerGas'],
    'maxFeePerGas': TX['maxFeePerGas'],
    'gas': TX['gas'],
    'to': Web3.to_checksum_address(TX['to']),
    'value': TX['value'],
    'data': bytes.fromhex(TX['data'][2:]),
    'accessList': TX['accessList']
}

# Use rlp to encode the signed tx manually
# The RLP structure for an EIP-1559 signed tx is: [chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, yParity, r, s]
# For EIP-1559 signed tx the RLP list is:
# [chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList, yParity, r, s]
to_field = bytes.fromhex(unsigned_tx['to'][2:]) if unsigned_tx['to'] else b''
access_list_rlp = []  # empty access list

rlp_signed = [
    unsigned_tx['chainId'],
    unsigned_tx['nonce'],
    unsigned_tx['maxPriorityFeePerGas'],
    unsigned_tx['maxFeePerGas'],
    unsigned_tx['gas'],
    to_field,
    unsigned_tx['value'],
    unsigned_tx['data'],
    access_list_rlp,
    SIG['yParity'],
    SIG['r'],
    SIG['s']
]

raw_payload = b'\x02' + rlp.encode(rlp_signed)

print('Raw tx length:', len(raw_payload))

tx_hash = w3.eth.send_raw_transaction(raw_payload)
print('Sent raw tx, hash:', tx_hash.hex())

receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)
print('Receipt status:', receipt.status)
print('Gas used:', receipt.gasUsed)
print(receipt)
