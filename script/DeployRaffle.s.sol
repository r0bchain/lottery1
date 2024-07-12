// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {


    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
                    
        if(config.subscriptionId == 0) {

            console.log("subscription ID is 0");
            // Create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) = 
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            console.log('*******************config.subscriptionId*********************', config.subscriptionId);

            // Fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.subscriptionId, 
            config.gasLane, 
            config.automationUpdateInterval, 
            config.raffleEntranceFee,
            config.callbackGasLimit,
            config.vrfCoordinatorV2_5);
        vm.stopBroadcast();

        // Do not need a broadcast, the consumer method already has one.
        AddConsumer addConsumer = new AddConsumer();
        console.log('config.subscriptionId', config.subscriptionId);
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);

        return (raffle, helperConfig);
    }

    function run() external returns (Raffle, HelperConfig) {
        return deployContract();
    }

}