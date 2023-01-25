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
    transaction = abc_collectible.createCollectible("None", {"value": 10000000000000000, "from": test})
    print("Waiting for second transaction...")
    transaction.wait(1)
    listen_for_event(abc_collectible, "ReturnedCollectible", timeout=200, poll_interval=10)
    requestId = transaction.events["RequestedCollectible"]["requestId"]
    token_id = abc_collectible.requestIdToTokenId(requestId)
    letter = get_letter(abc_collectible.tokenIdToLetter(token_id))
    print("Letter type of tokenId {} is {}".format(token_id, letter))