// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact contact@qfstoken.io
contract QFSToken is ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant LAUNCH_ROLE = keccak256("LAUNCHER_ROLE");

    uint8 constant DECIMALS = 18;
    uint256 public maxSupply = 1_000_000_000  * 10**DECIMALS;
    
    bool Launched = false;

    event enableTradingEvent(bool isTrading);

    constructor()
        ERC20("QFSToken", "$QFS") ERC20Permit("QFSToken")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _mint(msg.sender, 200_000_000 * 10**DECIMALS);
    }

    function claimStuckTokens(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        ERC20 ERC20token = ERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    receive() external payable {
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        public override returns (bool) {

        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()) - amount
        );

        return _customTransferFrom(sender, recipient, amount);
    }

    function transfer(
        address recipient,
        uint256 amount) 
        public virtual override returns (bool){

        return _customTransferFrom(_msgSender(), recipient, amount);
    }

       function _customTransferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        internal returns (bool) {

        require(Launched || hasRole(LAUNCH_ROLE, sender), "Project is not launched");
        
        super._transfer(sender, recipient, amount);
        return true;

        }

    function launch() public onlyRole(DEFAULT_ADMIN_ROLE) {
       require(!Launched,  "Project is already launched");
       Launched = true;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(maxSupply >= (amount + totalSupply()), "Cannot mint more tokens" );
        _mint(to, amount);
    }
}
