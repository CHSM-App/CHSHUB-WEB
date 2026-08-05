import { useCallback, useEffect, useRef, useState } from 'react';

/**
 * List/create/update/delete state for one master resource.
 *
 * Every master screen has the same shape — a searchable list, a modal form, and
 * a delete confirmation — so that logic lives here and the pages stay declarative.
 *
 * `resource` is any object with list/create/update/remove, e.g. from api/masters.js.
 */
export default function useCrudResource(resource, { itemsKey = 'items', params } = {}) {
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
    async (fn) => {
      setSaving(true);
      setError(null);
      try {
        const result = await fn();
        await refresh();
        return result;
      } catch (err) {
        setError(err);
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [refresh],
  );

  const create = useCallback((body) => mutate(() => resource.create(body)), [mutate, resource]);
  const update = useCallback((id, body) => mutate(() => resource.update(id, body)), [mutate, resource]);
  const remove = useCallback((id) => mutate(() => resource.remove(id)), [mutate, resource]);

  return { items, loading, error, saving, refresh, create, update, remove, setError };
}
