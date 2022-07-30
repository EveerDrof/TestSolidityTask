pragma solidity ^0.8.6;

contract MyContract {
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
    }
    uint256 oneMinute = 1 minutes;
    mapping(address => ClientData) clients;
    mapping(address => Deposit[]) deposits;
    address[] clientsWallets;
    Settings settings;

    constructor(address payable owner) payable {
        addTariff(1, 1);
        addTariff(3, 3);
        addTariff(5, 5);

        settings = Settings({owner: owner});
    }

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
        uint256 endDate = minutesInterval * oneMinute;
        uint256 additionPercentage = getStakeAdditionPercentage(
            minutesInterval
        );

        uint256 valueAfterAddition = msg.value;
        valueAfterAddition += (valueAfterAddition / 100) * additionPercentage;

        return
            Deposit(
                msg.value,
                block.timestamp,
                endDate,
                additionPercentage,
                valueAfterAddition
            );
    }

    function createStake(uint256 minutesInterval) public payable {
        ClientData storage clientData = clients[msg.sender];
        if (clientData.isValue) {
            deposits[msg.sender].push(createDeposit(minutesInterval));
            settings.owner.transfer(msg.value);
            return;
        }
        Deposit memory deposit = createDeposit(minutesInterval);
        deposits[msg.sender].push(deposit);
        clients[msg.sender] = ClientData(msg.sender, true);
        settings.owner.transfer(msg.value);
    }

    function getStakingBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getClientData() public view returns (ClientData memory) {
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

    function withdrawCoins() public payable {
        ClientData memory data = clients[msg.sender];
        require(data.isValue);
        Deposit[] memory clientDeposits = deposits[msg.sender];
        for (uint256 i = 0; i < clientDeposits.length; i++) {
            Deposit memory deposit = clientDeposits[i];
            if (
                block.timestamp >= deposit.endDate &&
                address(this).balance >= deposit.value
            ) {
                uint256 stake = deposit.valueAfterAddition;
                payable(msg.sender).transfer(stake);
            } else {
                return;
            }
        }
    }

    function removeFromDeposits(uint256 index) internal {
        Deposit[] storage senderDeposits = deposits[msg.sender];
        uint256 senderDepositsSize = senderDeposits.length;
        Deposit[] memory depositsCopy = new Deposit[](senderDepositsSize);
        if (index >= senderDepositsSize) return;

        for (uint256 i = index; i < senderDepositsSize - 1; i++) {
            depositsCopy[i] = senderDeposits[i + 1];
        }
        deposits[msg.sender] = depositsCopy;
    }

    function getClientDeposits() public view returns (Deposit[] memory) {
        return deposits[msg.sender];
    }
}
