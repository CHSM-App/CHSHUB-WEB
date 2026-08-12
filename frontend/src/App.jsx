import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { useAuth } from './auth/AuthContext.jsx';
import { Spinner } from './components/ui.jsx';
import AppLayout from './components/AppLayout.jsx';

import LoginPage from './pages/LoginPage.jsx';
import DashboardPage from './pages/DashboardPage.jsx';

import BuildingsPage from './pages/masters/BuildingsPage.jsx';
import WingsPage from './pages/masters/WingsPage.jsx';
import FlatsPage from './pages/masters/FlatsPage.jsx';
import ResidentsPage from './pages/masters/ResidentsPage.jsx';
import ContactsPage from './pages/masters/ContactsPage.jsx';

import AccountSettingsPage from './pages/settings/AccountSettingsPage.jsx';
import ChargesPage from './pages/settings/ChargesPage.jsx';
import TermsPage from './pages/settings/TermsPage.jsx';

import BillsPage from './pages/billing/BillsPage.jsx';
import ReceiptsPage from './pages/billing/ReceiptsPage.jsx';
import DefaultersPage from './pages/billing/DefaultersPage.jsx';
import GenerateBillsPage from './pages/billing/GenerateBillsPage.jsx';

import CashbookPage from './pages/accounts/CashbookPage.jsx';
import VendorBillsPage from './pages/accounts/VendorBillsPage.jsx';
import SocietyExpensePage from './pages/accounts/SocietyExpensePage.jsx';
import ReceiptEntryPage from './pages/billing/ReceiptEntryPage.jsx';
import HelpdeskPage from './pages/community/HelpdeskPage.jsx';
import { NotFoundPage, ErrorBoundary } from './pages/ErrorPages.jsx';
import * as MP from './pages/masters/MasterPages.jsx';
import * as CP from './pages/community/CommunityPages.jsx';
import * as VP from './pages/village/VillagePages.jsx';
import { AuditPage as AuditFullPage, BalanceSheetEditorPage } from './pages/reports/AuditBalancePages.jsx';
import ShopMaintenanceReport from './pages/reports/ShopMaintenanceReport.jsx';
import OwnerwiseMaintenanceReport from './pages/reports/OwnerwiseMaintenanceReport.jsx';
import IncomeExpenditureReport from './pages/reports/IncomeExpenditureReport.jsx';

import { PdcPage, PdcClearingPage } from './pages/billing/PdcPage.jsx';
import {
  RegisterPage,
  ForgotPasswordPage,
  SocietyProfilePage,
  ChangePasswordPage,
} from './pages/auth/OnboardingPages.jsx';
import SocietySetupPage from './pages/auth/SocietySetupPage.jsx';
import VillageSetupPage from './pages/auth/VillageSetupPage.jsx';
import VillageAnnouncementsPage from './pages/village/VillageAnnouncementsPage.jsx';
import VillageSettingsPage from './pages/village/VillageSettingsPage.jsx';
import HouseChargesPage from './pages/village/HouseChargesPage.jsx';
import BillRunPage from './pages/village/BillRunPage.jsx';
import VillageSchemesPage from './pages/village/VillageSchemesPage.jsx';
import VillageReportsPage from './pages/village/VillageReportsPage.jsx';
import {
  PaidAmountsPage,
  AgmReportPage,
  BalanceSheetPage,
} from './pages/reports/FinancialReports.jsx';

import * as S from './pages/screens.jsx';
import * as R from './pages/ReadOnlyPages.jsx';

function RequireAuth({ children }) {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();

  if (loading) return <Spinner label="Restoring your session…" />;
  if (!isAuthenticated) return <Navigate to="/login" replace state={{ from: location }} />;
  return children;
}

/**
 * Restrict a route to one kind of tenant, mirroring requireSociety and
 * requireVillage on the API.
 *
 * The sidebar already hides the other tenant's links, but hiding a link is not
 * the same as closing a route: a typed URL, a bookmark, or the `from` location
 * RequireAuth stored before a logout all arrive here directly. That last one is
 * how a society admin signing in after a village user lands on
 * /village/settings — the village page then renders with every request 403ing,
 * because the API takes the tenant from the token and refuses the mismatch.
 *
 * Sending the account to its own dashboard is the honest answer: the page was
 * never theirs to see. Nothing is being protected here that the API does not
 * already protect — village_id and society_id come from the token, never from
 * the client — this only spares the user a screen that could only fail.
 */
