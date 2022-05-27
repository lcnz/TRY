// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TryKitty is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;


    //Mapping classess(rank) to tokenid
    mapping(uint => uint256) classes;
    //Mapping tokenId to description like a Pokedex
    mapping(uint => string) KittyDex;

    constructor() ERC721("TryKitty", "TKTY") {}

    function safeMint(address to, uint class) public onlyOwner returns(uint256){
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        classes[class] = tokenId;
        KittyDex[tokenId] = string(abi.encodePacked("Faboulous Kitty of class ", Strings.toString(class)));

        _safeMint(to, tokenId);
        return tokenId;
    }

    function getTokenOfClassX(uint class)public view onlyOwner returns(uint256){
        return classes[class];
    }

    function checkTokenOfClassX(uint class)public view onlyOwner returns(uint256){
        return classes[class];
    }

    function awardItem(address owner, address player, uint256 tokendId) public onlyOwner{
        safeTransferFrom(owner, player, tokendId);
    }
}
