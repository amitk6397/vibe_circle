import React, { useCallback, useState } from 'react';
import { Alert, FlatList, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { EmptyState, Header, PersonGridCard, Screen } from '../../../components/ui';
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
          avatarUrl: item.avatar_url || null,
          avatarColor: colour[index % colour.length],
          conversationTopics: item.conversation_topics,
          performanceRating: item.performance_rating,
          reviewCount: item.review_count,
          completedSessions: item.completed_sessions,
          performanceTier: item.performance_tier,
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

  return (
    <Screen scroll={false}>
      <Header
        title="Recommended people"
        subtitle="Top recommendations based on your preferences"
        onBack={() => navigation.goBack()}
      />
      <View style={{ flex: 1, padding: 18, paddingTop: 12, gap: 16 }}>
        {people.length > 0 ? (
          <FlatList
            data={people}
            keyExtractor={(p) => p.id}
            numColumns={2}
            columnWrapperStyle={{ gap: 10 }}
            contentContainerStyle={{ gap: 10, paddingBottom: 20 }}
            showsVerticalScrollIndicator={false}
            renderItem={({ item }) => (
              <PersonGridCard
                person={item}
                onPress={() => navigation.navigate('PublicProfile', { personId: item.id })}
              />
            )}
          />
        ) : (
          !loading && (
            <EmptyState
              icon="people-outline"
              title="No recommendations yet"
              text="Add interests and conversation topics to receive relevant people."
            />
          )
        )}
      </View>
    </Screen>
  );
}
export default RecommendedPeopleScreen;
