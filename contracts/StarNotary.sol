// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract StarNotary is ERC721 {
    struct Star {
        string name;
    }

    mapping(uint256 => uint256) public plannedExchanges;
    mapping(uint256 => Star) public tokenIdToStarInfo;
    mapping(uint256 => uint256) public starsForSale;

    constructor() ERC721("StarNotary", "STAR") {

    }

    // Create Star using the Struct
    function createStar(string memory _name, uint256 _tokenId) public {// Passing the name and tokenId as a parameters
        Star memory newStar = Star(_name);
        // Star is an struct so we are creating a new Star
        tokenIdToStarInfo[_tokenId] = newStar;
        // Creating in memory the Star -> tokenId mapping
        _mint(msg.sender, _tokenId);
        // _mint assign the the star with _tokenId to the sender address (ownership)
    }

    // Putting an Star for sale (Adding the star tokenid into the mapping starsForSale, first verify that the sender is the owner)
    function putStarUpForSale(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == msg.sender, "You can't sale the Star you don't owned");
        starsForSale[_tokenId] = _price;
    }

    function buyStar(uint256 _tokenId) public payable {
        require(starsForSale[_tokenId] > 0, "The Star should be up for sale");
        uint256 starCost = starsForSale[_tokenId];
        address ownerAddress = ownerOf(_tokenId);
        require(msg.value > starCost, "You need to have enough Ether");
        _transfer(ownerAddress, msg.sender, _tokenId);
        // We can't use _addTokenTo or_removeTokenFrom functions, now we have to use _transferFrom
        address payable ownerAddressPayable = payable(ownerAddress);
        // We need to make this conversion to be able to use transfer() function to transfer ethers
        ownerAddressPayable.transfer(starCost);

        payable(msg.sender).transfer(msg.value - starCost);
    }

    //The stuff for the project:
    function lookUpTokenIdToStarInfo(uint256 _tokenId) public view returns (string memory) {
        if (bytes(tokenIdToStarInfo[_tokenId].name).length == 0) {
            return "";
        }
        return tokenIdToStarInfo[_tokenId].name;
    }

    //Step 1: Person A marks their star A as "to be exchanged with star B"
    //Step 2: Person B exchanges their star B with star A (which only works after step 1)
    function exchangeStars(uint256 _yourTokenId, uint256 _otherTokenId) public {
        require(bytes(tokenIdToStarInfo[_yourTokenId].name).length != 0, "Your star has to exist");
        require(bytes(tokenIdToStarInfo[_otherTokenId].name).length != 0, "The other star has to exist");
        require(ownerOf(_yourTokenId) == msg.sender, "You can only trade your own stars");

        if (plannedExchanges[_otherTokenId] == _yourTokenId) {
            //exchange the stars
            address other = ownerOf(_otherTokenId);
            _transfer(msg.sender, other, _yourTokenId);
            _transfer(other, msg.sender, _otherTokenId);

            //remove from plannedExchanges
            plannedExchanges[_otherTokenId] = 0;
            plannedExchanges[_yourTokenId] = 0;
        } else {
            plannedExchanges[_yourTokenId] = _otherTokenId;
        }
    }

    function cancelExchange(uint256 _yourTokenId) public {
        require(ownerOf(_yourTokenId) == msg.sender, "You can only manage your own stars");
        plannedExchanges[_yourTokenId] = 0;
    }

    function transferStar(address receiver, uint256 _yourTokenId) public {
        require(ownerOf(_yourTokenId) == msg.sender, "You can only trade your own stars");
        _transfer(msg.sender, receiver, _yourTokenId);
    }
}