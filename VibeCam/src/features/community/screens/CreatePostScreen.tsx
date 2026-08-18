import React, { useCallback, useEffect, useRef, useState } from 'react';

import { useFocusEffect } from '@react-navigation/native';

import { useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  ActivityIndicator,
  Alert,
  Animated,
  Dimensions,
  Image,
  Modal,
  PanResponder,
  Pressable,
  ScrollView,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';

import { Ionicons } from '@expo/vector-icons';

import { LinearGradient } from 'expo-linear-gradient';

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
  ShareModal,
  ui,
} from '../../../components/ui';

import { ChatSkeleton } from '../../../components/ChatSkeleton';

import { LANGUAGES, PURPOSES } from '../../../constants/data';

import { colors } from '../../../theme';

import { LocalAttachment, Post, Purpose } from '../../../types';

import { useAppStore } from '../../../store/useAppStore';

import {
  formatFileSize,
  pickDocument,
  pickImage,
  pickStoryImages,
} from '../../../services/mediaPicker';

import {
  chatApi,
  contentApi,
  discoveryApi,
  matchingApi,
  notificationsApi,
  safetyApi,
  storyApi,
  uploadAttachment,
  usersApi,
  walletApi,
} from '../../../services/api';

import { useInboxSync, usePrivateRealtime } from '../../chat/viewmodels/useRealtimeChat';

import { styles } from '../../shared-views/styles';

import { ProfileScreen } from '../../profile/screens/ProfileScreen';

import { MyCreationsScreen } from '../../profile/screens/MyCreationsScreen';

