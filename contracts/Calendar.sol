// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CalendarLib.sol";
import "./DateTime.sol";

contract Calendar is Initializable {
    
    address owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    int8 public timezone;
    string public emailAddress;
    bool[7] public availableDays;
    CalendarLib.Time public availableStart;
    CalendarLib.Time public availableEnd;

    mapping(uint256 => // year
        mapping(uint256 => // month
            mapping(uint256 => // day
                CalendarLib.Meeting[]
            )
        )
    ) public dateToMeetings;

    event MeetingBooked(
        address indexed _attendee,
        uint256 year, uint256 month, uint256 day,
        uint256 startHour, uint256 startMinute,
        uint256 endHour, uint256 endMinute
    );

    event MeetingCancelled(
        address indexed _attendee,
        uint256 year, uint256 month, uint256 day,
        uint256 startHour, uint256 startMinute,
        uint256 endHour, uint256 endMinute
    );

    function initialize(
        address _owner,
        int8 _timezone,
        string memory _emailAddress,
        bool[7] memory _availableDays,
        CalendarLib.Time calldata _availableStartTime,
        CalendarLib.Time calldata _availableEndTime
    ) external initializer
    {
        owner = _owner;
        timezone = _timezone;
        emailAddress = _emailAddress;
        availableDays = _availableDays;
        availableStart = _availableStartTime;
        availableEnd = _availableEndTime;
    }

    function setAvailableDays(bool[7] memory _availableDays) external onlyOwner {
        availableDays = _availableDays;
    }

    function changeAvailableTimes(CalendarLib.Time calldata _start, CalendarLib.Time calldata _end) external onlyOwner {
        require(CalendarLib.isLess(_start, _end), "The start must be earlier than the end.");
        availableStart = _start;
        availableEnd = _end;
    }

    function bookMeeting(
        uint256 _year,
        uint256 _month,
        uint256 _day,
        CalendarLib.Time calldata _start,
        CalendarLib.Time calldata _end
    ) external {
        require(CalendarLib.isLess(_start,_end), "The time of start must be earlier than the end.");

        require(msg.sender != owner, "You cannot book a meeting with yourself.");
        require(CalendarLib.isInbetween(_start, availableStart, availableEnd)
             && CalendarLib.isInbetween(_end, availableStart, availableEnd) , "Time not available.");

        uint256 timestamp = DateTime.timestampFromDateTime(_year, _month, _day, _start.hour, _start.minute, 59);
        require(timestamp > block.timestamp, "Cant book in past");
        require(availableDays[DateTime.getDayOfWeek(timestamp) - 1], "Day not available.");
        // TODO What if event spans two days e.g. start 23:30, end 00:30?

        // Compare existing events for collisions
        for (uint i=0; i<dateToMeetings[_year][_month][_day].length; i++) {

            // Require the new meeting to have no overlap with meeting i
            if (!CalendarLib.isGreaterOrEqual(_start, dateToMeetings[_year][_month][_day][i].end)) {   //          |s..e| <= |s'..
                require(CalendarLib.isLessOrEqual(_end, dateToMeetings[_year][_month][_day][i].start), // ..e'| <= |s..e|
                    "Overlap with existing event."
                );
            }
        }

        //No time collision
        dateToMeetings[_year][_month][_day].push(
            CalendarLib.Meeting({
                attendee: msg.sender,
                start: _start,
                end: _end
            })
        );

        emit MeetingBooked(
            msg.sender, _year, _month, _day,
            _start.hour, _start.minute,
            _end.hour, _end.minute
        );
    }

    function cancelMeeting(
        uint256 _year,
        uint256 _month,
        uint256 _day,
        CalendarLib.Time calldata _start,
        CalendarLib.Time calldata _end
    ) external {

        uint length = dateToMeetings[_year][_month][_day].length;
        for (uint i=0; i<length; i++) {
            require(CalendarLib.isEqual(_start, dateToMeetings[_year][_month][_day][i].start)
                 && CalendarLib.isEqual(_end, dateToMeetings[_year][_month][_day][i].end),
                 "Meeting not found."
            );

            // remove element by overwriting it with the last element
            dateToMeetings[_year][_month][_day][i] =  dateToMeetings[_year][_month][_day][length-1];
            dateToMeetings[_year][_month][_day].pop();

            emit MeetingCancelled(
                msg.sender, _year, _month, _day,
                _start.hour, _start.minute,
                _end.hour, _end.minute
            );
            return;
        }
    }
}