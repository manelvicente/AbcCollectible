from brownie import AbcCollectible, accounts, config, interface, network, web3
import os
import time

NON_FORKED_LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["hardhat", "development", "ganache"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = NON_FORKED_LOCAL_BLOCKCHAIN_ENVIRONMENTS + [
    "mainnet-fork",
    "binance-fork",
    "matic-fork",
]

def fund_with_link(
    contract_address, link_token=None, amount=100000000000000000
):
    """
    Funding a given contract with LINK
    Parameters:
    contract_address(string): Contract address thats is going to be funded
    account(string): account address that is going to be used to fund account
    link_token(string): LINK token address 
    amount(int): Amount in wei that is going to fund account (default = 1 LINK)
    """
    account = accounts.add(config["wallets"]["from_key"]) # Gets the Address that will fund the contract 
    tx = interface.LinkTokenInterface(link_token).transfer(
        contract_address, amount, {"from": account}
    ) # References LINK token ABI in order to fund the contract
    print(f"Funded {contract_address}")
    return tx

def get_publish_source():
    """
    Confirms if active network is compatible and checks if Etherscan token is defined
    for usage.
    Returns: 
    Boolean: A boolean to confirm if criteria is reached
    """
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS or not os.getenv(
        "ETHERSCAN_TOKEN"
    ):
        return False
    else:
        return True

def listen_for_event(brownie_contract, event, timeout=200, poll_interval=2):
    """
    Listen for an event to be fired from a contract.
    Parameters:
        brownie_contract (brownie.network.contract.ProjectContract):
        A brownie contract of some kind.
        event (string): The event you'd like to listen for.
        timeout (int): The max amount in seconds you'd like to
        wait for that event to fire. Defaults to 200 seconds.
        poll_interval (int): How often to call your node to check for events.
        Defaults to 2 seconds.
    """
    web3_contract = web3.eth.contract(
        address=brownie_contract.address, abi=brownie_contract.abi
    )
    start_time = time.time()
    current_time = time.time()
    event_filter = web3_contract.events[event].createFilter(fromBlock="latest")
    while current_time - start_time < timeout:
        for event_response in event_filter.get_new_entries():
            if event in event_response.event:
                print("Found event!")
                return event_response
        time.sleep(poll_interval)
        current_time = time.time()
    print("Timeout reached, no event found.")
    return {"event": None}

def get_letter(letter_number):
    """
    Gets letter associated with index number 0, 1 or 2
    Returns:
    String: Type of Letter
    """
    switch = {0: "ALPHA", 1: "BETA", 2: "DELTA"}
    return switch[letter_number]