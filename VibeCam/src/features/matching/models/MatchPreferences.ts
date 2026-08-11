import { Purpose } from '../../../types';

export type MatchPreferences = {
  purpose: Purpose;
  language: string;
  minimumAge: number;
  maximumAge: number;
  anonymous: boolean;
};
