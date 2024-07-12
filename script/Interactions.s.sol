// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        (uint256 subId, ) = createSubscription(vrfCoordinator, helperConfig.getConfig().account);

        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinatorV2_5, address account) public returns (uint256, address) {
        console.log("Creating subscripton on chain id: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();

        vm.stopBroadcast();

        return (subId, vrfCoordinatorV2_5);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }

}

contract FundSubscription is Script, CodeConstants {

    uint256 public constant FUND_AMOUNT = 25000000000000000 wei;

    function FundSubscriptionConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        address linkToken = helperConfig.getConfig().link;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);

    }   

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account) public {

        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if(block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }


    }

    function run() public {
        FundSubscriptionConfig();
    }

}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address mostRecentryDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentryDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding cosumer contract: ", vrfCoordinator);
        console.log("To vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVrf);
        vm.stopBroadcast();
    }

    function run() external { 
        address mostRecentryDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentryDeployed);
    }
}

