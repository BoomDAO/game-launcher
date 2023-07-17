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

## VERIFY CANISTER'S MODULE HASH

To get the hash for Game Launcher canisters:

- Get the canister IDs from [`canister_ids.json`](https://github.com/BoomDAO/game-launcher/blob/staging/canister_ids.json).
- Get hash using the DFX SDK by running: `dfx canister --network ic info <canister-id>`.

- The output of the above command should contain `Module hash` followed up with the hash value. Example output:

  ```
  $ > dfx canister --network ic info 6rvbl-uqaaa-aaaal-ab24a-cai

  Controllers: 2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe ...
  Module hash: 0x9d32c5bc82e9784d61856c7fa265e9b3dda4e97ee8082b30069ff39ab8626255
  ```



<p align="center">
  <a href="logo" target="_blank" rel="noreferrer"><img src="https://github.com/BoomDAO/world-template/assets/29381374/46aaa5e2-93b2-4b66-a654-527fd04c070a" alt="my banner"></a>
</p>
