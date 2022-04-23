import { ContractReceipt, ContractTransaction, Signer } from "ethers";
import { ethers } from "hardhat";
import chai from "chai";
import { CalendarFactory, CalendarFactory__factory } from "typechain-types";
import {
  AvailabilityStruct,
  ProfileStruct,
} from "typechain-types/CalendarFactory";

enum DaysOfWeek {
  None = 0,
  Sunday = 1 << 0,
  Monday = 1 << 1,
  Tuesday = 1 << 2,
  Wednesday = 1 << 3,
  Thursday = 1 << 4,
  Friday = 1 << 5,
  Saturday = 1 << 6,
  SunThu = Monday | Tuesday | Wednesday | Thursday | Sunday,
  All = SunThu | Friday | Saturday,
}

type CalendarConfig = {
  profile: ProfileStruct;
  availability: AvailabilityStruct;
};

const cal1Config = {
  profile: {
    email: "alice@mail.com",
    username: "alicep",
    picture: "http://stock-imgs.com/alicep2342/profile.jpg",
    url: "aliceparsons.com",
    description: "performance artist",
  },
  availability: {
    availableDays: DaysOfWeek.SunThu,
    location: "New York",
    timeZone: "America/New_York",
    earliestTimeInMinutes: 9 * 60 + 30, //  9:30 UTC
    minutesAvailable: 8 * 60, // 16:30 UTC
  },
};

const cal2Config = {
  profile: {
    email: "bob@mail.com",
    username: "bobslob",
    picture: "http://stock-imgs.com/boblslob2398742/profile.jpg",
    url: "bobstraining.com",
    description: "personal trainer",
  },
  availability: {
    availableDays: DaysOfWeek.SunThu,
    location: "Sydney",
    timeZone: "Australia/Sydney",
    earliestTimeInMinutes: 8 * 60, // 8:00 UTC
    minutesAvailable: 9 * 60, // 16:00 UTC
  },
};

const cal3Config = {
  profile: {
    email: "carl@mail.com",
    username: "carl1",
    picture: "",
    url: "",
    description: "",
  },
  availability: {
    availableDays: DaysOfWeek.All,
    location: "London",
    timeZone: "Europe/London",
    earliestTimeInMinutes: 18 * 60, //  16:00 UTC
    minutesAvailable: 8 * 60, // 2:00 UTC + 1 day
  },
};

const deployCalendarFactory = async (deployer: Signer) =>
  await new CalendarFactory__factory(deployer).deploy();

async function deployCalendar(
  calendarFactory: CalendarFactory,
  signer: Signer,
  { profile, availability }: CalendarConfig
) {
  let tx: ContractTransaction = await calendarFactory
    .connect(signer)
    .createCalendar(profile, availability);
  let receipt: ContractReceipt = await tx.wait();
  const txEvent = receipt.events?.[0]?.args;
  let ownerAddr = txEvent?.owner;
  let calendarAddr = txEvent?.calendar;

  chai.expect(ownerAddr).to.equal(await signer.getAddress());
  const calendarAddressFromMapping = await calendarFactory.userToCalendar(
    ownerAddr
  );
  chai.expect(calendarAddr).to.equal(calendarAddressFromMapping);

  return await ethers.getContractAt("Calendar", calendarAddr);
}

export {
  cal1Config,
  cal2Config,
  cal3Config,
  deployCalendarFactory,
  deployCalendar,
};