export function CreatePostScreen({ navigation, route }: any) {
  const [body, setBody] = useState('');
  const [anonymous, setAnonymous] = useState(false);
  const [postType, setPostType] = useState<'Text' | 'Question' | 'Poll' | 'Image'>('Text');
  const [attachment, setAttachment] = useState<LocalAttachment | null>(null);
  const [pollOptions, setPollOptions] = useState(['', '']);
  const [publishing, setPublishing] = useState(false);
  const [visibility, setVisibility] = useState<'public' | 'private'>('public');
  const [privatePostCoins, setPrivatePostCoins] = useState(0);
  const [postPriceMinCoins, setPostPriceMinCoins] = useState(5);
  const [postPriceMaxCoins, setPostPriceMaxCoins] = useState(500);
  const [customPrice, setCustomPrice] = useState('');
  const [bountyAmount, setBountyAmount] = useState('');
  const [postDeductionEnabled, setPostDeductionEnabled] = useState(false);
  const [publicPostPriceCoins, setPublicPostPriceCoins] = useState(0);
  const [privatePostPriceCoins, setPrivatePostPriceCoins] = useState(0);
  const profile = useAppStore((state) => state.profile);
  useEffect(() => {
    void walletApi.pricing().then(({ data }) => {
      setPrivatePostCoins(data.privatePostCoins);
      if (data.postPriceMinCoins) setPostPriceMinCoins(data.postPriceMinCoins);
      if (data.postPriceMaxCoins) setPostPriceMaxCoins(data.postPriceMaxCoins);
      if (data.postDeductionEnabled) setPostDeductionEnabled(data.postDeductionEnabled);
      if (data.publicPostPriceCoins !== undefined) setPublicPostPriceCoins(data.publicPostPriceCoins);
      if (data.privatePostPriceCoins !== undefined) setPrivatePostPriceCoins(data.privatePostPriceCoins);
    });
  }, []);
  const community = useAppStore((state) =>
    state.communities.find((item) => item.id === route.params?.communityId),
  );
  const chooseType = async (nextType: typeof postType) => {
    setPostType(nextType);
    if (nextType === 'Image') setAttachment(await pickImage());
    else setAttachment(null);
  };
  const pollValid = postType !== 'Poll' || pollOptions.every((option) => option.trim().length >= 2);
  return (
    <Screen>
      <Header
        title="Create post"
        subtitle={
          community
            ? `Posting in ${community.name}`
            : 'Share something useful or start a conversation.'
        }
        onBack={() => navigation.goBack()}
      />
      <LinearGradient colors={['#2A1F3D', '#1E2540']} style={styles.createPostHero}>
        <View style={styles.createPostStep}>
          <Ionicons name="create-outline" size={19} color="#fff" />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.createPostHeroTitle}>Create something meaningful</Text>
          <Text style={styles.smallMuted}>
            Choose a format, write your post and control who can view it.
          </Text>
        </View>
      </LinearGradient>
      <Card style={styles.postComposerCard}>
        <View style={styles.createAuthorRow}>
          <Avatar
            name={anonymous ? 'Anonymous' : profile.name}
            size={42}
            color={anonymous ? colors.muted : colors.primary}
          />
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>{anonymous ? 'Posting anonymously' : profile.name}</Text>
            <Text style={styles.smallMuted}>{community ? community.name : 'Public feed'}</Text>
          </View>
          <View style={styles.draftBadge}>
            <Text style={styles.draftBadgeText}>DRAFT</Text>
          </View>
        </View>
        <TextInput
          value={body}
          onChangeText={(value) => setBody(value.slice(0, 1200))}
          multiline
          placeholder="Share an idea, question or experience..."
          placeholderTextColor={colors.muted}
          style={styles.postComposerInput}
        />
        <View style={styles.composerFooter}>
          <Text style={styles.smallMuted}>Be useful, kind and authentic</Text>
          <Text style={styles.characterCount}>{body.length}/1200</Text>
        </View>
      </Card>
      <Text style={ui.h2}>Choose format</Text>
      <View style={styles.postTypeGrid}>
        {(['Text', 'Question', 'Poll', 'Image'] as const).map((type) => {
          const icon =
            type === 'Text'
              ? 'document-text-outline'
              : type === 'Question'
                ? 'help-circle-outline'
                : type === 'Poll'
                  ? 'stats-chart-outline'
                  : 'image-outline';
          return (
            <Pressable
              key={type}
              onPress={() => void chooseType(type)}
              style={[styles.postTypeOption, postType === type && styles.postTypeOptionActive]}
            >
              <Ionicons name={icon} size={21} color={postType === type ? '#fff' : colors.primary} />
              <Text style={[styles.postTypeText, postType === type && { color: '#fff' }]}>
                {type}
              </Text>
            </Pressable>
          );
        })}
      </View>
      {postType === 'Poll' &&
        pollOptions.map((option, index) => (
          <Field
            key={index}
            label={`Option ${index + 1}`}
            value={option}
            onChangeText={(value: string) =>
              setPollOptions((current) =>
                current.map((item, optionIndex) => (optionIndex === index ? value : item)),
              )
            }
            placeholder="Add an answer"
          />
        ))}
      {postType === 'Question' && (
        <Card style={{ marginVertical: 10, padding: 12 }}>
          <Text style={[ui.h2, { color: colors.primary, marginBottom: 4, fontSize: 16 }]}>Attach a coin bounty (Ask & Earn) 🏆</Text>
          <Text style={[ui.muted, { fontSize: 12, marginBottom: 8 }]}>
            Give incentive for detailed, helpful answers. Best answer receives the bounty!
          </Text>
          <TextInput
            keyboardType="number-pad"
            value={bountyAmount}
            onChangeText={setBountyAmount}
            placeholder="Min 10 coins (Optional)"
            placeholderTextColor={colors.muted}
            style={[styles.postComposerInput, { borderWidth: 1, borderColor: colors.border, paddingHorizontal: 10, marginTop: 4, height: 45, borderRadius: 8 }]}
          />
        </Card>
      )}
      {attachment && (
        <Pressable
          style={styles.createImagePreview}
          onPress={() => navigation.navigate('MediaPreview', { attachment })}
        >
          <Image source={{ uri: attachment.uri }} style={styles.attachmentImage} />
          <Text style={styles.smallMuted}>Tap to preview · Change by selecting Image again</Text>
        </Pressable>
      )}
      <Card style={styles.listRow}>
        <View style={{ flex: 1 }}>
          <Text style={styles.cardTitle}>Post anonymously</Text>
          <Text style={styles.smallMuted}>Your identity remains private to other members.</Text>
        </View>
        <Switch
          value={anonymous}
          onValueChange={setAnonymous}
          trackColor={{ true: colors.primary }}
        />
      </Card>
      <Text style={ui.h2}>Who can view?</Text>
      <View style={styles.visibilitySelector}>
        <Pill
          label="Public"
          selected={visibility === 'public'}
          onPress={() => setVisibility('public')}
        />
        <Pill
          label="Private · paid"
          selected={visibility === 'private'}
          onPress={() => setVisibility('private')}
        />
      </View>
      {visibility === 'private' && (
        <Card style={{ padding: 12 }}>
          <Text style={[ui.h2, { fontSize: 16, color: colors.primary, marginBottom: 4 }]}>Set unlock price (Tiered Pricing) 🪙</Text>
          <Text style={[ui.muted, { fontSize: 12, marginBottom: 8 }]}>
            Set the price in coins users must pay to unlock. Allowed range: {postPriceMinCoins} to {postPriceMaxCoins} coins.
          </Text>
          <TextInput
            keyboardType="number-pad"
            value={customPrice}
            onChangeText={setCustomPrice}
            placeholder={`Default is ${privatePostCoins} coins`}
            placeholderTextColor={colors.muted}
            style={[styles.postComposerInput, { borderWidth: 1, borderColor: colors.border, paddingHorizontal: 10, marginTop: 4, height: 45, borderRadius: 8 }]}
          />
        </Card>
      )}
      {postDeductionEnabled && (
        <Card style={{ padding: 12, marginVertical: 8, borderColor: colors.border, borderWidth: 1 }}>
          <Text style={[ui.body, { fontWeight: '600', color: '#E79B32', marginBottom: 2 }]}>
            Post Creation Fee: {visibility === 'private' ? privatePostPriceCoins : publicPostPriceCoins} coins
          </Text>
          <Text style={[ui.muted, { fontSize: 12 }]}>
            Publishing a {visibility} post will deduct {visibility === 'private' ? privatePostPriceCoins : publicPostPriceCoins} coins from your wallet balance.
          </Text>
        </Card>
      )}
      <Button
        title="Publish post"
        loading={publishing}
        disabled={body.trim().length < 3 || !pollValid || (postType === 'Image' && !attachment)}
        onPress={async () => {
          const price = customPrice.trim() ? parseInt(customPrice, 10) : undefined;
          if (price !== undefined && (isNaN(price) || price < postPriceMinCoins || price > postPriceMaxCoins)) {
            return Alert.alert('Invalid Price', `Post price must be between ${postPriceMinCoins} and ${postPriceMaxCoins} coins.`);
          }
          setPublishing(true);
          try {
            await useAppStore.getState().createPost(body.trim(), anonymous, {
              postType,
              attachment: attachment ?? undefined,
              pollOptions:
                postType === 'Poll' ? pollOptions.map((option) => option.trim()) : undefined,
              communityId: community?.id,
              visibility,
              bountyAmount: bountyAmount.trim() ? parseInt(bountyAmount, 10) : undefined,
              coinPrice: price,
            });
            navigation.goBack();
          } catch (error: any) {
            Alert.alert('Could not publish post', error.message || 'Please try again.');
          } finally {
            setPublishing(false);
          }
        }}
      />
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

export default CreatePostScreen;