function RequireTenant({ kind, children }) {
  const { villageId } = useAuth();
  if ((kind === 'village') !== Boolean(villageId)) return <Navigate to="/dashboard" replace />;
  return children;
}


/** Notices for a society, Announcements for a village. */
function NoticesRoute() {
  const { villageId } = useAuth();
  return villageId ? <VillageAnnouncementsPage /> : <S.NoticesPage />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />

      {/*
        new_society.aspx / new_village.aspx — where a new account went straight
        after registering, chosen by the Society/Village option on the
        registration form. Both need a session (they save against the signed-in
        tenant), but sit outside AppLayout: the legacy pages had no sidebar or
        topbar either, and a tenant that has not been named yet has nothing for
        that menu to point at.
      */}
      <Route
        path="/setup/society"
        element={
          <RequireAuth>
            <SocietySetupPage />
          </RequireAuth>
        }
      />
      <Route
        path="/setup/village"
        element={
          <RequireAuth>
            <VillageSetupPage />
          </RequireAuth>
        }
      />

      <Route
        element={
          <RequireAuth>
            <ErrorBoundary>
              <AppLayout />
            </ErrorBoundary>
          </RequireAuth>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        {/*
          Shared by both kinds of account, so they sit outside the two
          RequireTenant groups below: the dashboard picks its own panels by
          tenant, notices splits into Notices/Announcements in NoticesRoute,
          and the profile and password screens belong to the user rather than
          to whatever they administer.
        */}
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/community/notices" element={<NoticesRoute />} />
        <Route path="/settings/password" element={<ChangePasswordPage />} />

        {/* ---------------------------------------------------- society only */}
        <Route element={<RequireTenant kind="society"><Outlet /></RequireTenant>}>

          {/* Masters */}
          <Route path="/masters/buildings" element={<BuildingsPage />} />
          <Route path="/masters/wings" element={<WingsPage />} />
          <Route path="/masters/flats" element={<MP.FlatsMasterPage />} />
          <Route path="/masters/owners" element={<ResidentsPage type="Owner" />} />
          <Route path="/masters/tenants" element={<ResidentsPage type="Rent" />} />
          <Route path="/masters/staff" element={<MP.StaffMasterPage />} />
          <Route path="/masters/caretakers" element={<S.CaretakersPage />} />
          <Route path="/masters/helpers" element={<MP.HelpersMasterPage />} />
          <Route path="/masters/contacts" element={<ContactsPage />} />
          <Route path="/masters/doc-types" element={<S.DocTypesPage />} />
          <Route path="/masters/inventory" element={<MP.InventoryMasterPage />} />
          <Route path="/masters/parking-places" element={<S.ParkingPlacesPage />} />
          <Route path="/masters/parking-allotment" element={<MP.ParkingAllotmentPage />} />
          <Route path="/masters/car-pooling" element={<S.CarPoolingPage />} />
          <Route path="/masters/loans" element={<S.LoansPage />} />
          <Route path="/masters/members" element={<MP.CommitteeMembersPage />} />

          {/* Billing */}
          <Route path="/billing/bills" element={<BillsPage />} />
          <Route path="/billing/receipts" element={<ReceiptEntryPage />} />
          <Route path="/billing/defaulters" element={<DefaultersPage />} />
          <Route path="/billing/generate" element={<GenerateBillsPage />} />
          <Route path="/billing/pdc" element={<PdcPage />} />
          <Route path="/billing/pdc/clearing" element={<PdcClearingPage />} />

          {/* Accounts */}
          <Route path="/accounts/expenses" element={<SocietyExpensePage />} />
          <Route path="/accounts/ledger" element={<S.LedgerPage />} />
          <Route path="/accounts/shop-maintenance" element={<S.ShopMaintenancePage />} />
          <Route path="/accounts/other-credits" element={<S.OtherCreditsPage />} />
          <Route path="/accounts/cashbook" element={<CashbookPage />} />
          <Route path="/accounts/society-receipts" element={<R.SocietyReceiptsPage />} />
          <Route path="/accounts/vendors" element={<S.VendorsPage />} />
          <Route path="/accounts/vendor-bills" element={<VendorBillsPage />} />
          <Route path="/accounts/vendor-payments" element={<R.VendorPaymentsPage />} />

          {/* Community */}
          {/* /community/notices is shared — see the tenant-neutral block above. */}
          <Route path="/community/events" element={<S.EventsPage />} />
          <Route path="/community/meetings" element={<S.MeetingsPage />} />
          <Route path="/community/facilities" element={<MP.FacilitiesMasterPage />} />
          <Route path="/community/facility-bookings" element={<CP.FacilityBookingsPage />} />
          <Route path="/community/visitors" element={<CP.VisitorsPage />} />
          <Route path="/community/helpdesk" element={<HelpdeskPage />} />
          <Route path="/community/suggestions" element={<S.SuggestionsPage />} />
          <Route path="/community/messages" element={<CP.MessagesPage />} />
          <Route path="/community/documents" element={<CP.DocumentsPage />} />
          <Route path="/community/polls" element={<CP.PollsPage />} />

          {/* Reports */}
          <Route path="/reports/activity" element={<R.ActivityPage />} />
          {/* v_profite_loss.aspx — "Annual income and expenditure". Was pointing
              at the read-only IncomeExpensePage, which showed the same SP data
              without the paired layout or the totals row. */}
          <Route path="/reports/income-expense" element={<IncomeExpenditureReport />} />
          <Route path="/reports/audit" element={<AuditFullPage />} />
          <Route path="/reports/paid-amounts" element={<PaidAmountsPage />} />
          {/* /reports/profit-loss was a date-range report with no legacy
              equivalent. Annual income and expenditure is the one v_profite_loss
              .aspx rendered, so the old path redirects onto it rather than
              404ing a bookmark. */}
          <Route path="/reports/profit-loss" element={<Navigate to="/reports/income-expense" replace />} />
          <Route path="/reports/agm" element={<AgmReportPage />} />
          <Route path="/reports/balance-sheet" element={<BalanceSheetEditorPage />} />
          {/* ownerwise_maintenance.aspx — replaces the ?ownerId=-only OwnerLedgerPage */}
          <Route path="/reports/owner-ledger" element={<OwnerwiseMaintenanceReport />} />
          {/* printshop.aspx */}
          <Route path="/reports/shop-maintenance" element={<ShopMaintenanceReport />} />

          {/* Settings */}
          <Route path="/settings/accounts" element={<AccountSettingsPage />} />
          <Route path="/settings/charges" element={<ChargesPage />} />
          <Route path="/settings/terms" element={<TermsPage />} />
          <Route path="/settings/society" element={<SocietyProfilePage />} />
        </Route>

        {/* ---------------------------------------------------- village only */}
        <Route element={<RequireTenant kind="village"><Outlet /></RequireTenant>}>
          <Route path="/village/houses" element={<S.VillageHousesPage />} />
          <Route path="/village/residents" element={<VP.VillageResidentsPage />} />
          <Route path="/village/house-tax" element={<VP.VillageTaxPage kind="house" />} />
          <Route path="/village/house-tax/receipts" element={<VP.VillagePaymentsPage />} />
          <Route path="/village/water-tax" element={<VP.VillageTaxPage kind="water" />} />
          <Route path="/village/rates" element={<R.VillageRatesPage />} />
          <Route path="/village/staff" element={<S.VillageStaffPage />} />
          {/*
            The village balance sheet is gone: it listed accounting heads and
            their amounts, which answers none of the questions the office has.
            /village/reports covers them — collection, defaulters, monthly
            takings and a per-house ledger — all from the bills themselves.
          */}
          <Route path="/village/payments" element={<VP.VillagePaymentsPage />} />
          <Route path="/village/history" element={<R.VillageHistoryPage />} />
          <Route path="/village/house-charges" element={<HouseChargesPage />} />
          <Route path="/village/bill-run" element={<BillRunPage />} />
          <Route path="/village/schemes" element={<VillageSchemesPage />} />
          <Route path="/village/reports" element={<VillageReportsPage />} />
          <Route path="/village/settings" element={<VillageSettingsPage />} />
        </Route>
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
