import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import RandomUtil "../utils/RandomUtil";
import Utils "../utils/Utils";
import Int "mo:base/Int";

import ENV "../utils/Env";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

import ActionTypes "../types/action.types";
import EntityTypes "../types/entity.types";

module{
    public type EntityConfigs = [EntityTypes.EntityConfig]; 
    public type ActionConfigs = [ActionTypes.ActionConfig]; 

    public let Nft_Canister = "6uvic-diaaa-aaaap-abgca-cai"; //Game Collection
    public let ICRC1_Ledger = "6bszp-caaaa-aaaap-abgbq-cai"; //Game Token
    
    public let entityConfigs : EntityConfigs = [      
        // //ITEMS
        { 
            eid = "character_a"; 
            gid = "";
            name = ?"CharacterA"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?""; 
            rarity = ?"common"; 
            duration = null;
            metadata = "";
            tag = "item skin"; 

        },
        { 
            eid = "character_b";
            gid = "";
            name = ?"CharacterB"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";  
            rarity = ?"common"; 
            duration = null; 
            metadata = "";
            tag = "item skin"; 
        },
        { 
            eid = "character_c";
            gid = "";
            name = ?"CharacterC"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common"; 
            duration = null;
            metadata = "";
            tag = "item skin"; 
        },
        { 
            eid = "character_d"; 
            gid = "";
            name = ?"CharacterD"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "character_e"; 
            gid = "";
            name = ?"CharacterE"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "character_f";
            gid = "";
            name = ?"CharacterF"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"rare";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "character_g";
            gid = "";
            name = ?"CharacterG"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"rare";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "character_h";
            gid = "";
            name = ?"CharacterH"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"special";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "item_a";
            gid = "";
            name = ?"ItemA"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "item_b";
            gid = "";
            name = ?"ItemB"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "item_c";
            gid = "";
            name = ?"ItemC"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        //// add more items here...
    ];
    public let actionConfigs : ActionConfigs = [
        //CLAIM STAKE ICP REWARD
        { 
            aid = "stakeIcp";
            name = ?"Stake Icp";
            description = ?"You can try receive reward over time for staking at least 0.005 ICP";
            imageUrl = null;
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingRewardIcp 
            { 
                requiredAmount = 0.005;//0.005 ICP
            };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "character_a", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //CLAIM STAKE ICRC REWARD
        { 
            aid = "stakeIcrc";
            name = ?"Stake Icrc";
            description = ?"You can try receive reward over time for staking at least 0.005 ICP";
            imageUrl = null;
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingRewardIcrc 
            { 
                requiredAmount = 0.00005;//0.005 ICRC
                canister = ICRC1_Ledger;
            };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "character_b", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //CLAIM STAKE NFT REWARD
        { 
            aid = "stakeNft";
            name = ?"Stake Nft";
            description = ?"You can try receive reward over time for staking at least 1 Nft";
            imageUrl = null;
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingRewardNft 
            { 
                requiredAmount = 1;//0.005 ICRC
                canister = Nft_Canister;
            };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "character_c", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //BURN NFT
        { 
            aid = "burn_nft_tiket";
            name = ?"Burn a Test NFT!";
            description = ?"Burn a Test NFT to get a random reward in return!";
            imageUrl = null;
            tag = ?"BurnNft";
            actionPlugin = ? #burnNft { canister = Nft_Canister; };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "character_a", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_b", 1); weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_c", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_d", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_e", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_f", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_g", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "character_h", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //SPEND ICP TO MINT NFT 
        { 
            aid = "spend_icp_to_mint_test_nft";
            name = ?"Buy a Test NFT!";
            description = ?"Spend 0.001 ICP to get a \"Test NFT\" ";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Mint";
            actionPlugin = ? #verifyTransferIcp { amt = 0.001; toPrincipal = ENV.PaymentHubCanisterId };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintNft {
                                index = null;
                                name = "Test Nft";
                                description = "Spend 0.001 ICP to purchase a Test NFT."; 
                                imageUrl = ""; 
                                canister  = Nft_Canister;
                                assetId = "testAsset";
                                collection = "Nft Reward";
                                metadata = "{\"tag\":\"random-nft-reward\"}";
                            }; weight = 100;},
                        ]
                    }
                ]
            };
        },
        //Mint a Free Test NFT
        { 
            aid = "mint_test_nft";
            name = ?"Mint a free Test NFT!";
            description = ?"Mint a Free Test NFT";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = null;
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintNft {
                                index = null;
                                name = "Test Nft";
                                description = "Mint a free Test NFT"; 
                                imageUrl = ""; 
                                canister  = Nft_Canister;
                                assetId = "testAsset";
                                collection = "Nft Reward";
                                metadata = "{\"tag\":\"random-nft-reward\"}";
                            }; weight = 100;},
                        ]
                    }
                ]
            };
        },
        //Mint 2 Free Test ICRC
        { 
            aid = "mint_test_icrc";
            name = ?"Test ICRC";
            description = ?"Mint 5 Free Test Token";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = null;
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintToken {
                                quantity = 5;
                                canister = ICRC1_Ledger;
                            }; weight = 100;},
                        ]
                    }
                ]
            };
        },
        //BUY ITEM1 WITH ICP
        { 
            aid = "buyItem1_Icp";
            name = ?"ItemA Offer!";
            description = ?"Spend 0.001 ICP to receive an ItemA";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            actionPlugin = ? #verifyTransferIcp { amt = 0.001; toPrincipal = ENV.PaymentHubCanisterId };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "item_a", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
        //BUY ITEM2 WITH ICRC
        { 
            aid = "buyItem2_Icrc";
            name = ?"ItemB Offer!";
            description = ?"Spend 1 Test Token to receive an ItemB";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            actionPlugin = ? #verifyTransferIcrc { canister = ICRC1_Ledger; amt = 1; toPrincipal = ENV.PaymentHubCanisterId };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "item_b", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
        //TRADE ITEM1 WITH ITEM3
        { 
            aid = "buyItem3_Item1";
            name = ?"Trade Offer";
            description = ?"Trade an in-game ItemA for an ItemC";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = ? 
                [{
                    worldId = "6irst-uiaaa-aaaap-abgaa-cai"; 
                    groupId = ""; 
                    entityId = "item_a"; 
                    equalToAttribute = null; 
                    greaterThanOrEqualQuantity = ? 1.0; 
                    lessThanQuantity = null; 
                    notExpired = null;
            
                }];
            };
            actionResult = { 
                outcomes = [
                    {//Substract
                        possibleOutcomes = [
                            { option = #spendEntityQuantity (?"6irst-uiaaa-aaaap-abgaa-cai", "", "item_a", 1); weight = 100;},
                        ]
                    },
                    {//Add
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (?"6irst-uiaaa-aaaap-abgaa-cai", "", "item_c", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
    ];
}