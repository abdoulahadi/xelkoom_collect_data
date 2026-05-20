import axios from 'axios';

/**
 * Extract a user-friendly error message from an unknown error.
 * Handles Axios errors, standard Error objects, and fallback strings.
 */
export function getErrorMessage(err: unknown, fallback: string): string {
  if (axios.isAxiosError(err)) {
    return err.response?.data?.detail || fallback;
  }
  if (err instanceof Error) {
    return err.message || fallback;
  }
  return fallback;
}
