import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { environment } from '../config/environment';
import { tokenStorage } from './tokenStorage';

type RetryConfig = InternalAxiosRequestConfig & { _retry?: boolean };

export class ApiError extends Error {
  constructor(
    message: string,
    public code = 'request_failed',
    public status?: number,
  ) {
    super(message);
  }
}

export const apiClient = axios.create({
  baseURL: environment.apiUrl,
  timeout: 15000,
  headers: { Accept: 'application/json' },
});

apiClient.interceptors.request.use(async (config) => {
  const token = await tokenStorage.getAccess();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

let refreshPromise: Promise<string> | null = null;

apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError<any>) => {
    const original = error.config as RetryConfig | undefined;
    if (
      error.response?.status === 401 &&
      original &&
      !original._retry &&
      !original.url?.includes('/auth/refresh')
    ) {
      original._retry = true;
      refreshPromise ??= (async () => {
        const refreshToken = await tokenStorage.getRefresh();
        if (!refreshToken) throw error;
        const response = await axios.post(`${environment.apiUrl}/auth/refresh`, {
          refresh_token: refreshToken,
        });
        await tokenStorage.save(response.data.access_token, response.data.refresh_token);
        return response.data.access_token as string;
      })().finally(() => {
        refreshPromise = null;
      });
      const access = await refreshPromise;
      original.headers.Authorization = `Bearer ${access}`;
      return apiClient(original);
    }
    const detail = error.response?.data?.error;
    throw new ApiError(
      detail?.message ||
        (error.code === 'ECONNABORTED'
          ? 'The request timed out.'
          : `Unable to connect to VibeCircle at ${environment.apiUrl}. Check that the backend is running on the same Wi-Fi network.`),
      detail?.code,
      error.response?.status,
    );
  },
);
