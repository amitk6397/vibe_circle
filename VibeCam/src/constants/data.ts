import { Purpose } from '../types';

// Taxonomy/configuration values only. Runtime users and content always come from the API.
export const PURPOSES: { name: Purpose; icon: string; subtitle: string; color: string }[] = [
  { name: 'Talk', icon: 'chatbubbles', subtitle: 'A relaxed conversation', color: '#D62976' },
  { name: 'Friends', icon: 'people', subtitle: 'Meet your kind of people', color: '#2878D7' },
  { name: 'Advice', icon: 'bulb', subtitle: 'Ask and share experience', color: '#E99528' },
  { name: 'Learn', icon: 'school', subtitle: 'Practice and grow together', color: '#20A875' },
  { name: 'Support', icon: 'heart', subtitle: 'Find a safe listener', color: '#A044B2' },
  { name: 'Fun', icon: 'sparkles', subtitle: 'Games and good vibes', color: '#F05283' },
  { name: 'Local', icon: 'location', subtitle: 'Connect around your city', color: '#168F94' },
];

export const INTERESTS = [
  'Coding',
  'Career',
  'Books',
  'English',
  'Fitness',
  'Movies',
  'Travel',
  'Cricket',
  'Design',
  'Music',
  'Startups',
  'Wellbeing',
];

export const LANGUAGES = ['English', 'Hindi', 'Gujarati', 'Marathi', 'Kannada', 'Tamil', 'Bengali'];
