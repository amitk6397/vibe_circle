import React, { useEffect, useState } from 'react';

import { Alert, Pressable, Switch, Text, View } from 'react-native';

import { Ionicons } from '@expo/vector-icons';

import {
  Avatar,
  Button,
  Card,
  CommunityCard,
  EmptyState,
  Field,
  Header,
  IconButton,
  PersonCard,
  Pill,
  PostCard,
  Screen,
  SearchField,
  Section,
  ui,
} from '../../../components/ui';

import { ChatSkeleton } from '../../../components/ChatSkeleton';

import { LANGUAGES, PURPOSES } from '../../../constants/data';

import { colors } from '../../../theme';

import { Purpose } from '../../../types';

import { useAppStore } from '../../../store/useAppStore';

import { chatApi, discoveryApi, safetyApi, usersApi } from '../../../services/api';

import { styles } from '../../shared-views/styles';

export function SearchFiltersScreen({ navigation }: any) {
  const { searchFilters, setSearchFilters } = useAppStore();
  const [purpose, setPurpose] = useState<Purpose>(searchFilters.purpose);
  const [language, setLanguage] = useState(searchFilters.language);
  const [ageRange, setAgeRange] = useState(`${searchFilters.minAge}-${searchFilters.maxAge}`);
  const [online, setOnline] = useState(searchFilters.onlineOnly);
  const [gender, setGender] = useState(searchFilters.gender);
  const [city, setCity] = useState(searchFilters.city);

  const ageRangeValid = /^\s*(1[89]|[2-9]\d)\s*-\s*(1[89]|[2-9]\d)\s*$/.test(ageRange);

  const apply = () => {
    if (!ageRangeValid) return;
    const parts = ageRange.split('-');
    const minAge = parseInt(parts[0].trim(), 10);
    const maxAge = parseInt(parts[1].trim(), 10);
    setSearchFilters({
      purpose,
      language,
      minAge,
      maxAge,
      onlineOnly: online,
      gender,
      city: city.trim(),
    });
    navigation.goBack();
  };

  return (
    <Screen>
      <Header
        title="Search filters"
        subtitle="Control who appears in discovery"
        onBack={() => navigation.goBack()}
      />
      <Text style={ui.h2}>Purpose</Text>
      <View style={ui.wrap}>
        {PURPOSES.map((x) => (
          <Pill
            key={x.name}
            label={x.name}
            selected={purpose === x.name}
            onPress={() => setPurpose(x.name)}
          />
        ))}
      </View>
      <Text style={ui.h2}>Gender</Text>
      <View style={ui.wrap}>
        {['Any', 'Male', 'Female', 'Non-binary'].map((g) => (
          <Pill
            key={g}
            label={g}
            selected={gender === g}
            onPress={() => setGender(g)}
          />
        ))}
      </View>
      <Text style={ui.h2}>Language</Text>
      <View style={ui.wrap}>
        {LANGUAGES.map((x) => (
          <Pill key={x} label={x} selected={language === x} onPress={() => setLanguage(x)} />
        ))}
      </View>
      <Field
        label="City"
        value={city}
        onChangeText={setCity}
        placeholder="Enter city name (optional)"
      />
      <Field
        label="Age range"
        value={ageRange}
        onChangeText={setAgeRange}
        placeholder="18-35"
        keyboardType="numbers-and-punctuation"
        error={!ageRangeValid ? 'Use a range like 18-35' : undefined}
      />
      <Card style={styles.listRow}>
        <Text style={[ui.body, { flex: 1 }]}>Online now only</Text>
        <Switch value={online} onValueChange={setOnline} trackColor={{ true: colors.primary }} />
      </Card>
      <Button title="Apply filters" disabled={!ageRangeValid} onPress={apply} />
    </Screen>
  );
}

function reportAlert(
  targetType: 'user' | 'post' | 'comment' | 'community' | 'room',
  targetId: string,
  targetLabel: string,
) {
  const submit = (reason: string) => {
    void safetyApi
      .report(targetType, targetId, reason)
      .then(() =>
        Alert.alert('Report submitted', 'Thank you. Our safety team will review your report.'),
      )
      .catch((error) => Alert.alert('Report failed', error.message || 'Please try again.'));
  };
  Alert.alert(
    'Report safely',
    `Choose a reason for reporting ${targetLabel}. Only relevant evidence will be shared with moderators.`,
    [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Spam or scam', onPress: () => submit('Spam or scam') },
      { text: 'Harassment', style: 'destructive', onPress: () => submit('Harassment') },
    ],
  );
}

export default SearchFiltersScreen;
