from brownie import AbcCollectible, accounts, network, config
from scripts.helpful_scripts import fund_with_link, get_publish_source

def main():
    dev = accounts.add(config['wallets']['from_key']) # Gets dev account
    print(network.show_active())
    publish_source = False; # Publich or not on etherscan
    abcCollectible = AbcCollectible.deploy(
        config["networks"][network.show_active()]["vrf_coordinator"],
        config["networks"][network.show_active()]["link_token"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": dev},
        publish_source=get_publish_source(),
    ) # Deploys contract
    fund_with_link(
        abcCollectible.address,
        config['networks'][network.show_active()]["link_token"]
    ) # Funds it with link
    return abcCollectible # Returns the contract

def fund_contract():
    """
    Funds latest Iteration of the Abc contract with LINK
    """
    abc_collectible = AbcCollectible[len(AbcCollectible) - 1] # Gets the most recently deployed contrcact of AbcCollectible
    fund_with_link(abc_collectible.address) # Funds it with link

