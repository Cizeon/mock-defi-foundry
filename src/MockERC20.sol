// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 setDecimals,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _decimals = setDecimals;
        _mint(msg.sender, initialSupply);
    }

    /// @dev This is purely cosmetic but some SC may take 18 for granted.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @dev https://info.etherscan.com/zero-value-token-transfer-attack/
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(amount > 0, "Zero-Value Token Transfer Attack");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /// @dev https://info.etherscan.com/zero-value-token-transfer-attack/
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(amount > 0, "Zero-Value Token Transfer Attack");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}

contract TokenA is MockERC20 {
    // solhint-disable-next-line no-empty-blocks
    constructor() MockERC20("TokenA", "TKA", 18, 1_000_000_000_000 * 1e18) {}
}

contract TokenB is MockERC20 {
    // solhint-disable-next-line no-empty-blocks
    constructor() MockERC20("TokenB", "TKB", 18, 1_000_000_000_000 * 1e18) {}
}

contract MockUSDC is MockERC20 {
    // solhint-disable-next-line no-empty-blocks
    constructor() MockERC20("mockUSDC", "mUSDC", 6, 1_000_000_000_000 * 1e6) {}
}
