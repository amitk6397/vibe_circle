import { useEffect, useState } from 'react';
import { discoveryApi } from '../../../services/api';
import { useAppStore } from '../../../store/useAppStore';
import { Person } from '../../../types';

export function useDiscoveryViewModel(query = '') {
  const cachedPeople = useAppStore((state) => state.people);
  const [people, setPeople] = useState<Person[]>(cachedPeople);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    const request = query.trim()
      ? discoveryApi.search(query.trim()).then(({ data }: any) => data.users ?? [])
      : discoveryApi.users().then(({ data }) => data);

    request
      .then((items: any[]) => {
        if (!active) return;
        setPeople(
          items.map((item) => ({
            id: item.id,
            name: item.name,
            age: item.age,
            username: item.username || '',
            bio: item.bio || '',
            city: item.city || '',
            languages: item.languages || [],
            interests: item.interests || [],
            online: Boolean(item.is_online),
            avatarColor: '#6C63FF',
          })),
        );
      })
      .catch(() => active && setError('Unable to load recommendations.'))
      .finally(() => active && setLoading(false));

    return () => {
      active = false;
    };
  }, [query]);

  return { people, loading, error };
}
