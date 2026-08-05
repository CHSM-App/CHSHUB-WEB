import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import * as XLSX from 'xlsx';
import ExcelImport from './ExcelImport.jsx';

const createdBuildings = [];
const createdMembers = [];
const createdOwners = [];
const createdWings = [];
const createdFlats = [];

vi.mock('@/api/masters', () => ({
  buildings: {
    create: vi.fn(async (body) => {
      if (body.name === 'Duplicate Tower') throw new Error('Registration number already used');
      createdBuildings.push(body);
      return { ok: true };
    }),
    list: vi.fn(async () => ({ items: [{ build_id: 7, name: 'Arambh Chs' }] })),
  },
  wings: {
    create: vi.fn(async (body) => {
      createdWings.push(body);
      return { ok: true };
    }),
  },
  flats: {
    lookups: vi.fn(async () => ({
      wings: [{ wing_id: 3, name: 'Arambh ChsA-1' }],
      flatTypes: [{ flat_type_id: 1, flat_type: 'Flat' }],
      usages: [{ usage_id: 1, usage: 'Residential' }],
      bedrooms: [{ bed_id: 3, bed: '2 BED' }],
    })),
    list: vi.fn(async () => ({ items: [{ flat_id: 55, flat_no: '102' }] })),
    create: vi.fn(async (body) => {
      createdFlats.push(body);
      return { ok: true };
    }),
  },
  residents: {
    lookups: vi.fn(async () => ({
      marital: [
        { married_id: 1, married_name: 'married' },
        { married_id: 2, married_name: 'unmarried' },
      ],
    })),
    create: vi.fn(async (body) => {
      createdOwners.push(body);
      return { ok: true };
    }),
  },
}));

vi.mock('@/api/client', () => ({
  api: {
    get: vi.fn(async () => ({
      items: [
        { UserTypeId: 2, UserTypeName: 'Secretary' },
        { UserTypeId: 4, UserTypeName: 'Member' },
        { UserTypeId: 6, UserTypeName: 'Treasurer' },
      ],
    })),
    post: vi.fn(async (_url, body) => {
      createdMembers.push(body);
      return { ok: true };
    }),
  },
}));

/** Build a real .xlsx in memory, laid out with the legacy column letters. */
function workbookFile(rows) {
  const ws = XLSX.utils.aoa_to_sheet(rows);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Sheet1');
  const buf = XLSX.write(wb, { type: 'array', bookType: 'xlsx' });
  return new File([buf], 'import.xlsx', {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  });
}

/** The count sits in its own <strong>, so match on the paragraph's full text. */
const readyCount = (n) => (_, el) =>
  el?.tagName === 'P' && new RegExp(`^\\s*${n} row\\(s\\) ready`).test(el.textContent ?? '');

// A=name B=email C=print name D=floors E=(unused) F=registration no
const BUILDING_HEADER = ['Name', 'Email', 'Print', 'Floors', '', 'Reg No'];

