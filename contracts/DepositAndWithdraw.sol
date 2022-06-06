// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DepositAndWithdraw is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public userCount;
    struct User {
        address userAddress;
        uint256 userId;
        mapping(address => uint256) uniqueTokensDeposited;
        mapping(address => mapping(address => uint256)) tokenBalances;
    }
    User[] public users;
    address[] public allowedTokensAddresses;
    mapping(address => uint256) public contractTokenBalances;
    mapping(address => bool) public alreadyUser;

    event tokenAdded(address indexed userAddress, uint256 numberOfTokens);
    event tokenBalanceOf(
        address indexed userAddress,
        address indexed tokenAddress,
        uint256 tokenBalance
    );
    event userAdded(address indexed userAddress);
    event contractTokenBalanceAdjusted(
        address indexed tokenAddress,
        uint256 tokenBalance
    );

    function balanceOfToken(address _tokenAddress)
        public
        view
        returns (uint256)

    {
        require(tokenIsAllowed(_tokenAddress));
        return IERC20(_tokenAddress).balanceOf(msg.sender);
    }

    function deposit(address _token, uint256 _amount) public payable {
        require(_amount > 0, "Deposit an amount greater than 0");
        require(
            balanceOfToken(_token) >= _amount,
            "insufficient tokens available in your wallet"
        );
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] += _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        if (alreadyUser[msg.sender]) {
            for (uint256 i = 0; i < users.length; i++) {
                    if (users[i].tokenBalances[_token][msg.sender] <= 0) {
                        uint256 numberOfTokens = users[i].uniqueTokensDeposited[
                            _token
                        ] += 1;
                        emit tokenAdded(msg.sender, numberOfTokens);
                    }
                    uint256 tokenBalance = users[i].tokenBalances[_token][
                      msg.sender
                    ] += _amount;
                    emit tokenBalanceOf(msg.sender, _token, tokenBalance);
            }
        }
        User storage u = users.push();
        u.userAddress = msg.sender;
        u.userId = userCount.current();
        u.uniqueTokensDeposited[_token] += 1;
        u.tokenBalances[_token][msg.sender] += _amount;
        alreadyUser[msg.sender] = true;
        userCount.increment();
        emit tokenAdded(msg.sender, 1);
        emit tokenBalanceOf(msg.sender, _token, _amount);
        emit userAdded(msg.sender);
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokensAddresses.push(_token);
    }
 
    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokensAddresses.length;
            allowedTokensIndex++
        ) {
            if (allowedTokensAddresses[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function withdraw(
        address _withdrawAddress,
        address _token,
        uint256 _amount
    ) public onlyOwner {
        require(_amount > 0, "Withdraw an amount greater than 0");
        require(
            balanceOfToken(_token) >= _amount,
            "insufficient tokens available in the contract"
        );
        IERC20(_token).transfer(_withdrawAddress, _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] -= _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
    }
}
