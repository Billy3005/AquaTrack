// Minimal fetch-on-mount hook. The console has no client-side cache on purpose:
// an admin acting on stale numbers is the failure mode we most want to avoid,
// so every screen refetches when its inputs (or the action version) change.

import { useCallback, useEffect, useRef, useState } from 'react';

export interface AsyncState<T> {
  data: T | null;
  loading: boolean;
  /**
   * True when `data` belongs to an earlier set of inputs and a replacement is
   * in flight. Screens keep rendering it to avoid a flash of empty table, but
   * must not let an operator act on it — the rows they see may not be the rows
   * the current filter selects.
   */
  stale: boolean;
  error: string | null;
  reload: () => void;
}

export function useApi<T>(fetcher: () => Promise<T>, deps: unknown[]): AsyncState<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [nonce, setNonce] = useState(0);

  // Guards against a slow earlier request overwriting a newer response.
  const requestId = useRef(0);

  useEffect(() => {
    const id = ++requestId.current;
    setLoading(true);
    setError(null);
    fetcher()
      .then((result) => {
        if (id === requestId.current) setData(result);
      })
      .catch((err: unknown) => {
        if (id === requestId.current) setError(err instanceof Error ? err.message : 'Lỗi không xác định');
      })
      .finally(() => {
        if (id === requestId.current) setLoading(false);
      });
    // `fetcher` is intentionally excluded — callers pass an inline closure, and
    // `deps` is the explicit list of what actually changes the request.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, nonce]);

  const reload = useCallback(() => setNonce((n) => n + 1), []);

  return { data, loading, stale: loading && data !== null, error, reload };
}

/** Debounce a value — used for the search box so typing does not spam the API. */
export function useDebounced<T>(value: T, delay = 350): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return debounced;
}
