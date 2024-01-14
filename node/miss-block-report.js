const http = require('node:http');
const https = require('node:https');
const WebSocket = require('ws');
const crypto = require('node:crypto');

const webhookToken = process.argv[0];

if (!webhookToken) {
  console.error('No webhooks token provided');
  return;
}

const ws = new WebSocket('ws://0.0.0.0:26657/websocket');

function sendMessageToDiscord(message) {
  const req = https.request({
    headers: { 'Content-Type': 'application/json' },
    hostname: 'discord.com',
    path: `/api/webhooks/${webhookToken}`,
    method: 'POST',
  });

  req.write(JSON.stringify({ username: '(contabo) stargaze-mainnet-7', content: message }));
  req.on('error', (e) => console.error(e));
  req.end();
}

function queryFactory(id, query) {
  return JSON.stringify({ jsonrpc: '2.0', method: 'subscribe', id, params: { query } });
}

function getValidatorSet() {
  http.get(
    'http://0.0.0.0:1317/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED&pagination.limit=130',
    (res) => {
      res.setEncoding('utf8');

      let rawData = '';
      validatorSet = {};

      res.on('data', (chunk) => (rawData += chunk));
      res.on('end', () => {
        const parsedData = JSON.parse(rawData);

        parsedData.validators.forEach((validator) => {
          const base64ConsensusPubKey = validator.consensus_pubkey.key;
          const pubKeyBytes = Buffer.from(base64ConsensusPubKey, 'base64');
          const hashedPubKey = crypto.createHash('sha256').update(pubKeyBytes).digest();
          const validatorAddress = hashedPubKey.subarray(0, 20).toString('hex').toUpperCase();

          validatorSet[validatorAddress] = validator.description.moniker;
        });
      });
    }
  );
}

try {
  let validatorSet = {};

  getValidatorSet();

  ws.onopen = () => {
    sendMessageToDiscord('Tendermint connection opened');
    ws.send(queryFactory(0, "tm.event='NewBlock'"));
    ws.send(queryFactory(1, "tm.event='ValidatorSetUpdates'"));
    // ws.send(queryFactory(2, "tm.event='TimeoutPropose'"));
    // ws.send(queryFactory(3, "tm.event='TimeoutWait'"));
  };

  ws.onclose = () => sendMessageToDiscord('Tendermint connection closed');

  ws.onerror = (error) => sendMessageToDiscord(`Tendermint connection error ${error.message}`);

  ws.onmessage = (event) => {
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
        getValidatorSet();
    }
  };
} catch (error) {
  sendMessageToDiscord(`Report service error ${error.message}`);
}
