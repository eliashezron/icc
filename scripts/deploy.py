from brownie import config, network, DepositAndWithdraw
from scripts.helpful_scripts import get_account, get_contract
import yaml
import json
import os
import shutil


def deployWithdrawAndDeposit(front_end_update=True):
    account = get_account()
    depositAndWithraw = DepositAndWithdraw.deploy(
        {"from": account, "gas": 2000000},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print("contract deployed to ", depositAndWithraw.address)

    weth = get_contract("eth_token")
    icc = get_contract("icc_token")
    busd = get_contract("busd_token")
    bnb = get_contract("bnb_token")

    tokens = (weth, icc, busd, bnb)

    addAllowedTokens(tokens, depositAndWithraw, account)
    if front_end_update:
        update_front_end()

    return depositAndWithraw, tokens


def addAllowedTokens(tokens, contract, account):
    for token in tokens:
        print("adding token", token)
        addtx = contract.addAllowedTokens(token, {"from": account})
        addtx.wait(1)
        print("token added:", token)
    return contract


def update_front_end():
    # Send the build folder
    copy_folders_to_front_end("./build", "./ethereum-boilerplate/src/chain-info")

    # Sending the front end our config in JSON format
    with open("brownie-config.yaml", "r") as brownie_config:
        config_dict = yaml.load(brownie_config, Loader=yaml.FullLoader)
        with open("./ethereum-boilerplate/src/brownie-config.json", "w") as brownie_config_json:
            json.dump(config_dict, brownie_config_json)
    print("Front end updated!")


def copy_folders_to_front_end(src, dest):
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


def main():
    deployWithdrawAndDeposit(front_end_update=True)
