// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interfaces
import "./IStakeableNFT.sol";



 
/**
 * @notice This contract is used by borrowers to call Dapp functions (using delegate calls).
 * @notice This contract should only be constructed using it's upgradeable Proxy contract.
 * @notice In order to call a Dapp function, the Dapp must be added in the DappRegistry instance.
 *
 * @author develop@teller.finance
 */
contract TellerNFTDictionary is   IStakeableNFT, ERC721Upgradeable, AccessControlUpgradeable  {
     
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
     

     struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    } 

    mapping(uint256 => uint256) internal _baseLoanSizes;
    mapping(uint256 => string[]) internal _hashes;
    mapping(uint256 => address) internal _contributionAsset;
    mapping(uint256 => uint256) internal _contributionSize;
    mapping(uint256 => uint8) internal _contributionMultiplier;

 


    /* Constants */

    bytes32 public constant ADMIN = keccak256("ADMIN");
 
 

    /* State Variables */
 
    // It holds the information about a tier.
    //mapping(uint256 => Tier) internal _tiers;

    // It holds which tier a token ID is in.
    //mapping(uint256 => uint256) internal _tokenTier;



    mapping(uint256 => uint256) public _tokenTierMappingCompressed;

   

    /* Modifiers */

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "TellerNFT: not admin");
        _;
    }

    constructor(  ){        
      _setupRole(ADMIN, msg.sender );

       //setAllTokenTierMappings(tiersMapping);
    }




   

    /* External Functions */

   
  /*  function getTier(uint256 index)
        external
        view
         
        returns (Tier memory tier_)
    {
        tier_ = _tiers[index];
    }*/

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function getTokenTierIndex(uint256 tokenId)
        public
        view
         
        returns (uint8 index_)
    { 

        //32 * 8 = 256 - each uint256 holds the data of 32 tokens . 8 bits each.  

        uint256 mappingIndex = tokenId.div(32);

        uint256 compressedRegister = _tokenTierMappingCompressed[mappingIndex];


        //use 31 instead of 32 to account for the '0x' in the start. 
        //the '31 -' reverses our bytes order which is necessary

        uint256 offset =  ((31 - tokenId.mod(32)).mul(8)); 

        uint8 tierIndex = uint8( (compressedRegister >> offset) ); 

        return tierIndex ;

    }

    function bitshiftTesting() public view returns (uint8){

        bytes32 testInput = 0x0021020100030201000302010003020100030201000302010003020100030201;

        uint256 indexToReturn = 2  ;

        return uint8(uint256(testInput >>  indexToReturn.mul(8))    );
    }

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getTierHashes(uint256 tierIndex)
        public
        view
         
        returns (string[] memory hashes_)
    {

      hashes_ = _hashes[tierIndex];
    } 

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTier(uint256 index, Tier memory newTier) 
    external 
    onlyAdmin {
       /* Tier storage tier = _tiers[index];

        tier.baseLoanSize = newTier.baseLoanSize;
        tier.hashes = newTier.hashes;
        tier.contributionAsset = newTier.contributionAsset;
        tier.contributionSize = newTier.contributionSize;
        tier.contributionMultiplier = newTier.contributionMultiplier;
         */
           
        _baseLoanSizes[index] = newTier.baseLoanSize;
        _hashes[index] = newTier.hashes;
        _contributionAsset[index] = newTier.contributionAsset;
        _contributionSize[index] = newTier.contributionSize;
        _contributionMultiplier[index] = newTier.contributionMultiplier;
         
    } 

    function setAllTokenTierMappings(uint256[] memory tiersMapping) 
    public 
    onlyAdmin {

        for(uint256 i=0; i< tiersMapping.length; i++){
            _tokenTierMappingCompressed[i] = tiersMapping[i];
        } 
         
    } 

    function setTokenTierMapping(uint256 index, uint256 tierMapping) 
    public 
    onlyAdmin {
         
      _tokenTierMappingCompressed[index] = tierMapping; 
         
    } 


    //Write a method that allows for setting a new tierindex of a new token
    function setSpecificTokenTierForTokenId(uint256 index, uint256 tokenTier)
    public 
    onlyAdmin
    {

    }


    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IStakeableNFT).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }
  

    /**
        New methods for the dictionary
    */


     /**
     * @notice It returns information about the type of NFT.     * 
     */
    function stakeableTokenType()
        public
        view    
        override   
        returns (bytes32)
    {  
        return keccak256('TellerNFTV1');
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function tokenBaseLoanSize(uint256 tokenId)
        public
        view    
        override   
        returns (uint256)
    {  
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return _baseLoanSizes[tokenTier];
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function tokenURIHash(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        string[] memory tierImageHashes = getTierHashes(tokenTier);
        return tierImageHashes[tokenId.mod(tierImageHashes.length)];
 
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function tokenContributionAsset(uint256 tokenId)
        public
        view  
        override     
        returns (address)
    {  
        uint8 tokenTier = getTokenTierIndex(tokenId);
    
        return _contributionAsset[tokenTier];
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function tokenContributionSize(uint256 tokenId)
        public
        view   
        override    
        returns (uint256)
    {  
        uint8 tokenTier = getTokenTierIndex(tokenId);
          
        return _contributionSize[tokenTier];
    }

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function tokenContributionMultiplier(uint256 tokenId)
        public
        view    
        override   
        returns (uint256)
    {  
        uint8 tokenTier = getTokenTierIndex(tokenId);
       
        return _contributionMultiplier[tokenTier];
    }


}
