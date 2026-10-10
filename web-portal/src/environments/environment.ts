import { Environment } from './environment.model';

export type { Environment } from './environment.model';

export const environment: Environment = {
  production: false,
  useMocks: true,
  apiUrl: 'http://192.168.1.2:5039/api',
  backendUrl: 'http://192.168.1.2:5039',
};