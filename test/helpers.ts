import { Contract, ContractReceipt, ContractTransaction, Signer } from "ethers";
import { ethers } from "hardhat";
import chai from "chai";

const cal1Config = {
  emailAddress: "alice@mail.com",
  availableDays: [true, true, true, true, true, false, false],
  hour: 9,
  minute: 30, //  9:30 UTC
  duration: 8 * 60, // 16:30 UTC
};

const cal2Config = {
  emailAddress: "bob@mail.com",
  availableDays: [true, true, true, true, true, false, false],
  hour: 8,
  minute: 0, //  8:00 UTC
  duration: 9 * 60, // 16:00 UTC
};

const cal3Config = {
  emailAddress: "carl@mail.com",
  availableDays: [true, true, true, true, true, true, true],
  hour: 18,
  minute: 0, //  16:00 UTC
  duration: 8 * 60, // 2:00 UTC + 1 day
};

async function deployCalendarFactory(deployer: Signer) {
  // deploy CalendarFactory
  const CalendarFactory = await ethers.getContractFactory("CalendarFactory");
  return await CalendarFactory.deploy();
}

async function deployCalendar(
  calendarFactory: Contract,
  signer: Signer,
  config: Object
) {
  let tx: ContractTransaction = await calendarFactory
    .connect(signer)
    .createCalendar(...Object.values(config));
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
