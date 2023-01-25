from brownie import AbcCollectible, accounts, config, network
from scripts.helpful_scripts import fund_with_link, listen_for_event, get_letter
import time

def main():
    dev = accounts.add(config['wallets']['from_key']) # Gets dev account
    test = accounts.add(config['wallets']['test_key']) # Gets test account
    abc_collectible = AbcCollectible[len(AbcCollectible) - 1] # Gets the most recently deployed contrcact of AdvancedCollectible
    """
    fund_with_link(
        abc_collectible.address,  
        config['networks'][network.show_active()]["link_token"]
    )
    """
    #transaction = abc_collectible.createCollectible("None", {"value": 10000000000000000, "from": dev})
    
    #transactionAddOwner = abc_collectible.addOwner(test, {"from": dev})
    #print("Address {} was added as a Valid Owner".format(test))
    
    #transactionRemoveOwner = abc_collectible.addOwner(test, {"from": dev})
    #print("Address {} was removed as a Valid Owner".format(test))

    #transactionDeposit = abc_collectible.deposit({"value": 1000000000000000, "from": test})
    #print("Address {} deposited 1000000000000000 wei".format(test))

    #transactionDeposit = abc_collectible.withdrawTo(dev, 1, {"gas": "10000000000", "from": dev})
    #print("Address {} initiated a transaction to withdraw 1000000000000000 wei".format(dev))