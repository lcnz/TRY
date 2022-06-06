// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TryKitty
 * @dev Contract for NFT Kitty lottery collectibles
 */
contract TryKitty is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address lotteryOwner;
    address tryLottery;

    //Mapping kitty classess to tokenid
    mapping(uint => uint256) classes;
    //Mapping tokenId to description like a Pokedex (to catalog and provide information regarding the various species of Kitty)
    mapping(uint => string) KittyDex;

    modifier onlyTryLottery {
        require(msg.sender == tryLottery, "only the lottery can use this function");
        _;
    }

    constructor(address operator) ERC721("TryKitty", "TKTY") {
        lotteryOwner = operator;
        tryLottery = msg.sender;
        _setApprovalForAll(lotteryOwner, tryLottery, true);
    }

    /**
    * @dev mints the token of the class being passed as an argument and assigne the token to the lottery operator
    */
    function safeMint(uint _class) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        classes[_class] = tokenId;
        KittyDex[tokenId] = string(abi.encodePacked("Faboulous Kitty of class: ", Strings.toString(_class)));

        _safeMint(lotteryOwner, tokenId);
    }

    /**
    * @dev retrieves from the map the token of the class passed as argument
    */
    function getTokenOfClassX(uint _class)public view returns(uint256){
        return classes[_class];
    }

    /**
    * @dev retrieves from the related map the description of the token with tokenId passed as argument
    */
    function checkDescription(uint256 ID)public view returns(string memory){
        return KittyDex[ID];
    }

    /**
    * @dev awards the lottery gambler the Kitty NFT
    */
    function awardItem(address player, uint256 tokendId) public onlyTryLottery {
        safeTransferFrom(lotteryOwner, player, tokendId);
    }
}
