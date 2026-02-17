---
name: a0x-register
description: |
  Check your A0X tier and upgrade. Links your agent wallet via signature for higher limits.
  Uses $AGENT_PK environment variable (created by setup.sh).
  Activate on: register, upgrade, tier, wallet, limits, rate limit, ERC-8004.
---

# A0X Registration & Tier Upgrade

When the user invokes /a0x-register, follow these steps in order.

## Step 1: Check Current Status

1. Read `~/.claude/.a0x-wallet.json` to see current tier, API key, and agent wallet address
2. Extract the MCP server base URL from `~/.claude/.mcp.json` (the URL before `/{apiKey}/brain`)
3. Check if `$AGENT_PK` is available by running: `test -n "$AGENT_PK" && echo "ready" || echo "not set"`
4. Show the user their current tier and the upgrade path:

| Tier | Requests/day | Monthly | Requirement |
|------|-------------|---------|-------------|
| FREE | 50 | 1,500 | Auto-register |
| WALLET | 100 | 3,000 | Wallet signature |
| VERIFIED | 200 | 6,000 | ERC-8004 NFT |
| PREMIUM | Unlimited | Unlimited | x402 payment |

## Step 2: Ensure Agent Wallet is Ready

If `$AGENT_PK` is not set:
1. Check if Foundry is installed: `cast --version`
2. If not, tell the user: "Run `curl -L https://foundry.paradigm.xyz | bash && foundryup` then re-run setup"
3. If Foundry is available, tell the user to re-run the setup script: `bash ~/a0x/a0x-plugin/setup.sh`
4. The setup script creates the wallet and saves $AGENT_PK automatically
5. After re-running setup, the user needs to `source ~/.bashrc` (or `~/.zshrc`) to load $AGENT_PK

If `$AGENT_PK` is set, get the wallet address:
```
cast wallet address --private-key $AGENT_PK
```

## Step 3: Upgrade to WALLET Tier (automatic, no gas)

This step is fully automated. The user does NOT need to do anything manually.

1. Get the wallet address:
```
cast wallet address --private-key $AGENT_PK
```

2. Get the challenge message from the server:
```
curl -s "{BASE_URL}/challenge?walletAddress={WALLET_ADDRESS}"
```

3. Sign the challenge (Claude Code runs this -- $AGENT_PK is an env var, the actual key is never visible):
```
cast wallet sign --private-key $AGENT_PK "{CHALLENGE_MESSAGE}"
```

4. Link the wallet with the signature:
```
curl -s -X POST "{BASE_URL}/link-wallet" \
  -H "Content-Type: application/json" \
  -d '{"walletAddress": "{WALLET_ADDRESS}", "signature": "{SIGNATURE}", "apiKey": "{API_KEY}"}'
```

5. Update `~/.claude/.a0x-wallet.json` with the new tier and limits from the response.

6. Tell the user: "Upgraded to WALLET tier. You now have 100 requests/day."

## Step 4: Upgrade to VERIFIED Tier (optional, gasless)

After WALLET tier, offer the user to upgrade to VERIFIED:

1. Explain: "I can mint you an ERC-8004 identity NFT on Base for 200 req/day + vote + earn. You just need to send a small amount of ETH on Base to your agent wallet for gas."

2. Get the agent wallet address:
```
cast wallet address --private-key $AGENT_PK
```

3. Tell the user: "Send a small amount of ETH (0.001 ETH is enough) on Base to your agent wallet: {AGENT_ADDRESS}"
   - They can send from Coinbase, MetaMask, or any wallet that supports Base
   - Wait for the user to confirm they sent it

4. Check the balance to confirm funds arrived:
```
cast balance {AGENT_ADDRESS} --rpc-url https://mainnet.base.org
```
   - If balance is 0, tell the user the funds haven't arrived yet and to check the transaction
   - If balance is sufficient, proceed

5. Ask the user for a name for their onchain agent identity (or suggest a default based on their project or username)

6. Mint the ERC-8004 identity NFT:
```
cast send 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "register(string)" "{AGENT_NAME}" \
  --rpc-url https://mainnet.base.org \
  --private-key $AGENT_PK
```

7. Extract the tokenId from the transaction receipt. Look for the Transfer event log topic:
   - The `logs` array in the receipt will contain a Transfer event
   - The tokenId is in `topic[3]` (the 4th topic), as a hex number
   - Convert it to decimal: `cast --to-dec {HEX_TOKEN_ID}`
   - If no logs visible, try: `cast receipt {TX_HASH} --rpc-url https://mainnet.base.org` and parse the logs

8. Re-run the link-wallet flow (Step 3) but this time include the `tokenId` in the POST body:
```
curl -s -X POST "{BASE_URL}/link-wallet" \
  -H "Content-Type: application/json" \
  -d '{"walletAddress": "{WALLET_ADDRESS}", "signature": "{SIGNATURE}", "apiKey": "{API_KEY}", "nonce": "{NONCE}", "tokenId": {TOKEN_ID}}'
```
   - This verifies on-chain that the wallet owns the NFT and upgrades to VERIFIED tier
   - If the response shows `tier: "verified"`, the upgrade was successful

9. Update `~/.claude/.a0x-wallet.json` with tier: "verified", daily: 200, and tokenId from the mint

## Notes

- The $AGENT_PK env var is created by setup.sh and stored in the user's shell profile
- Claude Code never sees the actual private key value -- bash expands $AGENT_PK at runtime
- The agent wallet is dedicated (low balance, just for gas) -- not the user's main wallet
- The WALLET tier upgrade (step 3) requires no gas, only a signature
- The VERIFIED tier upgrade (step 4) requires a small amount of ETH on Base for gas (~0.001 ETH)
