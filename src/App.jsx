import { Navigate, Route, Routes, useLocation } from 'react-router-dom';
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

import { PdcPage, PdcClearingPage } from './pages/billing/PdcPage.jsx';
import {
  RegisterPage,
  ForgotPasswordPage,
  SocietyProfilePage,
  ChangePasswordPage,
} from './pages/auth/OnboardingPages.jsx';
import {
  PaidAmountsPage,
  ProfitLossPage,
  AgmReportPage,
  BalanceSheetPage,
  OwnerLedgerPage,
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

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />

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
        <Route path="/dashboard" element={<DashboardPage />} />

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
        <Route path="/community/notices" element={<S.NoticesPage />} />
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
        <Route path="/reports/income-expense" element={<R.IncomeExpensePage />} />
        <Route path="/reports/audit" element={<AuditFullPage />} />
        <Route path="/reports/paid-amounts" element={<PaidAmountsPage />} />
        <Route path="/reports/profit-loss" element={<ProfitLossPage />} />
        <Route path="/reports/agm" element={<AgmReportPage />} />
        <Route path="/reports/balance-sheet" element={<BalanceSheetEditorPage />} />
        <Route path="/reports/owner-ledger" element={<OwnerLedgerPage />} />

        {/* Settings */}
        <Route path="/settings/accounts" element={<AccountSettingsPage />} />
        <Route path="/settings/charges" element={<ChargesPage />} />
        <Route path="/settings/terms" element={<TermsPage />} />
        <Route path="/settings/society" element={<SocietyProfilePage />} />
        <Route path="/settings/password" element={<ChangePasswordPage />} />

        {/* Village (Gram Panchayat) */}
        <Route path="/village/houses" element={<S.VillageHousesPage />} />
        <Route path="/village/residents" element={<VP.VillageResidentsPage />} />
        <Route path="/village/house-tax" element={<VP.VillageTaxPage kind="house" />} />
        <Route path="/village/house-tax/receipts" element={<VP.VillagePaymentsPage />} />
        <Route path="/village/water-tax" element={<VP.VillageTaxPage kind="water" />} />
        <Route path="/village/rates" element={<R.VillageRatesPage />} />
        <Route path="/village/staff" element={<S.VillageStaffPage />} />
        <Route path="/village/balance-sheet" element={<R.VillageBalanceSheetPage />} />
        <Route path="/village/payments" element={<VP.VillagePaymentsPage />} />
        <Route path="/village/history" element={<R.VillageHistoryPage />} />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
