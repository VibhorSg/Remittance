pragma solidity ^ 0.4.21;

contract Remittance {

  uint constant deadLineLimit = 1000;

  address public owner;
  bool public isRunning;

  struct RemittanceContract {
    address contractOwner;
    address exchage;
    uint amount;
    uint endTime;
    bool claimed;
  }

  mapping(bytes32 => RemittanceContract) public remittances;

  event LogContractCreated(address indexed contractOwner, address indexed exchage, uint deadline, uint amount);
  event LogClaimed(address indexed contractOwner,address indexed exchage, uint amount);                         
  event LogReclaimed(address indexed contractOwner, uint amount);
  event LogPaused(address indexed owner);
  event LogResumed(address indexed owner);

  function Remittance( bool _running ) public {
    owner = msg.sender;
    isRunning = _running;
  }

  modifier onlyIfRunning {
    require(isRunning);
    _;
  }

  function createContract(bytes32 _puzzle, address _exchange, uint _duration) public onlyIfRunning payable
  returns(bool) {
    require(msg.value > 0);
    require(_exchange != address(0x00));
    require(_duration <= deadLineLimit);
    remittances[_puzzle] = RemittanceContract(msg.sender, _exchange, msg.value, _duration + block.number, false);
    emit LogContractCreated(msg.sender, _exchange, _duration + block.number, msg.value);
    return true;
  }

  function claim(bytes32 _recipienPassword, bytes32 _exchangePassword) public onlyIfRunning returns(bool) {
  require(_recipienPassword.length != 0);
  require( _exchangePassword.length != 0);
  RemittanceContract storage remittanceContract = remittances[keccak256(_recipienPassword , _exchangePassword)];
  require(remittanceContract.amount > 0); // Check reclaim contract is valid
  require(remittanceContract.exchage == msg.sender);
  uint amount = remittanceContract.amount;
  remittanceContract.amount = 0;
  emit LogClaimed(remittanceContract.contractOwner, msg.sender,  amount);
  msg.sender.transfer(amount);
  return true;
  }

  function reclaim(bytes32 _puzzle) public onlyIfRunning
  returns(bool) {
    require(msg.sender != address(0x00));
    RemittanceContract storage remittanceContract = remittances[_puzzle];
    require(remittanceContract.amount > 0); // Check reclaim contract is valid
    require(!remittanceContract.claimed);
    require(remittanceContract.contractOwner == msg.sender);
    require(remittanceContract.endTime > block.number);
    remittanceContract.claimed = true;
    emit LogReclaimed(msg.sender, remittanceContract.amount);
    msg.sender.transfer(remittanceContract.amount);
  }

  function pause() public onlyIfRunning returns(bool) {
    require(msg.sender == owner);
    emit LogPaused(owner);
    isRunning = false;
  }

  function resume() public returns(bool) {
    require(msg.sender == owner);
    emit LogResumed(owner);
    isRunning = false;
  }

  function() public {}
}