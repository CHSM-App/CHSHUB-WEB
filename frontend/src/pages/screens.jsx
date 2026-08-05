import { useState } from 'react';
import GenericCrudPage from './GenericCrudPage.jsx';
import ExcelImport from './settings/ExcelImport.jsx';
import { Modal } from '@/components/ui.jsx';
import * as M from '@/api/modules';

// Declarative screen definitions. Each entry describes a legacy ASPX page as
// columns + form fields; GenericCrudPage renders it. Screens with bespoke
// behaviour (bills, receipts, helpdesk, dashboards) have their own components.

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');
const yesNo = (v) => (v ? 'Yes' : 'No');

/* -------------------------------------------------------------- masters */

/**
 * NOT ROUTED — `/masters/staff` renders `MasterPages.StaffMasterPage`, which is
 * the maintained version (it already carries the photo and ID-proof uploads).
 * Left in place rather than deleted because several screens here are in the
 * same position; see docs/PAGE-AUDIT.md.
 */
export const StaffPage = () => (
  <GenericCrudPage
    title="Staff"
    resource={M.staff}
    idKey="staff_id"
    columns={[
      { key: 'name', label: 'Name' },
      { key: 'role', label: 'Role' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'email', label: 'Email' },
      { key: 'date_of_join', label: 'Joined', format: day },
      { key: 'salary', label: 'Salary', format: money },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'address', label: 'Address' },
      { name: 'dateOfJoin', label: 'Date of joining', type: 'date' },
      { name: 'salary', label: 'Salary', type: 'number' },
      { name: 'roleId', label: 'Role', type: 'select', lookup: 'roles', optionValue: 'role_id', optionLabel: 'role' },
    ]}
    lookups={{ roles: M.lookups.staffRoles }}
    toForm={(r) => ({
      name: r.name ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      address: r.address ?? '',
      dateOfJoin: r.date_of_join ? String(r.date_of_join).slice(0, 10) : '',
      salary: r.salary ?? '',
      roleId: r.role_id ?? '',
    })}
  />
);

export const CaretakersPage = () => (
  <GenericCrudPage
    title="Caretakers"
    resource={M.caretakers}
    idKey="caretaker_id"
    columns={[
      { key: 'c_name', label: 'Name' },
      { key: 'mobile_no', label: 'Mobile' },
      { key: 'c_address', label: 'Address' },
      { key: 'city', label: 'City' },
      { key: 'flat_no', label: 'Flat' },
    ]}
    // Order follows caretaker.aspx: flat > name > address > area > mobile >
    // email > city > pincode > doc executed.
    fields={[
      { name: 'flatNo', label: 'Flat number' },
      { name: 'name', label: 'Name', required: true },
      { name: 'address', label: 'Address' },
      { name: 'area', label: 'Area' },
      { name: 'mobile', label: 'Mobile' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'city', label: 'City' },
      { name: 'pincode', label: 'Pincode' },
      { name: 'docExecuted', label: 'Document executed' },
    ]}
    toForm={(r) => ({
      flatNo: r.flat_no ?? '',
      name: r.c_name ?? '',
      address: r.c_address ?? '',
      area: r.area ?? '',
      mobile: r.mobile_no ?? '',
      email: r.email ?? '',
      city: r.city ?? '',
      pincode: r.pincode ?? '',
      docExecuted: r.doc_executed ?? '',
    })}
  />
);

export const HelpersPage = () => (
  <GenericCrudPage
    title="Helpers"
    resource={M.helpers}
    idKey="servent_id"
    columns={[
      { key: 's_name', label: 'Name' },
      { key: 'mobile_no1', label: 'Mobile' },
      { key: 's_address_1', label: 'Address' },
      { key: 'remark', label: 'Remark' },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'mobile1', label: 'Mobile' },
      { name: 'mobile2', label: 'Alternate mobile' },
      { name: 'address1', label: 'Address line 1' },
      { name: 'address2', label: 'Address line 2' },
      { name: 'remark', label: 'Remark', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.s_name ?? '',
      mobile1: r.mobile_no1 ?? '',
      mobile2: r.mobile_no2 ?? '',
      address1: r.s_address_1 ?? '',
      address2: r.s_address_2 ?? '',
      remark: r.remark ?? '',
    })}
  />
);