describe('ExcelImport', () => {
  beforeEach(() => {
    createdBuildings.length = 0;
    createdMembers.length = 0;
    createdOwners.length = 0;
    createdWings.length = 0;
    createdFlats.length = 0;
  });

  it('parses rows using the legacy column letters and skips the header', async () => {
    const user = userEvent.setup();
    render(<ExcelImport onDone={() => {}} />);

    await user.upload(
      screen.getByLabelText(/spreadsheet/i),
      workbookFile([BUILDING_HEADER, ['A Wing', 'a@x.com', 'A-Wing', '5', '', 'REG-1']]),
    );

    await waitFor(() => expect(screen.getByText(readyCount(1))).toBeInTheDocument());
    expect(screen.getByText('A Wing')).toBeInTheDocument();
    expect(screen.getByText('REG-1')).toBeInTheDocument();
  });

  it('ignores rows with no value in the first column, as the legacy loop did', async () => {
    const user = userEvent.setup();
    render(<ExcelImport onDone={() => {}} />);

    await user.upload(
      screen.getByLabelText(/spreadsheet/i),
      workbookFile([
        BUILDING_HEADER,
        ['', 'x@x.com', '', '', '', 'REG-9'],
        ['B Wing', '', '', '2', '', 'REG-2'],
      ]),
    );

    await waitFor(() => expect(screen.getByText(readyCount(1))).toBeInTheDocument());
  });

  it('imports each row and reports failures without aborting the rest', async () => {
    const user = userEvent.setup();
    render(<ExcelImport onDone={() => {}} />);

    await user.upload(
      screen.getByLabelText(/spreadsheet/i),
      workbookFile([
        BUILDING_HEADER,
        ['Good Tower', '', '', '3', '', 'REG-A'],
        ['Duplicate Tower', '', '', '3', '', 'REG-B'],
        ['Another Tower', '', '', '1', '', 'REG-C'],
      ]),
    );

    await waitFor(() => expect(screen.getByText(readyCount(3))).toBeInTheDocument());
    await user.click(screen.getByRole('button', { name: /import 3 row/i }));

    await waitFor(() => expect(screen.getByText(/imported 2 building/i)).toBeInTheDocument());
    expect(createdBuildings.map((c) => c.name)).toEqual(['Good Tower', 'Another Tower']);
    expect(screen.getByText(/Row 3 \(Duplicate Tower\)/)).toBeInTheDocument();
  });

  it('resolves a member designation by name from the database', async () => {
    const user = userEvent.setup();
    render(<ExcelImport onDone={() => {}} />);

    await user.selectOptions(screen.getByLabelText(/import type/i), 'society_member');
    await user.upload(
      screen.getByLabelText(/spreadsheet/i),
      workbookFile([
        ['Name', 'Designation', 'Contact', 'Email'],
        ['Asha Patil', 'Treasurer', '9876543210', 'asha@x.com'],
      ]),
    );

    await waitFor(() => expect(screen.getByText(readyCount(1))).toBeInTheDocument());
    await user.click(screen.getByRole('button', { name: /import 1 row/i }));

    await waitFor(() => expect(screen.getByText(/imported 1 society member/i)).toBeInTheDocument());
    // Treasurer is 6 in UserType — resolved by name, not hardcoded.
    expect(createdMembers[0]).toMatchObject({ name: 'Asha Patil', userTypeId: 6 });
  });

  it('rejects a designation that does not exist rather than guessing', async () => {
    const user = userEvent.setup();
    render(<ExcelImport onDone={() => {}} />);

    await user.selectOptions(screen.getByLabelText(/import type/i), 'society_member');
    await user.upload(
      screen.getByLabelText(/spreadsheet/i),
      workbookFile([
        ['Name', 'Designation', 'Contact', 'Email'],
        ['Ravi Shah', 'President', '9876500000', 'ravi@x.com'],
      ]),
    );

    await waitFor(() => expect(screen.getByText(readyCount(1))).toBeInTheDocument());
    await user.click(screen.getByRole('button', { name: /import 1 row/i }));

    // "President" is not in UserType — the legacy code mapped it to 1 (admin).
    await waitFor(() => expect(screen.getByText(/1 row\(s\) were skipped/i)).toBeInTheDocument());
    expect(screen.getByText(/Unknown designation "President"/)).toBeInTheDocument();
    expect(createdMembers).toHaveLength(0);
  });

  it('reuses an existing wing and flat when importing an owner', async () => {
    const user = userEvent.setup();
    render(<ExcelImport onDone={() => {}} />);

    await user.selectOptions(screen.getByLabelText(/import type/i), 'owner');

    // Columns A..AB; only the ones the importer reads need values.
    const row = [];
    row[0] = 'Arambh Chs'; // A building
    row[1] = 'A-1'; // B wing
    row[2] = '102'; // C flat no
    row[3] = 'Residential'; // D usage
    row[4] = '2 BED'; // E bedroom
    row[8] = 'Flat'; // I flat type
    row[10] = 'Sunil Rao'; // K owner name
    row[11] = '9800000000'; // L mobile
    row[14] = 'Married'; // O marital
    row[27] = 'Own'; // AB type

    await user.upload(
      screen.getByLabelText(/spreadsheet/i),
      workbookFile([['Building', 'Wing', 'Flat'], row]),
    );

    await waitFor(() => expect(screen.getByText(readyCount(1))).toBeInTheDocument());
    await user.click(screen.getByRole('button', { name: /import 1 row/i }));

    await waitFor(() => expect(screen.getByText(/imported 1 owner/i)).toBeInTheDocument());
    // Wing "Arambh ChsA-1" and flat 102 already exist, so neither is recreated.
    expect(createdWings).toHaveLength(0);
    expect(createdFlats).toHaveLength(0);
    expect(createdOwners[0]).toMatchObject({
      wingId: 3,
      flatId: 55,
      name: 'Sunil Rao',
      marriedId: 1,
      type: 'Own',
    });
  });
});
