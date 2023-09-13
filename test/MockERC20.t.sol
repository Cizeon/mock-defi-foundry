// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";

// solhint-disable func-name-mixedcase,contract-name-camelcase

contract MockERC20BaseSetupTest is Test {
    MockERC20 internal _tokenA;
    address public owner = address(this);
    address public hacker1 = makeAddr("hacker1");
    address public hacker2 = makeAddr("hacker2");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public virtual {
        _tokenA = new TokenA();
        vm.label(owner, "owner");
    }
}

contract MockERC20_Deploy_Test is MockERC20BaseSetupTest {
    function test_balanceOf() public {
        uint256 balance = _tokenA.balanceOf(owner);
        uint256 supply = _tokenA.totalSupply();
        assertEq(balance, supply);
    }

    function test_decimals_pass_correct_value() public {
        uint8 decimals = _tokenA.decimals();
        assertEq(decimals, 18, "wrong decimals");
    }

    function test_name_pass_correct_value() public {
        string memory name = _tokenA.name();
        bool same = keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("TokenA"));
        assertTrue(same, "wrong name");
    }

    function test_symbol_pass_correct_value() public {
        string memory symbol = _tokenA.symbol();
        bool same = keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("TKA"));
        assertTrue(same, "wrong symbol");
    }
}

contract MockERC20_Transfer_Test is MockERC20BaseSetupTest {
    function test_transfer_pass_correct_event(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        // If this fails, it could be because the address are not indexed.
        vm.expectEmit(true, true, true, false, address(_tokenA));
        emit Transfer(address(this), alice, amount);
        _tokenA.transfer(alice, amount);
    }

    function test_transfer_pass_correct_balance(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        uint256 balanceBefore = _tokenA.balanceOf(owner);
        _tokenA.transfer(alice, amount);
        assertEq(_tokenA.balanceOf(owner), balanceBefore - amount, "wrong sender balance");
        assertEq(_tokenA.balanceOf(alice), amount, "wrong receiver balance");
    }

    function test_transfer_fail_if_too_much(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        vm.prank(alice);
        vm.expectRevert(abi.encodePacked("ERC20: transfer amount exceeds balance"));
        _tokenA.transfer(bob, amount);
    }

    function test_transfer_fail_amount_zero() public {
        uint256 amount = 0;

        vm.expectRevert(abi.encodePacked("Zero-Value Token Transfer Attack"));
        _tokenA.transfer(alice, amount);
    }

    function test_transferFrom_fail_amount_zero() public {
        uint256 amount = 0;

        vm.expectRevert(abi.encodePacked("Zero-Value Token Transfer Attack"));
        _tokenA.transferFrom(owner, alice, amount);
    }

    function test_approve_pass_correct_amount(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        _tokenA.approve(alice, amount);
        uint256 approved = _tokenA.allowance(owner, alice);
        assertEq(amount, approved, "allowance differ");
    }

    function test_approve_pass_reset(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        _tokenA.approve(alice, amount);
        _tokenA.approve(alice, 0);
        uint256 approved = _tokenA.allowance(owner, alice);
        assertEq(0, approved, "allowance not reset");
    }

    function test_approve_pass_correct_event(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        vm.expectEmit(true, true, true, false, address(_tokenA));
        emit Approval(owner, alice, amount);
        _tokenA.approve(alice, amount);
    }

    function test_transferFrom_pass_if_approved(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        _tokenA.approve(alice, amount);
        vm.prank(alice);
        _tokenA.transferFrom(owner, alice, amount);
        uint256 balance = _tokenA.balanceOf(alice);
        assertEq(balance, amount, "transferFrom failed after approval");
    }

    function test_transferFrom_fail_not_approved(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        vm.prank(hacker1);
        vm.expectRevert(abi.encodePacked("ERC20: insufficient allowance"));
        _tokenA.transferFrom(owner, hacker1, amount);
    }

    function test_transferFrom_pass_if_less_than_approved(uint256 amount, uint256 amountToTransfer) public {
        amount = bound(amount, 2, _tokenA.balanceOf(owner));
        amountToTransfer = bound(amountToTransfer, 1, amount - 1);

        console2.log(amount);
        console2.log(amountToTransfer);

        uint256 amountDifference = amount - amountToTransfer;
        _tokenA.approve(alice, amount);
        vm.prank(alice);
        _tokenA.transferFrom(owner, alice, amountDifference);
    }

    function test_transferFrom_fail_if_more_than_approved(uint256 amount, uint256 amountToTransfer) public {
        amount = bound(amount, 2, _tokenA.balanceOf(owner));
        amountToTransfer = bound(amountToTransfer, amount + 1, 2 ** 256 - 1 - amount);

        uint256 amountDifference = amount + amountToTransfer;
        _tokenA.approve(hacker1, amount);
        vm.prank(hacker1);
        vm.expectRevert(abi.encodePacked("ERC20: insufficient allowance"));
        _tokenA.transferFrom(owner, hacker1, amountDifference);
    }

    function test_transferFrom_pass_decrease_allowance(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        _tokenA.approve(alice, amount);
        vm.prank(alice);
        _tokenA.transferFrom(owner, alice, amount);
        uint256 approved = _tokenA.allowance(owner, alice);
        assertEq(approved, 0, "allowance did not decrease");
    }

    function test_transferFrom_pass_adjust_balance(uint256 amount) public {
        amount = bound(amount, 1, _tokenA.balanceOf(owner));

        uint256 balanceAlice = _tokenA.balanceOf(alice);
        _tokenA.approve(alice, amount);
        vm.prank(alice);
        _tokenA.transferFrom(owner, alice, amount);
        uint256 balanceAliceUpdated = _tokenA.balanceOf(alice);
        assertEq(balanceAlice + amount, balanceAliceUpdated, "balance not updated");
    }
}