export const ContactsPage = () => (
  <GenericCrudPage
    title="Useful contacts"
    resource={M.contacts}
    idKey="usefull_contact_id"
    columns={[
      { key: 'p_name', label: 'Name' },
      { key: 'p_type_name', label: 'Type' },
      { key: 'org_name', label: 'Organisation' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'contact_address', label: 'Address' },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'typeId', label: 'Type', type: 'select', lookup: 'types', optionValue: 'p_type_id', optionLabel: 'p_type_name' },
      { name: 'orgName', label: 'Organisation' },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'address', label: 'Address line 1' },
      { name: 'address2', label: 'Address line 2' },
      { name: 'remark', label: 'Remark', span: 2 },
    ]}
    lookups={{ types: M.lookups.contactTypes }}
    toForm={(r) => ({
      name: r.p_name ?? '',
      typeId: r.p_type ?? '',
      orgName: r.org_name ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      address: r.contact_address ?? '',
      address2: r.address2 ?? '',
      remark: r.remark ?? '',
    })}
  />
);

export const DocTypesPage = () => (
  <GenericCrudPage
    title="Document types"
    resource={M.docTypes}
    idKey="doc_id"
    columns={[{ key: 'doc_name', label: 'Document type' }]}
    fields={[{ name: 'name', label: 'Document type', required: true, span: 2 }]}
    toForm={(r) => ({ name: r.doc_name ?? '' })}
  />
);

/**
 * Parking places. park_place_search.aspx carried an "import data" button whose
 * handler is live (OLEDB over the uploaded workbook), so it is reproduced here
 * through the shared ExcelImport modal.
 */
export const ParkingPlacesPage = () => {
  const [importing, setImporting] = useState(false);
  return (
  <GenericCrudPage
    title="Parking places"
    resource={M.parkingPlaces}
    idKey="place_id"
    headerActions={
      <button type="button" className="btn-primary" onClick={() => setImporting(true)}>
        Import Data
      </button>
    }
    columns={[
      { key: 'parking_no', label: 'Parking number' },
      { key: 'park_for', label: 'For' },
    ]}
    fields={[
      { name: 'parkingNo', label: 'Parking number', required: true },
      {
        name: 'parkFor',
        label: 'Vehicle type',
        type: 'select',
        options: [
          { id: '0', name: 'Bike' },
          { id: '1', name: 'Car' },
        ],
      },
    ]}
    toForm={(r) => ({ parkingNo: r.parking_no ?? '', parkFor: r.park_for === 'Car' ? '1' : '0' })}
  >
    <Modal open={importing} title="Import Data" onClose={() => setImporting(false)}>
      <ExcelImport defaultType="parking" onDone={() => setImporting(false)} />
    </Modal>
  </GenericCrudPage>
  );
};

export const CarPoolingPage = () => (
  <GenericCrudPage
    title="Car pooling"
    resource={M.carPooling}
    idKey="car_id"
    columns={[
      { key: 'c_name', label: 'Name' },
      { key: 'vehical_no', label: 'Vehicle' },
      { key: 'destination', label: 'Destination' },
      { key: 'seat', label: 'Seats' },
      { key: 'date', label: 'Date', format: day },
      { key: 'charges', label: 'Charges' },
    ]}
    // Order follows car_polling.aspx: name > vehicle > seat > time > date >
    // destination > charges.
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'vehicleNo', label: 'Vehicle number' },
      { name: 'seats', label: 'Seats' },
      { name: 'time', label: 'Time', type: 'time' },
      { name: 'date', label: 'Date', type: 'date' },
      { name: 'destination', label: 'Destination' },
      { name: 'charges', label: 'Charges' },
    ]}
    toForm={(r) => ({
      name: r.c_name ?? '',
      vehicleNo: r.vehical_no ?? '',
      seats: r.seat ?? '',
      // time comes back as a full datetime; the input wants HH:MM.
      time: r.time ? String(r.time).slice(11, 16) : '',
      date: r.date ? String(r.date).slice(0, 10) : '',
      destination: r.destination ?? '',
      charges: r.charges ?? '',
    })}
  />
);

