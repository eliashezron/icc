// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepositAndWithdraw is Ownable {
    struct User {
        address userAddress;
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
        return IERC20(_tokenAddress).balanceOf(msg.sender);
    }

    function deposit(address _token, uint256 _amount) public payable {
        require(_amount > 0, "Deposit an amount greater than 0");
        require(
            balanceOfToken(_token) >= _amount,
            "insufficient tokens available in your wallet"
        );
        require(tokenIsAllowed(_token), "token is not allowed to be deposited");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] += _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        if (alreadyUser[msg.sender]) {
            for (uint256 i = 0; i < users.length; i++) {
                if (users[i].userAddress == msg.sender) {
                    if (users[i].tokenBalances[_token][msg.sender] <= 0) {
                        uint256 numberOfTokens = users[i].uniqueTokensDeposited[
                            _token
                        ] += 1;
                        emit tokenAdded(msg.sender, numberOfTokens);
                        uint256 tokenBalance = users[i].tokenBalances[_token][
                            msg.sender
                        ] += _amount;

                        emit tokenBalanceOf(msg.sender, _token, tokenBalance);
                        break;
                    }
                    users[i].uniqueTokensDeposited[_token] += 1;
                    users[i].tokenBalances[_token][msg.sender] += _amount;
                    break;
                }
            }
        }
        User storage u = users.push();
        u.userAddress = msg.sender;
        u.uniqueTokensDeposited[_token] += 1;
        u.tokenBalances[_token][msg.sender] += _amount;
        alreadyUser[msg.sender] = true;
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
        require(tokenIsAllowed(_token), "token is not allowed to be withdrawn");
        IERC20(_token).transfer(_withdrawAddress, _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] -= _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
    }
}
