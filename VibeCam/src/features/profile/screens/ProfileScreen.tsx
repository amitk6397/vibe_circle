import React, { useCallback, useState } from 'react';
import { useFocusEffect } from '@react-navigation/native';
import { Pressable, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Avatar, IconButton, Screen, ui } from '../../../components/ui';
import { colors } from '../../../theme';
import { useAppStore } from '../../../store/useAppStore';
import { usersApi } from '../../../services/api';
import { styles } from '../../shared-views/styles';

export function ProfileScreen({ navigation }: any) {
  const { profile, posts, joinedCommunities } = useAppStore();
  const [followerCount, setFollowerCount] = useState(0);
  const currentUserId = useAppStore((state) => state.currentUserId);
  useFocusEffect(
    useCallback(() => {
      void usersApi
        .connections()
        .then(({ data }) =>
          setFollowerCount(
            data.filter((item) => item.status === 'accepted' && item.receiver_id === currentUserId)
              .length,
          ),
        );
    }, [currentUserId]),
  );
  // Removed My Profile & Edit Profile from list — they live on the card buttons
  const menu = [
    ['heart-outline', 'Interests & languages', 'InterestsLanguages'],
    ['gift-outline', 'Daily Login Rewards 🎁', 'DailyRewards'],
    ['people-circle-outline', 'Refer & Earn 🪙', 'Referral'],
    ['time-outline', 'My activity', 'MyActivity'],
    ['grid-outline', 'My creations', 'MyCreations'],
    ['people-outline', 'Followers', 'Connections'],
    ['lock-closed-outline', 'Privacy settings', 'PrivacySettings'],
    ['sparkles-outline', 'Subscription plans', 'SubscriptionPlans'],
    ['wallet-outline', 'Wallet & earnings dashboard', 'Wallet'],
    ['ban-outline', 'Blocked users', 'BlockedUsers'],
    ['shield-checkmark-outline', 'My reports', 'Reports'],
    ['key-outline', 'Account management', 'AccountManagement'],
  ];
  return (
    <Screen>
      {/* Top row */}
      <View style={styles.topRow}>
        <Text style={ui.title}>Profile</Text>
        <IconButton
          icon="settings-outline"
          onPress={() => navigation.navigate('SettingsSupport')}
        />
      </View>

      {/* Profile hero card */}
      <View style={styles.profileHeroCard}>
        {/* Avatar centered */}
        <View style={styles.profileAvatarWrap}>
          <Avatar name={profile.name} uri={profile.avatarUri} size={90} />
        </View>
        <Text style={styles.profileHeroName}>{profile.name}</Text>
        <Text style={styles.profileHeroHandle}>@{profile.username}</Text>

        {/* Stats row */}
        <View style={styles.profileHeroStats}>
          <Pressable
            style={styles.profileHeroStat}
            onPress={() => navigation.navigate('MyCreations')}
          >
            <Text style={styles.profileHeroStatNum}>{posts.length}</Text>
            <Text style={styles.profileHeroStatLabel}>Posts</Text>
          </Pressable>
          <View style={styles.profileHeroStatDivider} />
          <Pressable style={styles.profileHeroStat}>
            <Text style={styles.profileHeroStatNum}>{joinedCommunities.length}</Text>
            <Text style={styles.profileHeroStatLabel}>Communities</Text>
          </Pressable>
          <View style={styles.profileHeroStatDivider} />
          <Pressable
            style={styles.profileHeroStat}
            onPress={() => navigation.navigate('Connections')}
          >
            <Text style={styles.profileHeroStatNum}>{followerCount}</Text>
            <Text style={styles.profileHeroStatLabel}>Followers</Text>
          </Pressable>
        </View>

        {/* Action buttons */}
        <View style={styles.profileHeroActions}>
          <Pressable style={styles.profileHeroBtn} onPress={() => navigation.navigate('MyProfile')}>
            <Ionicons name="person-outline" size={16} color={colors.primary} />
            <Text style={styles.profileHeroBtnText}>View Profile</Text>
          </Pressable>
          <Pressable
            style={[styles.profileHeroBtn, { backgroundColor: colors.primary }]}
            onPress={() => navigation.navigate('EditProfile')}
          >
            <Ionicons name="create-outline" size={16} color="#fff" />
            <Text style={[styles.profileHeroBtnText, { color: '#fff' }]}>Edit Profile</Text>
          </Pressable>
        </View>
      </View>

      {/* Menu items */}
      {menu.map(([icon, title, route]) => (
        <Pressable key={title} onPress={() => navigation.navigate(route)} style={styles.menu}>
          <View style={styles.menuIcon}>
            <Ionicons name={icon as any} size={20} color={colors.primary} />
          </View>
          <Text style={[styles.cardTitle, { flex: 1 }]}>{title}</Text>
          <Ionicons name="chevron-forward" color={colors.muted} />
        </Pressable>
      ))}
    </Screen>
  );
}

export default ProfileScreen;