export const LoansPage = () => (
  <GenericCrudPage
    title="Loans"
    resource={M.loans}
    idKey="loan_id"
    columns={[
      { key: 'bank', label: 'Bank' },
      { key: 'flat_id', label: 'Flat' },
      { key: 'noc_issued', label: 'NOC issued' },
      { key: 'society_noc', label: 'Society NOC', format: day },
      { key: 'loan_clearance', label: 'Clearance', format: day },
    ]}
    fields={[
      { name: 'bank', label: 'Bank', required: true },
      { name: 'flatId', label: 'Flat ID', type: 'number', required: true },
      { name: 'nocIssued', label: 'NOC issued' },
      { name: 'societyNocDate', label: 'Society NOC date', type: 'date' },
    ]}
    // sp_loan's Delete sets active_status = 0, which is the LIVE value, so the
    // row is not actually removed. Reported in docs/MIGRATION-MAP.md §5.
    canDelete={false}
    toForm={(r) => ({
      bank: r.bank ?? '',
      flatId: r.flat_id ?? '',
      nocIssued: r.noc_issued ?? '',
      societyNocDate: r.society_noc ? String(r.society_noc).slice(0, 10) : '',
    })}
  />
);

/* ------------------------------------------------------------- accounts */

export const ExpensesPage = () => (
  <GenericCrudPage
    title="Expenses"
    resource={M.expenses}
    idKey="expense_id"
    columns={[
      { key: 'invoice_no', label: 'Invoice' },
      { key: 'date', label: 'Date', format: day },
      { key: 'ex_name', label: 'Expense' },
      { key: 'ex_details', label: 'Details' },
      { key: 'f_amount', label: 'Amount', format: money },
      { key: 'expense_status', label: 'Status' },
    ]}
    fields={[
      { name: 'name', label: 'Expense name', required: true },
      { name: 'date', label: 'Date', type: 'date' },
      { name: 'amount', label: 'Amount', type: 'number', required: true },
      { name: 'tax', label: 'Tax', type: 'number' },
      { name: 'tds', label: 'TDS', type: 'number' },
      { name: 'finalAmount', label: 'Final amount', type: 'number', required: true },
      { name: 'details', label: 'Details', type: 'textarea', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.ex_name ?? '',
      date: r.date ? String(r.date).slice(0, 10) : '',
      amount: r.amount ?? '',
      tax: r.tax ?? '',
      tds: r.tds ?? '',
      finalAmount: r.f_amount ?? '',
      details: r.ex_details ?? '',
    })}
  />
);

export const LedgerPage = () => (
  <GenericCrudPage
    title="Ledger"
    resource={M.ledger}
    idKey="led_id"
    columns={[
      { key: 'led_description', label: 'Description' },
      { key: 'led_status', label: 'Status' },
      { key: 'date', label: 'Date', format: day },
    ]}
    fields={[
      { name: 'description', label: 'Description', required: true, span: 2 },
      { name: 'status', label: 'Status' },
    ]}
    toForm={(r) => ({ description: r.led_description ?? '', status: r.led_status ?? '' })}
  />
);

export const ShopMaintenancePage = () => (
  <GenericCrudPage
    title="Shop maintenance"
    resource={M.shopMaintenance}
    idKey="shop_maint_id"
    columns={[
      { key: 'mrep_no', label: 'Report no.' },
      { key: 'm_date', label: 'Date', format: day },
      { key: 'led_description', label: 'Ledger' },
      { key: 'amt', label: 'Amount', format: money },
      { key: 'pay_method', label: 'Pay method' },
    ]}
    fields={[
      { name: 'reportNo', label: 'Report number', required: true },
      { name: 'date', label: 'Date', type: 'date' },
      { name: 'ledgerId', label: 'Ledger ID', type: 'number', required: true },
      { name: 'amount', label: 'Amount', type: 'number', required: true },
      { name: 'payMethod', label: 'Payment method' },
      { name: 'details', label: 'Details', type: 'textarea', span: 2 },
    ]}
    canDelete={false}
    toForm={(r) => ({
      reportNo: r.mrep_no ?? '',
      date: r.m_date ? String(r.m_date).slice(0, 10) : '',
      ledgerId: r.led_id ?? '',
      amount: r.amt ?? '',
      payMethod: r.pay_method ?? '',
      details: r.other_details ?? '',
    })}
  />
);

export const OtherCreditsPage = () => (
  <GenericCrudPage
    title="Other credits"
    resource={M.otherCredits}
    idKey="Id"
    searchable={false}
    columns={[
      { key: 'Description', label: 'Description' },
      { key: 'Amount', label: 'Amount', format: money },
      { key: 'PaymentDate', label: 'Payment date', format: day },
    ]}
    fields={[
      { name: 'description', label: 'Description', required: true, span: 2 },
      { name: 'amount', label: 'Amount', type: 'number', required: true },
      { name: 'paymentDate', label: 'Payment date', type: 'date' },
    ]}
    toForm={(r) => ({
      description: r.Description ?? '',
      amount: r.Amount ?? '',
      paymentDate: r.PaymentDate ? String(r.PaymentDate).slice(0, 10) : '',
    })}
  />
);

