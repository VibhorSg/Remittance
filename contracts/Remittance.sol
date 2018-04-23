pragma solidity ^ 0.4.21;

contract Remittance {

  /*
   * Maximun number of block it can be mined.
   */
  uint constant maxDuration = 1000;

  /*
   * Owner of the contract.
   */
  address public owner;

  /*
   * Flag to detrermine whether contract is running or not.
   */
  bool public isRunning;

  /*
   * Hold remittance data
   * contractOwner: Contract owner address. {Alice}
   * exchage: Exchange address. Exchange is responsible for converting currency.
   * {Carol} amount: Amount in Ether to remit. deadline: The block number after
   * which the amount can be reclaimed by the contract owner. claimed: Boolean
   * to determine whether amount has been remitted and claimed.
   */
  struct RemittanceStructure {
    address contractOwner;
    address exchage;
    uint amount;
    uint deadline;
    bool claimed;
  }

  /*
   *Map of the remittance structure. Key is the puzzle to be solve.
   */
  mapping(bytes32 => RemittanceStructure) public remittances;

  event LogContractCreated(address indexed contractOwner,
                           address indexed exchage, uint deadline, uint amount);
  event LogClaimed(address indexed contractOwner, address indexed exchage,
                   uint amount);
  event LogReclaimed(address indexed contractOwner, uint amount);
  event LogPaused(address indexed owner);
  event LogResumed(address indexed owner);

  /*
   *constructor: Remittance
   *In: _running: Boolean value for running state.
   */
  function Remittance(bool _running) public {
    owner = msg.sender;
    isRunning = _running;
  }

  /*
   *Modifier: onlyIfRunning
   *To check running state.
   */
  modifier onlyIfRunning {
    require(isRunning);
    _;
  }

  /*
   *Function: createRemittance
   *In: _puzzle: Puzzle to solve.
   *In: _exchange: Exchange address. Exchange is responsible for converting
   *currency In: _duration: No of blocks the remmitance contract remain valid.
   */
  function createRemittance(bytes32 _puzzle, address _exchange,
                            uint _duration) public onlyIfRunning payable
  returns(bool) {
    require(msg.value > 0);
    require(_exchange != address(0x00));
    require(_duration <= maxDuration);
    remittances[_puzzle] = RemittanceStructure(msg.sender, _exchange, msg.value,
                                               _duration + block.number, false);
    isRunning = true;
    emit LogContractCreated(msg.sender, _exchange, _duration + block.number,
                            msg.value);
    return true;
  }

  /*
   *Function: claimRemittance: This function should be called by the exchange
   *shop to receive the Ether from the contract owner. In: _recipientPassword:
   *The password that contract owner has passed to the recipient. {Bob}
   *In: _exchange: The password that contract owner has passed to the exchange
   *shop.
   *{Carol}
   */
  function claimRemittance(bytes32 _recipientPassword,
                           bytes32 _exchangePassword) public onlyIfRunning
  returns(bool) {
    require(_recipientPassword.length != 0);
    require(_exchangePassword.length != 0);
    RemittanceStructure storage remittanceContract =
        remittances[keccak256(_recipientPassword, _exchangePassword)];
    require(remittanceContract.amount > 0); // Check reclaim contract is valid
    require(remittanceContract.exchage == msg.sender); // Sender should Carol
    uint amount = remittanceContract.amount;
    remittanceContract.amount = 0;
    emit LogClaimed(remittanceContract.contractOwner, msg.sender, amount);
    msg.sender.transfer(amount);
    return true;
  }

  /*
   *Function: reclaimRemittance: This functio should be called by the contract
   *owner to get back the Ether after deadline is crossed. {Alice} In: _puzzle:
   *The puzzle to solve
   */
  function reclaimRemittance(bytes32 _puzzle) public onlyIfRunning returns(
      bool) {
    require(msg.sender != address(0x00));
    RemittanceStructure storage remittanceContract = remittances[_puzzle];
    require(remittanceContract.amount >
            0); // Check remittance structure is valid
    require(!remittanceContract.claimed);
    require(remittanceContract.contractOwner == msg.sender);
    require(remittanceContract.deadline > block.number);
    remittanceContract.claimed = true;
    emit LogReclaimed(msg.sender, remittanceContract.amount);
    msg.sender.transfer(remittanceContract.amount);
  }

  /*
   *Function: pause: This function is use to halt the remittance process.
   */
  function pause() public onlyIfRunning returns(bool) {
    require(msg.sender == owner);
    emit LogPaused(owner);
    isRunning = false;
  }

  /*
   *Function: resume: This function is use to  the remittance process.
   */
  function resume() public returns(bool) {
    require(msg.sender == owner);
    emit LogResumed(owner);
    isRunning = true;
  }

  /*
   *The fallback function.
   */
  function() public {}
}