// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import "forge-std/Test.sol";
import {Wyre} from "../src/contracts/Wyre.sol";
import {TestToken} from "../src/testtoken/TestToken.sol";

contract WyreRewardContractorWithETHTest is Test {
    Wyre wyre;
    TestToken testToken;

    address owner = vm.addr(0x029eAd);

    address alice = vm.addr(0xabcd);
    address bob = vm.addr(0xb0B0);

    modifier pranking() {
        vm.startPrank(owner);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);

        wyre = new Wyre();
        testToken = new TestToken();

        vm.stopPrank();
    }

    function testSetUp() public {
        assertFalse(address(wyre) == address(0));
        assertEq(owner.balance, 100 ether);
        assertEq(testToken.balanceOf(owner), type(uint256).max);
        assertEq(address(wyre).balance, 0);
        assertEq(wyre.owner(), owner);

        console.log(address(wyre));
        console.log(owner);
        console.log(wyre.owner());
    }

    function testRewardContractorWithEthZeroAddress() public pranking {
        vm.expectRevert();
        wyre.rewardContractorWithETH(address(0), 6 ether);
    }

    function testRewardContractorWithEthButInsufficientFunds(uint256 amount) public pranking {
        vm.assume(amount < 100 ether);

        uint256 oldBal = alice.balance;
        vm.expectRevert();
        wyre.rewardContractorWithETH(alice, 6 ether);
        uint256 newBal = alice.balance;

        assert(newBal == oldBal);
    }

    function testRewardContractorWithEth(uint256 amount) public pranking {
        vm.assume(amount < 80 ether);
        payable(address(wyre)).transfer(80 ether);

        uint256 oldWBal = address(wyre).balance;

        uint256 oldBal = alice.balance;
        wyre.rewardContractorWithETH(alice, amount);
        uint256 newBal = alice.balance;

        uint256 newWBal = address(wyre).balance;

        assert(newBal - oldBal == amount);
        assert(oldWBal - newWBal == amount);
    }
}