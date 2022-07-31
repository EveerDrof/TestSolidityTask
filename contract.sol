pragma solidity ^0.8.6;

contract MyContract {
    // Structs
    struct Tariff {
        uint256 percentPerMinute;
        uint256 minimumMinutesValue;
    }
    struct Settings {
        address payable owner;
    }
    mapping(uint256 => Tariff) tariffs;
    uint256 tariffsSize;
    struct Deposit {
        uint256 value;
        uint256 startDate;
        uint256 endDate;
        uint256 additionPercentage;
        uint256 valueAfterAddition;
    }
    struct ClientData {
        address wallet;
        bool isValue;
        Deposit deposit;
    }

    // Global variables
    uint256 oneMinute = 1 minutes;
    mapping(address => ClientData) clients;
    address[] clientsWallets;
    Settings settings;

    constructor(address payable owner) payable {
        addTariff(1, 1);
        addTariff(3, 3);
        addTariff(5, 5);
        addTariff(10, 10);

        settings = Settings({owner: owner});
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

    function addCoinsToContract() public payable {
        require(msg.value > 0);
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
        valueAfterAddition += (valueAfterAddition / 100) * additionPercentage;

        return
            Deposit(
                msg.value,
                startDate,
                endDate,
                additionPercentage,
                valueAfterAddition
            );
    }

    function createStake(uint256 minutesInterval) public payable {
        ClientData storage clientData = clients[msg.sender];
        if (clientData.isValue) {
            require(clientData.deposit.value == 0);
            clientData.deposit = createDeposit(minutesInterval);
            return;
        }
        Deposit memory deposit = createDeposit(minutesInterval);
        clients[msg.sender] = ClientData(msg.sender, true, deposit);
    }

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

    function withdrawCoins() public payable onlyRegistered {
        Deposit memory clientDeposit = clients[msg.sender].deposit;
        require(clientDeposit.value > 0);
        require(block.timestamp >= clientDeposit.endDate);
        require(address(this).balance >= clientDeposit.value);
        uint256 stake = clientDeposit.valueAfterAddition;
        payable(msg.sender).transfer(stake);
        clientDeposit.value = 0;
    }

    function getClientDepositValue()
        public
        view
        onlyRegistered
        returns (uint256)
    {
        return clients[msg.sender].deposit.value;
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
