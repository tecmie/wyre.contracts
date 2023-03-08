// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import "forge-std/Test.sol";
import {Wyre} from "../src/contracts/Wyre.sol";
import {TestToken} from "../src/testtoken/TestToken.sol";

contract WyreSignatureTest is Test {
    Wyre wyre;
    TestToken testToken;

    uint256 ownerPK = 0x029eAd;
    address owner = vm.addr(ownerPK);

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
        vm.warp(9819483094813439384719847198918041);
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
        console.log(block.timestamp);
    }

    function sign(bytes32 hash) public view returns (uint8 v, bytes32 r, bytes32 s) {
        return vm.sign(ownerPK, hash);
    }

    function testExecuteSignedContractorETHReward(uint256 amount) public pranking {
        vm.assume(amount < 80 ether);
        payable(address(wyre)).transfer(80 ether);
        uint256 oldWBal = address(wyre).balance;
        uint256 oldBal = alice.balance;

        address contractor = alice;
        uint256 reward = amount;
        uint256 seed = block.timestamp * 45;
        uint256 deadline = block.timestamp + 56 days;

        console.log(alice);

        (uint8 v, bytes32 r, bytes32 s) = sign(wyre.hashContractorETHRewardForSigning(contractor, reward, seed, deadline));

        console.log(uint256(r));
        wyre.executeSignedContractorETHReward(contractor, reward, seed, deadline, v, r, s);

        console.log(uint256(r));
        vm.expectRevert();
        wyre.executeSignedContractorETHReward(contractor, reward, seed, deadline, v, r, s);

        uint256 newBal = alice.balance;
        uint256 newWBal = address(wyre).balance;

        console.log(v);
        assert(newBal - oldBal == amount);
        assert(oldWBal - newWBal == amount);

    }

    function testExecuteSignedContractorTokenReward(uint256 amount) public pranking {
        vm.assume(amount < 80 ether);
        testToken.transfer(address(wyre), 80 ether);
        uint256 oldWBal = testToken.balanceOf(address(wyre));
        uint256 oldBal = testToken.balanceOf(alice);

        address contractor = alice;
        uint256 reward = amount;
        uint256 seed = block.timestamp * 45;
        uint256 deadline = block.timestamp + 56 days;

        (uint8 v, bytes32 r, bytes32 s) = sign(wyre.hashContractorTokenRewardForSigning(contractor, reward, address(testToken), seed, deadline));

        console.log(uint256(r));
        wyre.executeSignedContractorTokenReward(contractor, reward, address(testToken), seed, deadline, v, r, s);

        console.log(uint256(r));
        vm.expectRevert();
        wyre.executeSignedContractorTokenReward(contractor, reward, address(testToken), seed, deadline, v, r, s);

        uint256 newBal = testToken.balanceOf(alice);
        uint256 newWBal = testToken.balanceOf(address(wyre));

        console.log(v);
        assert(newBal - oldBal == amount);
        assert(oldWBal - newWBal == amount);
    }

    function testExecuteSignedContractorTokenRewardButPastTime(uint256 amount) public pranking {
        vm.assume(amount < 80 ether);
        testToken.transfer(address(wyre), 80 ether);
        uint256 oldWBal = testToken.balanceOf(address(wyre));
        uint256 oldBal = testToken.balanceOf(alice);

        address contractor = alice;
        uint256 reward = amount;
        uint256 seed = block.timestamp * 45;
        uint256 deadline = block.timestamp - 56 days;

        vm.expectRevert();
        bytes32 hash = wyre.hashContractorTokenRewardForSigning(contractor, reward, address(testToken), seed, deadline);
        (uint8 v, bytes32 r, bytes32 s) = sign(hash);

        console.log(uint256(r));
        vm.expectRevert();
        wyre.executeSignedContractorTokenReward(contractor, reward, address(testToken), seed, deadline, v, r, s);

        console.log(uint256(r));
        vm.expectRevert();
        wyre.executeSignedContractorTokenReward(contractor, reward, address(testToken), seed, deadline, v, r, s);

        uint256 newBal = testToken.balanceOf(alice);
        uint256 newWBal = testToken.balanceOf(address(wyre));

        console.log(v);
        assert(newBal - oldBal == 0);
        assert(oldWBal - newWBal == 0);

    }
}