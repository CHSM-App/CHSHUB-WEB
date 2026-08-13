import { useCallback, useEffect, useRef, useState } from 'react';
import { useToast } from '@/components/Toast.jsx';

/**
 * List/create/update/delete state for one master resource.
 *
 * Every master screen has the same shape — a searchable list, a modal form, and
 * a delete confirmation — so that logic lives here and the pages stay declarative.
 *
 * `resource` is any object with list/create/update/remove, e.g. from api/masters.js.
 *
 * Successful mutations raise a toast from here rather than from each page. The
 * bespoke screens — flats, residents, PDC, charges — each wrote their own
 * submit handler, and none of them confirmed anything; putting it at the hook
 * covers all of them at once and keeps the wording consistent. Pass
 * `notify: false` for a caller that announces the outcome itself, so the two
 * do not stack up.
 */
export default function useCrudResource(
  resource,
  { itemsKey = 'items', params, notify = true, label = 'Record' } = {},
) {
  const toast = useToast();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);

  // Guards against a slow earlier request overwriting a newer result when the
  // user types quickly in the search box.
  const requestId = useRef(0);
  const paramsKey = JSON.stringify(params ?? {});

  const refresh = useCallback(async () => {
    const id = ++requestId.current;
    setLoading(true);
    setError(null);
    try {
      const data = await resource.list(params);
      if (id !== requestId.current) return;
      setItems(data?.[itemsKey] ?? []);
    } catch (err) {
      if (id === requestId.current) setError(err);
    } finally {
      if (id === requestId.current) setLoading(false);
    }
    // params is compared by value via paramsKey.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resource, itemsKey, paramsKey]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  /** Runs a mutation, refreshes the list, and surfaces errors to the caller. */
  const mutate = useCallback(
    async (fn, done) => {
      setSaving(true);
      setError(null);
      try {
        const result = await fn();
        await refresh();
        // Announced only after the refresh lands, so the confirmation and the
        // updated row appear together rather than the toast racing the list.
        if (notify && done) toast.success(`${label} ${done} successfully.`, { title: 'Saved' });
        return result;
      } catch (err) {
        setError(err);
        // Still rethrown — pages keep their own handling (the modal stays open
        // and renders the detail); this only makes sure the failure is visible
        // even when that notice is off screen.
        if (notify) toast.error(err?.message ?? 'The change could not be saved. Please try again.');
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [refresh, notify, label, toast],
  );

  const create = useCallback((body) => mutate(() => resource.create(body), 'added'), [mutate, resource]);
  const update = useCallback(
    (id, body) => mutate(() => resource.update(id, body), 'updated'),
    [mutate, resource],
  );
  const remove = useCallback((id) => mutate(() => resource.remove(id), 'deleted'), [mutate, resource]);

  return { items, loading, error, saving, refresh, create, update, remove, setError };
}
