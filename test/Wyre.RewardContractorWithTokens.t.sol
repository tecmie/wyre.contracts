// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import "forge-std/Test.sol";
import {Wyre} from "../src/contracts/Wyre.sol";
import {TestToken} from "../src/testtoken/TestToken.sol";

contract WyreRewardContractorWithTokenTest is Test {
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

    function testRewardContractorWithTokenZeroAddress() public pranking {
        vm.expectRevert();
        wyre.rewardContractorWithToken(address(0), 6 ether, address(testToken));
    }

    function testRewardContractorWithTokenButInsufficientFunds(uint256 amount) public pranking {
        vm.assume(amount < 100 ether);

        uint256 oldBal = testToken.balanceOf(alice);
        vm.expectRevert();
        wyre.rewardContractorWithToken(alice, 6 ether, address(testToken));
        uint256 newBal = testToken.balanceOf(alice);

        assert(newBal == oldBal);
    }

    function testRewardContractorWithToken(uint256 amount) public pranking {
        vm.assume(amount < 80 ether);
        testToken.transfer(address(wyre), 80 ether);

        uint256 oldWBal = testToken.balanceOf(address(wyre));

        uint256 oldBal = testToken.balanceOf(alice);
        wyre.rewardContractorWithToken(alice, amount, address (testToken));
        uint256 newBal = testToken.balanceOf(alice);

        uint256 newWBal = testToken.balanceOf(address(wyre));

        assert(newBal - oldBal == amount);
        assert(oldWBal - newWBal == amount);
    }
}