AbcCollectible:
Contracts Address: 0x50Df7F7CbdD33E3a02102Ad0dD4CA2D9917235d8 (goerli tesnet)

    - AbcCollectible is a type ERC721 (from OpenZepplin)
        - In order to able to create ABC collectibles
    - AbcCollectible is a type VRFConsumerBase (from ChainlinkVRF)
        - Throw an off chain call to get RNG for collectible creation
    - AbcCollectible is a type Ownable (from OpenZepplin) 
        - Provides basic control mechanisms

    User is able to create a random ERC721 token (using ChainlinkVRF for RNG)
    out of 3 possible collectible options: ABC = {"Alpha", "Beta", "Delta"} 
    In order to create a token, you will need to pay 0.01 ether.

    The contracts also has a MultiSigWallet functionality that allows owners to
    withdraw funds from the contract after authentication. The minimum amount of 
    signatures needed to verify a transaction is 1 ("MIN_SIGNATURES = 1"). The owner 
    of the contract (the one who deployed it) is able to add and remove owners. 
    Valid owners are able withdraw, deposit and sign pending withdrwal transactions 
    from other valid owners.

deploy_abc.py:
    - Allows contracts to be deployed ad properly funded with LINK

create_abc.py/multiSigFunc.py:
    - testing scripts 

helpful_scripts.py: 
    - Auxiliary scripts

Environment Variables:

    - PRIVATE_KEY : developers key
    - PRIVATE_KEY2 : test key
    - WEB3_INFURA_PROJECT_ID : infura api key
    - ETHERSCAN_TOKEN : etherscan api key


    
