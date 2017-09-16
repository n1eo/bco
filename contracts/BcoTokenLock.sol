pragma solidity ^0.4.11;

import "./token/FreezableToken.sol";
import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";

contract BcoTokenLock is Ownable {
    using SafeMath for uint256;

    // @dev How many investors we have now
    uint256 public investorCount;
    // @dev How many tokens investors have claimed so far
    uint256 public totalClaimed;
    // @dev How many tokens our internal book keeping tells us to have at the time of lock() when all investor data has been loaded
    uint256 public tokensAllocatedTotal;

    // must hold as much as tokens
    uint256 public tokensAtLeastHold;

    struct balance{
        address investor;
        uint256 amount;
        uint256 freezeEndAt;
        bool claimed;
    }

    mapping(address => balance[]) public balances;
    // @dev How many tokens investors have claimed
    mapping(address => uint256) public claimed;

    // @dev token
    FreezableToken public token;

    // @dev We allocated tokens for investor
    event Invested(address investor, uint256 amount, uint256 hour);

    // @dev We distributed tokens to an investor
    event Distributed(address investors, uint256 count);

    /**
     * @dev Create contract where lock up period is given days
     *
     * @param _owner Who can load investor data and lock
     * @param _token Token contract address we are distributing
     *
     */
    function BcoTokenLock(address _owner, address _token) {
        require(_owner != 0x0);
        require(_token != 0x0);

        owner = _owner;
        token = FreezableToken(_token);
    }

    // @dev Add investor
    function addInvestor(address investor, uint256 _amount, uint256 hour) public onlyOwner {
        require(investor != 0x0);
        require(_amount > 0); // No empty buys

        uint256 amount = _amount *(10**token.decimals());
        if(balances[investor].length == 0) {
            investorCount++;
        }

        balances[investor].push(balance(investor, amount, now + hour*60*60, false));
        tokensAllocatedTotal += amount;
        tokensAtLeastHold += amount;
        // Do not lock if the given tokens are not on this contract
        require(token.balanceOf(address(this)) >= tokensAtLeastHold);

        Invested(investor, amount, hour);
    }

    // @dev can only withdraw rest of investor's tokens
    function withdrawLeftTokens() onlyOwner {
        token.transfer(owner, token.balanceOf(address(this))-tokensAtLeastHold);
    }

    // @dev Get the current balance of tokens
    // @return uint256 How many tokens there are currently
    function getBalance() public constant returns (uint256) {
        return token.balanceOf(address(this));
    }

    // @dev Claim N bought tokens to the investor as the msg sender
    function claim() {
        withdraw(msg.sender);
    }

    function withdraw(address investor) internal {
        require(balances[investor].length > 0);

        uint256 nowTS = now;
        uint256 withdrawTotal;
        for (uint i = 0; i < balances[investor].length; i++){
            if(balances[investor][i].claimed){
                continue;
            }
            if(nowTS<balances[investor][i].freezeEndAt){
                continue;
            }

            balances[investor][i].claimed=true;
            withdrawTotal += balances[investor][i].amount;
        }

        claimed[investor] += withdrawTotal;
        totalClaimed += withdrawTotal;
        token.transfer(investor, withdrawTotal);
        tokensAtLeastHold -= withdrawTotal;
        require(token.balanceOf(address(this)) >= tokensAtLeastHold);

        Distributed(investor, withdrawTotal);
    }
}