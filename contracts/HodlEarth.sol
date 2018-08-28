pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

/***
*
* need to add pausable when minting need to check that it doesnt exist first
* need to allow the minter to attribute up to X tokens
*/
contract HodlEarthToken is ERC721Token, Ownable, Pausable {
  string public constant name = "HodlEarthToken";
  string public constant symbol = "HEAR";

  constructor() ERC721Token(name, symbol) public {
    owner = msg.sender;
  }

  mapping (uint256 => bytes7) public plotColours;
  mapping (uint256 => bytes32) public plotDescriptors;

  function calculatePlotPrice() public view returns(uint256 currentPlotPrice){

    if(totalSupply() < 250000){
        currentPlotPrice = 0.0004 * 1000000000000000000;
    } else currentPlotPrice = 0.001 * 1000000000000000000;

  }

  function calculateTransactionFee(uint256 noPlots,bool updatePlot) public view returns(uint256 fee){

    uint256 plotPrice;
    plotPrice = calculatePlotPrice();
    fee = plotPrice.div(10);
    fee = fee.mul(noPlots);

    if(updatePlot == false){

       uint256 minFee = 0.001 * 1000000000000000000;
       if(fee < minFee) fee = minFee;
       else fee = fee + minFee;

    }

  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused{

    super.transferFrom(_from,_to,_tokenId);

  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused{

    super.safeTransferFrom(_from,_to,_tokenId);

  }

  function safeTransferFrom(address _from,address _to,uint256 _tokenId,bytes _data) public whenNotPaused{

    super.safeTransferFrom(_from,_to,_tokenId,_data);

  }

  function getPlot(uint256 _plotLat,uint256 _plotLng) public view returns(uint256 plotReference,bytes7 colour,bytes32 descriptor){

    plotReference = _generatePlotReference(_plotLat,_plotLng);
    colour = plotColours[plotReference];
    descriptor = plotDescriptors[plotReference];

  }

  function getPlotByReference(uint256 _plotReference) public view returns(bytes7 colour,bytes32 descriptor){

    colour = plotColours[_plotReference];
    descriptor = plotDescriptors[_plotReference];

  }


  function getPlots(uint256[] _plotLats,uint256[] _plotLngs) public view returns(uint256[],bytes7[],bytes32[]){

    uint arrayLength = _plotLats.length;
    uint256 plotReference;
    uint256[] memory plotIds = new uint[](arrayLength);
    bytes7[] memory colours = new bytes7[](arrayLength);
    bytes32[] memory descriptors = new bytes32[](arrayLength);
    for (uint i=0; i<arrayLength; i++) {
      plotReference = _generatePlotReference(_plotLats[i],_plotLngs[i]);
      plotIds[i] = plotReference;
      colours[i] =  plotColours[plotReference];
      descriptors[i] = plotDescriptors[plotReference];

    }

    return(plotIds,colours,descriptors);
  }


  function getPlotsByReference(uint256[] _plotReferences) public view returns(uint256[],bytes7[],bytes32[]){

    uint arrayLength = _plotReferences.length;
    uint256[] memory plotIds = new uint[](arrayLength);
    bytes7[] memory colours = new bytes7[](arrayLength);
    bytes32[] memory descriptors = new bytes32[](arrayLength);
    for (uint i=0; i<arrayLength; i++) {
      plotIds[i] = _plotReferences[i];
      colours[i] =  plotColours[_plotReferences[i]];
      descriptors[i] = plotDescriptors[_plotReferences[i]];
    }

    return(plotIds,colours,descriptors);
  }


  function newPlot(uint256 _plotLat,uint256 _plotLng,bytes7 _colour,bytes32 _title) public payable whenNotPaused{

    uint256 plotReference;
    bool validLatLng;
    uint256 plotPrice;
    uint256 transactionFee;

    //check the amount sent
    transactionFee = calculateTransactionFee(1,false);
    if(msg.sender != owner){
        require(
            msg.value >= plotPrice + transactionFee,
            "Insufficient Eth sent."
        );
    }

    validLatLng = validatePlotLatLng(_plotLat,_plotLng);
    require(
        validLatLng == true,
        "Lat long is invalid"
    );
    plotReference = _generatePlotReference(_plotLat,_plotLng);
    require(
       plotColours[plotReference] == 0,
      "Plot already exists."
    );
    _addPlot(plotReference,_colour,_title);

  }
  function newPlots(uint256[] _plotLat,uint256[] _plotLng,bytes7[] _colours,bytes32[] _descriptors) public payable whenNotPaused{

    uint256 noPlots = _plotLat.length;
    bytes7 colour;
    bytes32 descriptor;
    uint256 plotReference;
    bool validLatLng;
    uint256 plotPrice;
    uint256 transactionFee;

    plotPrice = calculatePlotPrice();
    transactionFee = calculateTransactionFee(noPlots,false);

    if(msg.sender != owner){
      require(
        msg.value >= plotPrice.mul(noPlots) + transactionFee,
        "Insufficient Eth sent."
      );
    }

    for (uint i=0; i<noPlots; i++) {
        colour =  _colours[i];
        descriptor = _descriptors[i];
        validLatLng = validatePlotLatLng(_plotLat[i],_plotLng[i]);
        require(
           validLatLng == true,
           "Lat long is invalid"
        );
        plotReference = _generatePlotReference(_plotLat[i],_plotLng[i]);
        require(
           plotColours[plotReference] == 0,
          "Plot already exists."
        );
        _addPlot(plotReference,colour,descriptor);
    }

  }

  function _generatePlotReference(uint256 _plotLat,uint256 _plotLng) internal pure returns(uint256 plotReference){

    plotReference = (_plotLat * 10000000000) + _plotLng;

  }

  function _addPlot(uint256 _plotReference,bytes7 _colour,bytes32 _descriptor) private{

    //check that the plotreference does not already exist
    plotColours[_plotReference] =  _colour;
    plotDescriptors[_plotReference] =  _descriptor;
    _mint(msg.sender, _plotReference);
  }

  function validatePlotLatLng(uint256 _lat,uint256 _lng) public pure returns(bool){
    //confirm the lat and long conforms to the hodlearth dimensions
    if(_lat%5 == 0 && _lng%8 == 0) return true;
    return false;
  }

  function updatePlot(uint256 _plotLat,uint256 _plotLng,bytes7 _colour,bytes32 _descriptor) public payable whenNotPaused{

    uint256 plotReference;
    uint256 transactionFee;

    plotReference = _generatePlotReference(_plotLat,_plotLng);
    transactionFee = calculateTransactionFee(1,true);

    if(msg.sender != owner){
      require(
      msg.value >= transactionFee,
          "Insufficient Eth sent."
      );
    }
    require(
      plotColours[plotReference] != 0,
      "Plot does not exist."
    );
    require(
      ownerOf(plotReference) == msg.sender,
      "Update can only be carried out by the plot owner."
    );

    plotColours[plotReference] =  _colour;
    plotDescriptors[plotReference] = _descriptor;
  }

  function updatePlots(uint256[] _plotLat,uint256[] _plotLng,bytes7[] _colours,bytes32[] _descriptors) public payable whenNotPaused{

    uint256 noPlots = _plotLat.length;
    bytes7 colour;
    bytes32 descriptor;
    uint256 plotReference;
    uint256 transactionFee;

    transactionFee = calculateTransactionFee(noPlots,true);

    if(msg.sender != owner){
      require(
      msg.value >= transactionFee,
          "Insufficient Eth sent."
      );
    }

    for (uint i=0; i<noPlots; i++) {
        colour =  _colours[i];
        descriptor = _descriptors[i];
        plotReference = _generatePlotReference(_plotLat[i],_plotLng[i]);
        require(
            plotColours[plotReference] != 0,
            "Plot does not exist."
        );
        require(
            ownerOf(plotReference) == msg.sender,
            "Update can only be carried out by the plot owner."
        );


        plotColours[plotReference] =  colour;
        plotDescriptors[plotReference] = descriptor;
    }
  }

  function withdraw() public onlyOwner returns(bool) {
     owner.transfer(address(this).balance);
     return true;
  }

}