const crypto = require('node:crypto');
const http = require('node:http');
const https = require('node:https');
const WebSocket = require('ws');

const webhookToken = process.argv[2];
const hostname = process.argv[3];
const valAddress = process.argv[4];
const maxValidators = process.argv[5];

function sendMessageToDiscord(message) {
  const req = https.request({
    headers: { 'Content-Type': 'application/json' },
    hostname: 'discord.com',
    path: `/api/webhooks/${webhookToken}`,
    method: 'POST',
  });

  req.write(JSON.stringify({ username: hostname, content: message }));
  req.on('error', (e) => console.error(`Send message error ${error.message}`));
  req.end();
}

function queryFactory(id, query) {
  return JSON.stringify({ jsonrpc: '2.0', method: 'subscribe', id, params: { query } });
}

function getValidatorSet() {
  return new Promise((resolve) => {
    http.get(
      `http://0.0.0.0:1317/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED&pagination.limit=${maxValidators}`,
      (res) => {
        res.setEncoding('utf8');

        let rawData = '';

        res.on('data', (chunk) => (rawData += chunk));
        res.on('end', () => {
          const parsedData = JSON.parse(rawData);
          const validatorSet = {};

          parsedData.validators?.forEach((validator) => {
            const base64ConsensusPubKey = validator.consensus_pubkey.key;
            const ed25519PubkeyRaw = Buffer.from(base64ConsensusPubKey, 'base64');
            const addressData = crypto.createHash('sha256').update(ed25519PubkeyRaw).digest().subarray(0, 20);
            const hexAddress = addressData.toString('hex').toUpperCase();

            validatorSet[hexAddress] = validator.description.moniker;
          });

          resolve(validatorSet);
        });
      }
    );
  });
}

try {
  let validatorSet;

  getValidatorSet().then((_validatorSet) => (validatorSet = _validatorSet));

  const ws = new WebSocket('ws://0.0.0.0:26657/websocket');

  ws.onerror = (error) => {
    console.error(`Tendermint connection error ${error.message}`);
    sendMessageToDiscord(`Tendermint connection error ${error.message}`);
  };

  ws.onopen = () => {
    console.log('Tendermint connection opened');
    sendMessageToDiscord('Tendermint connection opened');
    ws.send(queryFactory(0, "tm.event='NewBlock'"));
    ws.send(queryFactory(1, "tm.event='ValidatorSetUpdates'"));
    // ws.send(queryFactory(2, "tm.event='TimeoutPropose'"));
    // ws.send(queryFactory(3, "tm.event='TimeoutWait'"));
  };

  ws.onmessage = async (event) => {
    const parsedSocketData = JSON.parse(event.data);

    if (Object.keys(parsedSocketData.result).length === 0) return;

    switch (parsedSocketData.result.query) {
      case "tm.event='NewBlock'":
        const lastBlock = parsedSocketData.result.data.value.block.last_commit;
        const signatureThreshold =
          lastBlock.signatures.reduce((sum, signatureObj) => {
            sum += +!!signatureObj.signature;

            return sum;
          }, 0) / maxValidators;

        if (
          signatureThreshold > 0.7 &&
          lastBlock.signatures.find((signature) => signature.validator_address === valAddress)
        )
          return;

        http.get(`http://0.0.0.0:26657/block?height=${lastBlock.height}`, (res) => {
          res.setEncoding('utf8');

          let rawData = '';

          res.on('data', (chunk) => (rawData += chunk));
          res.on('end', () => {
            const parsedHttpData = JSON.parse(rawData);

            if (parsedHttpData.error) return;

            const lastBlockHeader = parsedHttpData.result.block.header;

            sendMessageToDiscord(
              'Missed block report' +
                `\n\tHeight: ${lastBlockHeader.height}` +
                `\n\tSignature threshold: ${(signatureThreshold * 100).toFixed(2)}%` +
                `\n\tProposer: ${validatorSet[lastBlockHeader.proposer_address]}`
            );
          });
        });
        break;
      case "tm.event='ValidatorSetUpdates'":
        getValidatorSet().then((_validatorSet) => {
          if (JSON.stringify(_validatorSet) === JSON.stringify(validatorSet)) return;

          console.log(_validatorSet);

          validatorSet = _validatorSet;
        });
    }
  };
} catch (error) {
  console.error(`Report error ${erorr.message}`);
  sendMessageToDiscord(`Report service error ${error.message}`);
}