export const VendorsPage = () => (
  <GenericCrudPage
    title="Vendors"
    resource={M.vendors}
    idKey="vendor_id"
    columns={[
      { key: 'vendor_name', label: 'Vendor' },
      { key: 'contact_person', label: 'Contact person' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'service_type', label: 'Service' },
      { key: 'gst_no', label: 'GST' },
    ]}
    fields={[
      { name: 'name', label: 'Vendor name', required: true },
      { name: 'contactPerson', label: 'Contact person' },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'serviceType', label: 'Service type' },
      { name: 'gstNo', label: 'GST number' },
      { name: 'address', label: 'Address', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.vendor_name ?? '',
      contactPerson: r.contact_person ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      serviceType: r.service_type ?? '',
      gstNo: r.gst_no ?? '',
      address: r.address ?? '',
    })}
  />
);

/* ------------------------------------------------------------ community */

export const NoticesPage = () => (
  <GenericCrudPage
    title="Notices"
    resource={M.notices}
    idKey="notice_id"
    columns={[
      { key: 'name', label: 'Title' },
      { key: 'description', label: 'Description' },
      { key: 'date', label: 'Published', format: day },
      { key: 'valid_to', label: 'Valid to', format: day },
    ]}
    fields={[
      { name: 'title', label: 'Title', required: true, span: 2 },
      { name: 'description', label: 'Description', type: 'textarea', span: 2 },
      { name: 'validTo', label: 'Valid until', type: 'date' },
      { name: 'recipientsId', label: 'Recipients', type: 'select', lookup: 'recipients', optionValue: 'recipients_id', optionLabel: 'recipients' },
    ]}
    lookups={{ recipients: M.community.noticeRecipients }}
    toForm={(r) => ({
      title: r.name ?? '',
      description: r.description ?? '',
      validTo: r.valid_to ? String(r.valid_to).slice(0, 10) : '',
      recipientsId: r.recipients_id ?? '',
    })}
  />
);

export const EventsPage = () => (
  <GenericCrudPage
    title="Events"
    resource={M.events}
    idKey="event_id"
    searchable={false}
    columns={[
      { key: 'event_name', label: 'Event' },
      { key: 'description', label: 'Description' },
      { key: 'from_date', label: 'From', format: day },
      { key: 'to_date', label: 'To', format: day },
    ]}
    fields={[
      { name: 'name', label: 'Event name', required: true, span: 2 },
      { name: 'description', label: 'Description', type: 'textarea', span: 2 },
      { name: 'fromDate', label: 'From', type: 'date', required: true },
      { name: 'toDate', label: 'To', type: 'date', required: true },
    ]}
    toForm={(r) => ({
      name: r.event_name ?? '',
      description: r.description ?? '',
      fromDate: r.from_date ? String(r.from_date).slice(0, 10) : '',
      toDate: r.to_date ? String(r.to_date).slice(0, 10) : '',
    })}
  />
);

export const MeetingsPage = () => (
  <GenericCrudPage
    title="Meetings"
    resource={M.meetings}
    idKey="meet_id"
    columns={[
      { key: 'subject', label: 'Subject' },
      { key: 'details', label: 'Details' },
      { key: 'meeting_date', label: 'Date', format: day },
    ]}
    fields={[
      { name: 'subject', label: 'Subject', required: true, span: 2 },
      { name: 'details', label: 'Details', type: 'textarea', span: 2 },
      { name: 'meetingDate', label: 'Meeting date', type: 'date', required: true },
    ]}
    toForm={(r) => ({
      subject: r.subject ?? '',
      details: r.details ?? '',
      meetingDate: r.meeting_date ? String(r.meeting_date).slice(0, 10) : '',
    })}
  />
);

