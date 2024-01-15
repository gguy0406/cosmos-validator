const http = require('node:http');
const https = require('node:https');
const WebSocket = require('ws');
const crypto = require('node:crypto');

const webhookToken = process.argv[0];
const hostname = process.argv[1];

if (!webhookToken) throw new Error('No webhooks token provided');

const ws = new WebSocket('ws://0.0.0.0:26657/websocket');

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
      'http://0.0.0.0:1317/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED&pagination.limit=130',
      (res) => {
        res.setEncoding('utf8');

        let rawData = '';

        res.on('data', (chunk) => (rawData += chunk));
        res.on('end', () => {
          const parsedData = JSON.parse(rawData);
          const validatorSet = {};

          parsedData.validators.forEach((validator) => {
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
  let validatorSet = await getValidatorSet();

  console.log(validatorSet);

  ws.onopen = () => {
    console.log('Tendermint connection opened');
    sendMessageToDiscord('Tendermint connection opened');
    ws.send(queryFactory(0, "tm.event='NewBlock'"));
    ws.send(queryFactory(1, "tm.event='ValidatorSetUpdates'"));
    // ws.send(queryFactory(2, "tm.event='TimeoutPropose'"));
    // ws.send(queryFactory(3, "tm.event='TimeoutWait'"));
  };

  ws.onclose = () => {
    console.log('Tendermint connection closed');
    sendMessageToDiscord('Tendermint connection closed');
  };

  ws.onerror = (error) => {
    console.error(`Tendermint connection error ${error.message}`);
    sendMessageToDiscord(`Tendermint connection error ${error.message}`);
  };

  ws.onmessage = async (event) => {
    const parsedSocketData = JSON.parse(event.data);

    if (Object.keys(parsedSocketData.result).length === 0) return;

    switch (parsedSocketData.result.query) {
      case "tm.event='NewBlock'":
        const lastBlock = parsedSocketData.result.data.value.block.last_commit;

        if (
          lastBlock.signatures.length / 130 > 0.7 &&
          lastBlock.signatures.find(
            (signature) => signature.validator_address === '54670CE963DE9962D1A82A2E4741888E884B0BA2'
          )
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
              `block height: ${lastBlockHeader.height}\n` +
                `signature threshold: ${(lastBlock.signatures.length / 130) * 100}%\n` +
                `proposer: ${validatorSet[proposer_address]}` +
                `block hash: ${lastBlock.block_id.hash}\n`
            );
          });
        });
        break;
      case "tm.event='ValidatorSetUpdates'":
        const newValidatorSet = await getValidatorSet();

        if (JSON.stringify(validatorSet) === JSON.stringify(newValidatorSet)) return;

        console.log(newValidatorSet);

        validatorSet = newValidatorSet;
    }
  };
} catch (error) {
  console.error(`Report error ${erorr.message}`);
  sendMessageToDiscord(`Report service error ${error.message}`);
}
