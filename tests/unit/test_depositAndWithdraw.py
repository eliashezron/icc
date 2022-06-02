from scripts.deploy import deployWithdrawAndDeposit
from brownie import accounts, config, network, exceptions
from scripts.helpful_scripts import (
    get_account,
    get_contract,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)
from web3 import Web3
import pytest


def testDeposit():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for intergration testing testing!")
    account = get_account()
    account1 = get_account(index=1)
    account2 = get_account(index=2)
    account3 = get_account(index=3)

    depositAndWithraw, tokens = deployWithdrawAndDeposit()

    tokens[0].approve(
        depositAndWithraw.address, Web3.toWei(5, "ether"), {"from": account}
    )
    tx = depositAndWithraw.deposit(tokens[0], Web3.toWei(5, "ether"), {"from": account})
    tx.wait(1)
    assert depositAndWithraw.contractTokenBalances(tokens[0]) == Web3.toWei(5, "ether")
    assert tokens[0].balanceOf(depositAndWithraw.address) == Web3.toWei(5, "ether")
    assert depositAndWithraw.alreadyUser(account.address) == True
    with pytest.raises(exceptions.VirtualMachineError):
        depositAndWithraw.addAllowedTokens(tokens[1], {"from": account1})
    return depositAndWithraw, tokens, account, account1, account2


def test_Withdraw():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    account1 = get_account(index=1)
    account2 = get_account(index=2)
    account3 = get_account(index=3)

    depositAndWithraw, tokens = deployWithdrawAndDeposit()
    assert tokens[0].balanceOf(account1.address) == 0
    assert tokens[0].balanceOf(account.address) == tokens[0].totalSupply()
    tokens[0].transfer(account1.address, Web3.toWei(10, "ether"), {"from": account})
    assert tokens[0].balanceOf(account1.address) == Web3.toWei(10, "ether")
    assert tokens[0].balanceOf(account.address) == tokens[0].totalSupply() - Web3.toWei(
        10, "ether"
    )
    tokens[0].approve(
        depositAndWithraw.address, Web3.toWei(5, "ether"), {"from": account1}
    )
    tx = depositAndWithraw.deposit(
        tokens[0], Web3.toWei(5, "ether"), {"from": account1}
    )
    tx.wait(1)
    assert depositAndWithraw.contractTokenBalances(tokens[0]) == Web3.toWei(5, "ether")
    assert tokens[0].balanceOf(depositAndWithraw.address) == Web3.toWei(5, "ether")
    assert depositAndWithraw.alreadyUser(account1.address) == True
    with pytest.raises(exceptions.VirtualMachineError):
        depositAndWithraw.addAllowedTokens(tokens[1], {"from": account1})
    assert tokens[0].balanceOf(account1.address) == Web3.toWei(5, "ether")
    with pytest.raises(exceptions.VirtualMachineError):
        depositAndWithraw.withdraw(
            account2.address, tokens[0], Web3.toWei(10, "ether"), {"from": account}
        )
    depositAndWithraw.withdraw(
        account2.address, tokens[0], Web3.toWei(3, "ether"), {"from": account}
    )
    assert tokens[0].balanceOf(account2.address) == Web3.toWei(3, "ether")
    with pytest.raises(exceptions.VirtualMachineError):
        depositAndWithraw.withdraw(
            account2.address, tokens[0], Web3.toWei(3, "ether"), {"from": account1}
        )
