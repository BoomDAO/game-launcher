<p align="center">
  <a href="logo" target="_blank" rel="noreferrer"><img src="https://github.com/BoomDAO/game-launcher/assets/29381374/875537bb-f9d4-4594-84e0-a7375ce46213" alt="my banner"></a>
</p>

## GAME LAUNCHER

The **Game Launcher** is a platform that simplifies the creation of on-chain games on the Internet Computer blockchain. With just **one click**, developers can upload **WebGL**, **PC**, and **Android** builds directly to canister smart contracts. All uploaded games are immediately surfaced on a dedicated discovery page for players to browse and play. 

Game developers have the power to create self-custodial **NFT** and **Token** collections with a single click, alongside launching seamless **airdrops** to thousands of holders. Streamline in-game NFT and Token **minting**, **payments**, **staking**, and **burning** directly from the website.

Deploy a game **World** and configure the contract directly on the Game Launcher website without writing a single line of code. Enforce smart contract laws and empower composability in your game at its inception.

The Game Launcher shortens game development timelines from months to days. 

## CHECK IT OUT

You can use the Game Launcher here: http://launcher.boomdao.xyz

## TECH DOCUMENTATION

To dive deeper into the Game Launcher, read the tech docs here: https://docs.boomdao.xyz/game-launcher

<p align="center">
  <a href="logo" target="_blank" rel="noreferrer"><img src="https://github.com/BoomDAO/game-launcher/assets/29381374/7242c0b8-aae2-403a-9475-5ed22492bc4e" alt="my banner"></a>
</p>

## VERIFYING CANISTER BUILDS

To get the hash for Game Launcher canisters:

- Get the canister IDs from [`canister_ids.json`](https://github.com/BoomDAO/game-launcher/blob/main/canister_ids.json).
- Get hash using the DFX SDK by running: `dfx canister --network ic info <canister-id>`.

- The output of the above command should contain `Module hash` followed up with the hash value. Example output:

  ```
  $ > dfx canister --network ic info 6rvbl-uqaaa-aaaal-ab24a-cai

  Controllers: 2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe ...
  Module hash: 0x9d32c5bc82e9784d61856c7fa265e9b3dda4e97ee8082b30069ff39ab8626255
  ```
To get the hash for Canisters deployment:

- Go to [Github actions deployment runs](https://github.com/BoomDAO/game-launcher/actions)
- Open the latest succesful run. ([Click to see an example run](https://github.com/BoomDAO/game-launcher/actions/runs/5641910908))
- Go to `Build and Deploy all BOOM DAO Game Launcher canisters` job.
- Open `Deploy All Canisters` step. Scroll to the end of this Job, you should find the `Module hash` in this step. This value should match the value you got locally. 


## TECHNICAL ARCHITECTURE

<p align="center">
  <a href="logo" target="_blank" rel="noreferrer"><img src="https://github.com/BoomDAO/game-launcher/assets/29381374/e64d58f7-2f0c-4a4c-975f-bfdc131f57a9" alt="my banner"></a>
</p>
