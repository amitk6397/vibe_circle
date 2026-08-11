import { Purpose } from '../../../types';

export type DiscoveryFilter = {
  query: string;
  purpose?: Purpose;
  language?: string;
  onlineOnly: boolean;
  minimumAge: number;
  maximumAge: number;
};
