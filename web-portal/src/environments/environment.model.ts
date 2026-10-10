export interface Environment {
  production: boolean;
  useMocks: boolean;
  apiUrl: string;
  /** Bare server origin (no `/api` suffix), e.g. the Mac on the LAN. */
  backendUrl: string;
}
