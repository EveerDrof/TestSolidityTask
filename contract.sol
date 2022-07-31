pragma solidity ^0.8.6;

contract TaskContract {
    // Structs
    struct Tariff {
        uint256 percentPerMinute;
        uint256 minimumMinutesValue;
    }
    struct Deposit {
        uint256 value;
        uint256 startDate;
        uint256 endDate;
        uint256 additionPercentage;
        uint256 valueAfterAddition;
        bool wasWithdrawn;
    }
    struct ClientData {
        address wallet;
        bool isValue;
        Deposit deposit;
    }

    // Global variables
    address payable owner;

    mapping(uint256 => Tariff) tariffs;
    uint256 tariffsSize;
    uint256 oneMinute = 1 minutes;
    mapping(address => ClientData) clients;
    address[] clientsWallets;

    constructor(address payable _owner) payable {
        addTariff(1, 1);
        addTariff(3, 3);
        addTariff(5, 5);
        addTariff(10, 10);

        owner = _owner;
    }

    // Modifiers

    modifier onlyRegistered() {
        require(clients[msg.sender].isValue);
        _;
    }

    // Internal functions

    function addTariff(uint256 percentPerMinute, uint256 minimumMinutesValue)
        internal
    {
        tariffs[tariffsSize] = Tariff(percentPerMinute, minimumMinutesValue);
        tariffsSize += 1;
    }

    function createDeposit(uint256 minutesInterval)
        internal
        returns (Deposit memory)
    {
        uint256 startDate = block.timestamp;
        uint256 endDate = startDate + minutesInterval * oneMinute;
        uint256 additionPercentage = getStakeAdditionPercentage(
            minutesInterval
        );

        uint256 valueAfterAddition = msg.value;
        valueAfterAddition +=
            (valueAfterAddition / 100) *
            (additionPercentage * minutesInterval);

        return
            Deposit(
                msg.value,
                startDate,
                endDate,
                additionPercentage,
                valueAfterAddition,
                false
            );
    }

    function getStakeAdditionPercentage(uint256 stakeMinutes)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < tariffsSize; i++) {
            Tariff memory tariff = tariffs[i];
            if (stakeMinutes <= tariff.minimumMinutesValue) {
                return tariff.percentPerMinute;
            }
        }
        return tariffs[tariffsSize - 1].percentPerMinute;
    }

    //Payable
    function addCoinsToContract() public payable {
        require(msg.value > 0);
    }

    function createStake(uint256 minutesInterval) public payable {
        ClientData storage clientData = clients[msg.sender];
        if (clientData.isValue) {
            require(clientData.deposit.wasWithdrawn);
            clientData.deposit = createDeposit(minutesInterval);
            return;
        }
        Deposit memory deposit = createDeposit(minutesInterval);
        clients[msg.sender] = ClientData(msg.sender, true, deposit);
        clientsWallets.push(msg.sender);
    }

    function withdrawCoins() public payable onlyRegistered {
        Deposit memory clientDeposit = clients[msg.sender].deposit;
        require(!clientDeposit.wasWithdrawn);
        require(block.timestamp >= clientDeposit.endDate);
        require(address(this).balance >= clientDeposit.value);
        uint256 stake = clientDeposit.valueAfterAddition;
        payable(msg.sender).transfer(stake);
        clients[msg.sender].deposit.wasWithdrawn = true;
    }

    // Views
    function getStakingBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getClientData()
        public
        view
        onlyRegistered
        returns (ClientData memory)
    {
        return clients[msg.sender];
    }

    function getAllClientsData() public view returns (ClientData[] memory) {
        uint256 registeredClientsNumber = clientsWallets.length;
        ClientData[] memory result = new ClientData[](registeredClientsNumber);
        for (uint256 i = 0; i < registeredClientsNumber; i++) {
            result[i] = clients[clientsWallets[i]];
        }
        return result;
    }
}
