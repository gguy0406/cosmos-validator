const crypto = require('crypto');

// Example base64-encoded consensus public key
const base64ConsensusPubKey = 'W4SiCxVzOnZ220WvQRxik0qLdmk6KWMOtJG1QNZtfUA=';

// Decode the base64 public key
const pubKeyBytes = Buffer.from(base64ConsensusPubKey, 'base64');

// Hash the public key using SHA-256
const hashedPubKey = crypto.createHash('sha256').update(pubKeyBytes).digest();

// Take the first 20 bytes of the hash and convert to uppercase hexadecimal
const validatorAddress = hashedPubKey.slice(0, 20).toString('hex').toUpperCase();

console.log('Validator Address:', validatorAddress);

// Example validator address from Tendermint block signatures
const exampleValidatorAddress = '54670CE963DE9962D1A82A2E4741888E884B0BA2';

// Check if the addresses match
if (validatorAddress === exampleValidatorAddress) {
  console.log('Validator found:', validatorAddress);
} else {
  console.log('No match found');
}
