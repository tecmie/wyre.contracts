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
    function testRewardEmployeesWithETHByNonOwner() public {
        vm.deal(address(this), 50 ether);

        vm.expectRevert();
        bool isTrue = wyre.rewardEmployeesWithETH(setEmployees, setRewards);

        assertFalse(isTrue);
    }

    function testRewardEmployeesWithETHWithMismatchedArray() public pranking {
        vm.expectRevert();

        bool isTrue = wyre.rewardEmployeesWithETH(setEmployees, badRewards);

        assertFalse(isTrue);
    }

    function testRewardEmployeesWithETHButSumGTBalance() public pranking {
        vm.expectRevert();
        vm.deal(address(wyre), 1 ether);
        bool isTrue = wyre.rewardEmployeesWithETH(setEmployees, setRewards);

        assertFalse(isTrue);
    }

    function testRewardEmployeesWithETH() public pranking {
        vm.deal(address(wyre), 50 ether);
        uint256[5] memory prevBalances = [setEmployees[0].balance, setEmployees[1].balance, setEmployees[2].balance, setEmployees[3].balance, setEmployees[4].balance];
        bool isTrue = wyre.rewardEmployeesWithETH(setEmployees, setRewards);

        for (uint256 i; i < setEmployees.length; ++i) {
            assertLt(prevBalances[i], setEmployees[i].balance);
        }

        assertTrue(isTrue);
        assertLt(address(wyre).balance, 50 ether);
    }

    function testReenter() public pranking {
        vm.deal(address(wyre), 50 ether);

        vm.expectRevert();
        bool isTrue = wyre.rewardEmployeesWithETH(maliciousEmployee, setRewards);

        assertFalse(isTrue);
    }

    receive() external payable {
        wyre.rewardEmployeesWithETH(me, me2);
    }
}