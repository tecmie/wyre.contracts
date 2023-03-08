// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import "forge-std/Test.sol";
import {Wyre} from "../src/contracts/Wyre.sol";
import {TestToken} from "../src/testtoken/TestToken.sol";

contract WyreFundContractWithETHTest is Test {
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

    address[5] public setEmployees = [employee1, employee2, employee3, employee4, employee5];
    address[5] public setEmployeesOneZero =[employee1, employee2, employee3, address(0), employee5];

    uint256[5] public setRewards = [1 ether, 2 ether, 3 ether, 4 ether, 5 ether];
    uint256[6] public badRewards = [1 ether, 2 ether, 3 ether, 4 ether, 5 ether, 6 ether];

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
    }

    /// @dev Test the fundContractWithETH function.
    function testFundContractWithETH(uint256 amount) public pranking {
        vm.assume(amount > 1 ether);
        vm.assume(amount < 30 ether);

        uint256 oldBalance = address(wyre).balance;

        wyre.fundContractWithETH{value: amount}();

        uint256 newBalance = address(wyre).balance;

        assertEq(newBalance - oldBalance, amount);
    }

    function testExternalFund(uint256 amount) public pranking {
        vm.assume(amount > 1 ether);
        vm.assume(amount < 30 ether);

        uint256 oldBalance = address(wyre).balance;

        (bool success, ) = payable(address(wyre)).call{value: amount}("");
        success;

        uint256 newBalance = address(wyre).balance;

        assertEq(newBalance - oldBalance, amount);
    }
}