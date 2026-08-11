import React, { useCallback, useState } from 'react';
import { Alert, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { EmptyState, Header, PersonCard, Screen, ui } from '../../../components/ui';
import { discoveryApi } from '../../../services/api';
import { Person } from '../../../types';

const colour = ['#5B5CE2', '#2FB67C', '#FF6B6B', '#8B6BD9'];

export function RecommendedPeopleScreen({ navigation }: any) {
  const [people, setPeople] = useState<Person[]>([]);
  const [loading, setLoading] = useState(true);
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await discoveryApi.recommendedPeople({ limit: 30 });
      setPeople(
        data.map((item, index) => ({
          id: item.id,
          name: item.name,
          age: item.age,
          username: item.username || '',
          bio: item.bio,
          city: item.city,
          languages: item.languages,
          interests: item.interests,
          online: item.is_online,
          avatarColor: colour[index % colour.length],
          conversationTopics: item.conversation_topics,
          performanceRating: item.performance_rating,
          reviewCount: item.review_count,
          completedSessions: item.completed_sessions,
          performanceTier: item.performance_tier,
          recommendationReasons: [
            ...(item.performance_tier === 'top_performer' ? ['Top performer'] : []),
            ...(item.review_count
              ? [`${item.performance_rating?.toFixed(1)} rating · ${item.review_count} reviews`]
              : []),
            ...(item.is_online ? ['Available now'] : []),
            ...(!item.review_count && !item.is_online ? ['New user'] : []),
          ],
        })),
      );
    } catch (error: any) {
      Alert.alert('Recommendations unavailable', error.message || 'Please try again.');
    } finally {
      setLoading(false);
    }
  }, []);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );

  const topPerformers = people.filter((person) => person.performanceTier === 'top_performer');
  const otherRecommendations = people.filter(
    (person) => person.performanceTier !== 'top_performer',
  );
  const renderPerson = (person: Person) => (
    <View key={person.id}>
      <PersonCard
        person={person}
        onPress={() => navigation.navigate('PublicProfile', { personId: person.id })}
      />
      {!!person.recommendationReasons?.length && (
        <Text style={[ui.muted, { marginTop: -12, marginLeft: 14 }]}>
          {person.recommendationReasons.join(' · ')}
        </Text>
      )}
    </View>
  );

  return (
    <Screen>
      <Header
        title="Recommended people"
        subtitle="Review performance, interests, topics, and availability"
        onBack={() => navigation.goBack()}
      />
      {!!topPerformers.length && <Text style={ui.h2}>Top performers</Text>}
      {topPerformers.map(renderPerson)}
      {!!otherRecommendations.length && <Text style={ui.h2}>Other recommendations</Text>}
      {otherRecommendations.map(renderPerson)}
      {!loading && !people.length && (
        <EmptyState
          icon="people-outline"
          title="No recommendations yet"
          text="Add interests and conversation topics to receive relevant people."
        />
      )}
    </Screen>
  );
}
export default RecommendedPeopleScreen;
