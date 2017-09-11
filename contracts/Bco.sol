pragma solidity ^0.4.11;

import "./ownership/Claimable.sol";
import "./ownership/Contactable.sol";
import "./ownership/HasNoEther.sol";
import "./token/FreezableToken.sol";

/**
 * @title Bco
 * @dev The Bco contract is Claimable, and provides ERC20 standard token.
 */
contract Bco is Claimable, Contactable, HasNoEther, FreezableToken {
    // @dev Constructor initial token info
    function Bco(){
        uint256 _decimals = 18;
        uint256 _supply = 1000000000*(10**_decimals);

        _totalSupply = _supply;
        balances[msg.sender] = _supply;
        name = "BitConch Coin";
        symbol = "BCO";
        decimals = _decimals;
        contactInformation = "BCO contact information";
    }
}
