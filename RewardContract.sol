// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RewardContract is ERC1155, Ownable, ReentrancyGuard, ERC1155Supply {

    uint public rewardId;
    uint public idsCount;
    string public name;
    string public symbol;
    string public baseUri;
    bool public mintEnabled;

    
    mapping(address => bool) public whitelistedAddresses;

    error AmountMustBeAboveZero();
    error NotWhitelistedAddress();
    error AddressIsAlreadyWhitelisted();
    error MintingDisabled();
    error TokenIdNotExists();
    error TokenIdAlreadyExists();
    
    event MintStatusUpdated(
        bool status,
        address updatedBy
    );
    
    event SingleRewardMintedBy(
        uint rewardId,
        uint quantity,
        address mintedTo
    );

    event BulkRewardsOfSinglePlayerMintedBy(
        uint[] rewardIds,
        uint[] quantities,
        address mintedTo 
    );

    event BulkRewardsOfMultiplePlayersMintedBy(
        uint[] rewardIds,
        uint[] quantities,
        address[] mintedTo 
    );

    event DroneRewardUpdatedBy(
        uint rewardId,
        uint quantity,
        address updatedBy  
    );

    event SetBaseURI(
        string baseURI,
        address setBy
    );

    event AddedWhitelistAddress(
        address whitelistedAddress,
        address addedBy
    );

    event RemovedWhitelistAddress(
        address whitelistedAddress,
        address removeBy
    );

    constructor() ERC1155("") {
        name = "Drone Mania";
        symbol = "DM";
        baseUri = "https://bafybeihul6zsmbzyrgmjth3ynkmchepyvyhcwecn2yxc57ppqgpvr35zsq.ipfs.dweb.link/";
        
        mintEnabled = true;
        whitelistedAddresses[msg.sender] = true;
        emit SetBaseURI(baseUri, msg.sender);
    }

    modifier isWhitelisted() {
        if (!whitelistedAddresses[msg.sender]) {
            revert NotWhitelistedAddress();
        }
        _;   
    }

    function updateMintStatus(bool _status) 
    external 
    onlyOwner {
        mintEnabled = _status;

        emit MintStatusUpdated(_status, msg.sender);
    }

    /**
     * @dev addWhitelistedAddress is used to add address in whitelist mapping.
     *
     * Requirement:
     *
     * - This function can only called by owner of contract
     *
     * @param whitelistAddress - New whitelist address
     *
     * Emits a {AddedWhitelistAddress} event.
    */

    function addWhitelistedAddress(address whitelistAddress)
    external
    onlyOwner
    nonReentrant {
        if(whitelistedAddresses[whitelistAddress]){
            revert AddressIsAlreadyWhitelisted();
        }
        whitelistedAddresses[whitelistAddress] = true;

        emit AddedWhitelistAddress(whitelistAddress, msg.sender);
    }

    /**
     * @dev removeWhitelistedAddress is used to remove address from whitelist mapping.
     *
     * Requirement:
     *
     * - This function can only called by owner of contract
     *
     * @param whitelistAddress - Remove whitelist address
     *
     * Emits a {RemovedWhitelistAddress} event.
    */

    function removeWhitelistedAddress(address whitelistAddress)
    external
    onlyOwner
    nonReentrant {
        if(!whitelistedAddresses[whitelistAddress]){
            revert NotWhitelistedAddress();
        }

        whitelistedAddresses[whitelistAddress] = false;

        emit RemovedWhitelistAddress(whitelistAddress, msg.sender);
    }

    /**
     * @dev setBaseUri is used to set BaseURI.
     * Requirement:
     * - This function can only called by owner of contract
     *
     * @param _baseUri - New baseURI
     * Emits a {UpdatedBaseURI} event.
    */

    function updateBaseUri(
        string memory _baseUri
    ) external
      onlyOwner 
    {
        baseUri = _baseUri;
        
        emit SetBaseURI(baseUri, msg.sender);
    }

    /**
     * @dev mintSingleReward is used to create a new Reward.
     * Requirement:
     *
     * @param id - id to mint
     * @param amount - Reward Copy to mint
     * @param account - address to
     *
     * Emits a {SingleRewardMintedBy} event.
    */

    function mintSingleReward(
        uint256 id,
        uint256 amount,
        address account
    ) public
      isWhitelisted
      nonReentrant
      returns(uint)
    {
        if(!mintEnabled){
          revert MintingDisabled();
        }

        if (amount <= 0) {
          revert AmountMustBeAboveZero();
        }

        if(exists(id)){
            revert TokenIdAlreadyExists();
        }
        
        idsCount += id; 
       _mint(account, id, amount, "");

       emit SingleRewardMintedBy(id, amount, account);        
       return id;

    }

    /**
     * @dev mintBulkRewardsOfSinglePlayer is used to create a Bulk Rewards of single player.

     * Requirement:

     * @param ids - ids to mint
     * @param amounts - Copies of reward that have to send
     * @param account - address to
     *
     * Emits a {BulkRewardsOfSinglePlayerMintedBy} event.
    */

    function mintBulkRewardsOfSinglePlayer(
        uint256[] memory ids,
        uint256[] memory amounts,
        address account
    ) public
      isWhitelisted
    {
        if(!mintEnabled){
           revert MintingDisabled();
        }
        for(uint i=0; i<ids.length; i++){
            if(exists(ids[i])){
                revert TokenIdAlreadyExists();
            }
            if (amounts[i] <= 0) {
                revert AmountMustBeAboveZero();
            } 
        }
       idsCount += ids.length; 
      _mintBatch(account, ids, amounts, "");

      emit BulkRewardsOfSinglePlayerMintedBy(ids, amounts, account);
    }

    /**
     * @dev mintBulkRewardsOfMultiplePlayers is used to create a Bulk Rewards of Multiple player.

     * Requirement:

     * @param ids - ids to mint
     * @param amounts - Copies of reward that have to send
     * @param accounts - address to
     *
     * Emits a {BulkRewardsOfMultiplePlayersMintedBy} event.
    */

    function mintBulkRewardsOfMultiplePlayers(
        uint[] memory ids,
        address[] memory accounts,
        uint256[] memory amounts
    ) public
      isWhitelisted
      nonReentrant
      returns(uint[] memory)
    {
        if(!mintEnabled){
          revert MintingDisabled();
        }
        for(uint i=0; i<ids.length; i++){
            if(exists(ids[i])){
                revert TokenIdAlreadyExists();
            }
            if (amounts[i] <= 0) {
                revert AmountMustBeAboveZero();
            } 
        }
         require(ids.length == accounts.length,"Amount of ids is equal to the amount of addressess");
        idsCount += ids.length;
        for(uint i=0; i<accounts.length; i++){
            _mint(accounts[i], ids[i], amounts[i], "");
        }
       
       emit BulkRewardsOfMultiplePlayersMintedBy(ids, amounts, accounts);

       return ids;
    }

    /**
     * @dev increaseDroneRewardItem is used to create a new Drone Reward.
     *
     * Requirement:
     *
     * @param account - address to
     * @param id - reward id
     * @param amount - amounts of token to mint
     *
     * Emits a {DroneRewardUpdatedBy} event.
    */

    function increaseDroneRewardItem(
        address account,
        uint id,
        uint256 amount
    ) public
      isWhitelisted
      nonReentrant
    {
        if(!mintEnabled){
           revert MintingDisabled();
        }

        if (amount <= 0) {
           revert AmountMustBeAboveZero();
        } 

         if(!exists(id)){
            revert TokenIdNotExists();
        }
       
       _mint(account, id, amount, "");

       emit DroneRewardUpdatedBy(id, amount, account);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev uri is used to get the uri by token ID.
     *
     * Requirement:
     *
     * @param _tokenId - tokenId 
    */

    function uri(uint256 _tokenId)  public override view returns (string memory){
        if(!exists(_tokenId)){
            revert TokenIdNotExists();
        }     
        return string(
         abi.encodePacked(
              baseUri,
              Strings.toString(_tokenId),
              ".json"
            )
        );
    }
 
    /**
     * @dev getRewardByAddress is used to get information of all Rewards hold by the player address.
     * Requirement:
     *
     * @param playerAddress - playerAddress 
    */

    function getRewardsByAddress(address playerAddress)
    external
    view
    returns(uint[] memory){
        uint count;
        uint countAgain;
        uint[] memory totalItemCount = new uint[](idsCount);
        
        for (uint i = 1; i <= idsCount; i++){
            if(balanceOf(playerAddress,i) > 0 ){   
                totalItemCount[count] = balanceOf(playerAddress,i);
                count++;
            } 
        }
        uint[] memory totalItemToReturn = new uint[](count);
        for (uint i = 1; i <= idsCount; i++){
            if(balanceOf(playerAddress,i) > 0 ){    
                totalItemToReturn[countAgain] = balanceOf(playerAddress,i);
                countAgain++;
            }    
        }

      return totalItemToReturn;
    }
}
