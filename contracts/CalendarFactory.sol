// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Calendar.sol";

contract CalendarFactory {

    mapping(address => uint256[]) public userToCalendarIds;
    mapping(uint256 => address) public calendarIdToCalendar;

    address calendarImplementation;
    uint256 public calendarCount = 0;

    event CalendarCreated(
        address indexed userAddress,
        address indexed calenderAddress,
        uint256 id
    );

    constructor() {
        calendarImplementation = address(new Calendar());
    }
    
    function createCalendar(
        string memory _emailAddress,
        bool[7] memory _availableDays,
        CalendarLib.Time calldata _availableStartTime,
        CalendarLib.Time calldata _availableEndTime
    ) external returns (uint256){
        require(CalendarLib.isLess(_availableStartTime, _availableEndTime),
            "The time of start must be earlier than the end.");

        address clone = Clones.clone(calendarImplementation);

        Calendar(clone).initialize(
            msg.sender,
            _emailAddress,
            _availableDays,
            _availableStartTime,
            _availableEndTime
        );

        uint256 id = calendarCount;
        calendarCount++;

        calendarIdToCalendar[id] = clone;
        userToCalendarIds[msg.sender].push(id);

        emit CalendarCreated(msg.sender, clone, id);

        return id;
    }
}