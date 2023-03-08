// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import "forge-std/Test.sol";
import {Wyre} from "../src/contracts/Wyre.sol";
import {TestToken} from "../src/testtoken/TestToken.sol";

contract WyreRewardEmployeesWithETHTest is Test {
    Wyre wyre;
    TestToken testToken;

    address owner = vm.addr(0x029eAd);

    address alice = vm.addr(0xabcd);
    address bob = vm.addr(0xb0B0);

    address employee1 = vm.addr(1);
    address employee2 = vm.addr(2);
    address employee3 = vm.addr(3);
    address employee4 = vm.addr(4);
    address employee5 = vm.addr(5);

    address[] public setEmployees = [employee1, employee2, employee3, employee4, employee5];
    address[] public setEmployeesOneZero =[employee1, employee2, employee3, address(0), employee5];
    address[] public maliciousEmployee =[employee1, employee2, address(this), address(0), employee5];

    address[] public me = [address(this)];
    uint256[] public me2 = [3 ether];

    uint256[] public setRewards = [1 ether, 2 ether, 3 ether, 4 ether, 5 ether];
    uint256[] public badRewards = [1 ether, 2 ether, 3 ether, 4 ether, 5 ether, 6 ether];

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

    // Test 1, call by non owner.
    function testFailRewardEmployeesWithTokenByNonOwner() public {
        vm.prank(owner);
        testToken.transfer(address(wyre), 50 ether);

        bool isTrue = wyre.rewardEmployeesWithToken(setEmployees, setRewards, address(testToken));

        assertFalse(isTrue);
    }

    function testRewardEmployeesWithTokenWithMismatchedArray() public pranking {
        testToken.transfer(address(wyre), 50 ether);

        vm.expectRevert();
        bool isTrue = wyre.rewardEmployeesWithToken(setEmployees, badRewards, address(testToken));

        assertFalse(isTrue);
    }

    function testRewardEmployeesWithTokenButSumGTBalance() public pranking {
        testToken.transfer(address(wyre), 1 ether);

        vm.expectRevert();
        bool isTrue = wyre.rewardEmployeesWithToken(setEmployees, setRewards, address(testToken));

        assertFalse(isTrue);
    }

    function testRewardEmployeesWithETH() public pranking {
        testToken.transfer(address(wyre), 50 ether);
        uint256[5] memory prevBalances = [testToken.balanceOf(setEmployees[0]), testToken.balanceOf(setEmployees[1]), testToken.balanceOf(setEmployees[2]), testToken.balanceOf(setEmployees[3]), testToken.balanceOf(setEmployees[4])];
        bool isTrue = wyre.rewardEmployeesWithToken(setEmployees, setRewards, address(testToken));

        for (uint256 i; i < setEmployees.length; ++i) {
            assertLt(prevBalances[i], testToken.balanceOf(setEmployees[i]));
        }

        assertTrue(isTrue);
        assertLt(testToken.balanceOf(address(wyre)), 50 ether);
    }
}