export const FacilitiesPage = () => (
  <GenericCrudPage
    title="Facilities"
    resource={M.facilities}
    idKey="facility_id"
    searchable={false}
    columns={[
      { key: 'name', label: 'Facility' },
      { key: 'cost', label: 'Cost', format: money },
      { key: 'capacity', label: 'Capacity' },
      { key: 'slot', label: 'Slots' },
      { key: 'isActive', label: 'Bookable', format: yesNo },
    ]}
    fields={[
      { name: 'name', label: 'Facility name', required: true },
      { name: 'cost', label: 'Cost', type: 'number' },
      { name: 'capacity', label: 'Capacity', type: 'number' },
      { name: 'slots', label: 'Slots', type: 'number' },
      { name: 'description', label: 'Description', span: 2 },
      { name: 'isActive', label: 'Available for booking', type: 'checkbox', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.name ?? '',
      cost: r.cost ?? '',
      capacity: r.capacity ?? '',
      slots: r.slot ?? '',
      description: r.description ?? '',
      isActive: Boolean(r.isActive),
    })}
  />
);

export const SuggestionsPage = () => (
  <GenericCrudPage
    title="Suggestions"
    resource={M.suggestions}
    idKey="sug_id"
    columns={[
      { key: 'subject', label: 'Subject' },
      { key: 'details', label: 'Details' },
    ]}
    canCreate={false}
    canEdit={false}
  />
);

export const DocumentsPage = () => (
  <GenericCrudPage
    title="Documents"
    resource={M.documents}
    idKey="file_id"
    columns={[
      { key: 'doc_name', label: 'Document' },
      { key: 'Tag', label: 'Tag' },
      { key: 'Description', label: 'Description' },
      { key: 'date', label: 'Uploaded', format: day },
    ]}
    canCreate={false}
    canEdit={false}
  />
);

/* -------------------------------------------------------------- village */

export const VillageHousesPage = () => (
  <GenericCrudPage
    title="Houses"
    resource={{
      list: M.village.houses,
      create: M.village.createHouse,
      update: M.village.updateHouse,
      remove: () => Promise.reject(new Error('Houses cannot be deleted')),
    }}
    idKey="house_id"
    searchable={false}
    canDelete={false}
    columns={[
      { key: 'house_no', label: 'House no.' },
      { key: 'name', label: 'Owner' },
      { key: 'house_type', label: 'Type' },
      { key: 'area', label: 'Area' },
      { key: 'gharpatti_charges', label: 'Property tax', format: money },
      { key: 'water_charges', label: 'Water', format: money },
      { key: 'waste_charges', label: 'Waste', format: money },
    ]}
    fields={[
      { name: 'houseNo', label: 'House number', type: 'number', required: true },
      { name: 'houseType', label: 'House type ID', type: 'number', required: true },
      { name: 'area', label: 'Area', type: 'number' },
      { name: 'propertyTax', label: 'Property tax', type: 'number' },
      { name: 'tapCount', label: 'Number of taps', type: 'number' },
      { name: 'waterCharges', label: 'Water charges', type: 'number' },
      { name: 'wasteCharges', label: 'Waste charges', type: 'number' },
    ]}
    toForm={(r) => ({
      houseNo: r.house_no ?? '',
      houseType: r.house_type ?? '',
      area: r.area ?? '',
      propertyTax: r.gharpatti_charges ?? '',
      tapCount: r.no_of_tab ?? '',
      waterCharges: r.water_charges ?? '',
      wasteCharges: r.waste_charges ?? '',
    })}
  />
);

export const VillageStaffPage = () => (
  <GenericCrudPage
    title="Village staff"
    resource={{
      list: M.village.staff,
      create: M.village.createStaff,
      update: M.village.updateStaff,
      remove: M.village.removeStaff,
    }}
    idKey="staff_id"
    searchable={false}
    columns={[
      { key: 'staff_name', label: 'Name' },
      { key: 'role', label: 'Role' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'email', label: 'Email' },
      { key: 'joined_date', label: 'Joined', format: day },
      { key: 'salary', label: 'Salary', format: money },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'address', label: 'Address' },
      { name: 'joinedDate', label: 'Joined date', type: 'date' },
      { name: 'salary', label: 'Salary', type: 'number' },
      { name: 'roleId', label: 'Role', type: 'select', lookup: 'roles', optionValue: 'role_id', optionLabel: 'role' },
    ]}
    lookups={{ roles: M.village.staffRoles }}
    toForm={(r) => ({
      name: r.staff_name ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      address: r.address ?? '',
      joinedDate: r.joined_date ? String(r.joined_date).slice(0, 10) : '',
      salary: r.salary ?? '',
      roleId: r.role_id ?? '',
    })}
  />
);
