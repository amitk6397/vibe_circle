import React from 'react';
import {
  ActivityIndicator,
  Alert,
  Animated,
  Dimensions,
  Image,
  Linking,
  Modal,
  Pressable,
  ScrollView,
  Share,
  StyleProp,
  StyleSheet,
  Text,
  TextInput,
  View,
  Vibration,
  ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors, gradients } from '../theme';
import { Community, Person, Post } from '../types';
import { useAppStore } from '../store/useAppStore';
import { contentApi, safetyApi, usersApi, engagementApi } from '../services/api';
import { CoinSpendAnimation } from './CoinAnimation';
import { environment } from '../config/environment';

export function resolveImageUrl(url: string | null | undefined): string | null {
  return getAbsoluteUri(url || undefined) || null;
}

export function renderGiftIcon(icon: string | null | undefined, size = 16) {
  const resolved = resolveImageUrl(icon);
  if (resolved && (resolved.startsWith('http') || resolved.startsWith('/'))) {
    return (
      <Image
        source={{ uri: resolved }}
        style={{ width: size, height: size, borderRadius: 4 }}
        resizeMode="contain"
      />
    );
  }
  return <Text style={{ fontSize: size }}>{icon || '🎁'}</Text>;
}


const dark = {
  background: '#242837',
  surface: '#2E3347',
  surfaceAlt: '#38405A',
  border: '#3D4460',
  text: '#EEF2FF',
  muted: '#8892A4',
};

function themedChildren(children: React.ReactNode, enabled: boolean): React.ReactNode {
  if (!enabled) return children;
  return React.Children.map(children, (child) => {
    if (!React.isValidElement(child)) return child;
    const props = child.props as any;
    const nested = props.children ? themedChildren(props.children, enabled) : props.children;
    if (child.type === Text) {
      const current = StyleSheet.flatten(props.style) || {};
      const color =
        current.color === colors.muted
          ? dark.muted
          : !current.color || current.color === colors.text
            ? dark.text
            : current.color;
      return React.cloneElement(child as any, {
        ...props,
        children: nested,
        style: [props.style, { color }],
      });
    }
    if (child.type === TextInput) {
      return React.cloneElement(child as any, {
        ...props,
        children: nested,
        placeholderTextColor: dark.muted,
        style: [
          props.style,
          { color: dark.text, backgroundColor: dark.surface, borderColor: dark.border },
        ],
      });
    }
    if (child.type === View) {
      const current = StyleSheet.flatten(props.style) || {};
      const backgroundColor =
        current.backgroundColor === colors.surface
          ? dark.surface
          : current.backgroundColor === colors.surfaceAlt || current.backgroundColor === colors.bg
            ? dark.surfaceAlt
            : undefined;
      return React.cloneElement(child as any, {
        ...props,
        children: nested,
        style: backgroundColor ? [props.style, { backgroundColor }] : props.style,
      });
    }
    return React.cloneElement(child as any, { ...props, children: nested });
  });
}

export function Screen({
  children,
  scroll = true,
  style,
  edges = ['top', 'left', 'right', 'bottom'],
  noPadding = false,
}: {
  children: React.ReactNode;
  scroll?: boolean;
  style?: StyleProp<ViewStyle>;
  edges?: ('top' | 'right' | 'bottom' | 'left')[];
  noPadding?: boolean;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  const childrenArray = React.Children.toArray(children);
  const headerIndex = childrenArray.findIndex(
    (child) => React.isValidElement(child) && child.type === Header
  );

  let header: React.ReactNode = null;
  let remainingChildren = childrenArray;

  if (headerIndex !== -1) {
    header = childrenArray[headerIndex];
    remainingChildren = childrenArray.filter((_, idx) => idx !== headerIndex);
  }

  const themedHeader = header ? themedChildren(header, darkMode) : null;
  const themedContent = themedChildren(remainingChildren, darkMode);
  const bgStyle = darkMode ? { backgroundColor: dark.background } : { backgroundColor: colors.bg };

  return (
    <SafeAreaView style={[styles.screen, bgStyle, style]} edges={edges}>
      {themedHeader}
      {scroll ? (
        <ScrollView
          style={{ flex: 1 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
          contentContainerStyle={[styles.content, noPadding && { padding: 0, paddingHorizontal: 0 }]}
        >
          {themedContent}
        </ScrollView>
      ) : (
        <View style={{ flex: 1, padding: noPadding ? 0 : undefined }}>
          {themedContent}
        </View>
      )}
    </SafeAreaView>
  );
}

export function Header({
  title,
  subtitle,
  onBack,
  right,
}: {
  title: string;
  subtitle?: string;
  onBack?: () => void;
  right?: React.ReactNode;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <View style={styles.header}>
      {onBack && <IconButton icon="arrow-back" onPress={onBack} />}
      <View style={{ flex: 1 }}>
        <Text style={[styles.headerTitle, darkMode && { color: '#F5F7FF' }]}>{title}</Text>
        {subtitle && (
          <Text style={[styles.muted, darkMode && { color: '#AAB0C5' }]}>{subtitle}</Text>
        )}
      </View>
      {right}
    </View>
  );
}

export function Button({
  title,
  onPress,
  icon,
  tone = 'primary',
  disabled = false,
  compact = false,
  loading = false,
}: {
  title: string;
  onPress: () => void;
  icon?: string;
  tone?: 'primary' | 'secondary' | 'danger' | 'ghost';
  disabled?: boolean;
  compact?: boolean;
  loading?: boolean;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  if (tone === 'primary')
    return (
      <Pressable
        disabled={disabled}
        onPress={onPress}
        onPressIn={() => !disabled && Vibration.vibrate(8)}
        style={({ pressed }) => ({
          opacity: disabled ? 0.45 : pressed ? 0.82 : 1,
          transform: [{ scale: pressed ? 0.98 : 1 }],
        })}
      >
        <LinearGradient
          colors={gradients.primary}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={[styles.button, compact && styles.compactButton]}
        >
          {loading ? (
            <ActivityIndicator size="small" color="#fff" />
          ) : (
            icon && <Ionicons name={icon as any} size={18} color="#fff" />
          )}
          <Text style={styles.buttonText}>{title}</Text>
        </LinearGradient>
      </Pressable>
    );
  return (
    <Pressable
      disabled={disabled}
      onPress={onPress}
      onPressIn={() => !disabled && Vibration.vibrate(8)}
      style={({ pressed }) => [
        styles.button,
        compact && styles.compactButton,
        styles[(tone + 'Button') as 'secondaryButton'],
        darkMode &&
          tone !== 'ghost' && { backgroundColor: dark.surfaceAlt, borderColor: dark.border },
        {
          opacity: disabled ? 0.45 : pressed ? 0.7 : 1,
          transform: [{ scale: pressed ? 0.98 : 1 }],
        },
      ]}
    >
      {loading ? (
        <ActivityIndicator
          size="small"
          color={tone === 'danger' ? colors.danger : colors.primary}
        />
      ) : icon ? (
        <Ionicons
          name={icon as any}
          size={18}
          color={tone === 'danger' ? colors.danger : colors.primary}
        />
      ) : null}
      <Text style={[styles.altButtonText, tone === 'danger' && { color: colors.danger }]}>
        {title}
      </Text>
    </Pressable>
  );
}

export function IconButton({
  icon,
  onPress,
  badge,
}: {
  icon: string;
  onPress: () => void;
  badge?: number;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <Pressable
      onPress={onPress}
      onPressIn={() => Vibration.vibrate(8)}
      style={({ pressed }) => [
        styles.iconButton,
        darkMode && { backgroundColor: dark.surface, borderColor: dark.border },
        pressed && { opacity: 0.55, transform: [{ scale: 0.92 }] },
      ]}
    >
      <Ionicons name={icon as any} size={22} color={darkMode ? dark.text : colors.text} />
      {!!badge && (
        <View style={styles.badge}>
          <Text style={styles.badgeText}>{badge}</Text>
        </View>
      )}
    </Pressable>
  );
}

export function Card({
  children,
  style,
  onPress,
}: {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  onPress?: () => void;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <Pressable
      disabled={!onPress}
      onPress={onPress}
      onPressIn={() => onPress && Vibration.vibrate(8)}
      style={({ pressed }) => [
        styles.card,
        darkMode && { backgroundColor: '#181C30', borderColor: '#2B304A' },
        style,
        pressed && onPress ? { opacity: 0.72, transform: [{ scale: 0.992 }] } : null,
      ]}
    >
      {themedChildren(children, darkMode)}
    </Pressable>
  );
}

export function Field({
  label,
  value,
  onChangeText,
  placeholder,
  secureTextEntry,
  keyboardType,
  multiline,
}: any) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <View style={{ gap: 7 }}>
      <Text style={[styles.label, darkMode && { color: dark.text }]}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={darkMode ? dark.muted : '#A1A5B3'}
        secureTextEntry={secureTextEntry}
        keyboardType={keyboardType}
        multiline={multiline}
        style={[
          styles.field,
          darkMode && { backgroundColor: dark.surface, borderColor: dark.border, color: dark.text },
          multiline && { minHeight: 110, textAlignVertical: 'top' },
        ]}
      />
    </View>
  );
}

export function SearchField({
  value,
  onChangeText,
  placeholder = 'Search people, communities and posts',
}: {
  value: string;
  onChangeText: (value: string) => void;
  placeholder?: string;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <View
      style={[
        styles.search,
        darkMode && { backgroundColor: dark.surface, borderColor: dark.border },
      ]}
    >
      <Ionicons name="search" size={20} color={colors.muted} />
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={darkMode ? dark.muted : colors.muted}
        style={{ flex: 1, color: darkMode ? dark.text : colors.text }}
      />
    </View>
  );
}

export function Section({
  title,
  action,
  onAction,
}: {
  title: string;
  action?: string;
  onAction?: () => void;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, darkMode && { color: dark.text }]}>{title}</Text>
      {action && (
        <Pressable onPress={onAction}>
          <Text style={styles.link}>{action}</Text>
        </Pressable>
      )}
    </View>
  );
}

const getAbsoluteUri = (uri?: string) => {
  if (!uri) return undefined;
  const trimmed = uri.trim();
  if (!trimmed || trimmed === 'null' || trimmed === 'None') return undefined;

  const base = environment.apiUrl.split('/api/')[0];

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    // If it's a backend attachment URL, rewrite the host to match current API origin
    if (trimmed.includes('/uploads/')) {
      try {
        const match = trimmed.match(/^https?:\/\/[^\/]+/);
        if (match) {
          return trimmed.replace(match[0], base);
        }
      } catch (e) {
        // fallback
      }
    }
    return trimmed;
  }

  if (
    trimmed.startsWith('data:') ||
    trimmed.startsWith('file://') ||
    trimmed.startsWith('content://')
  ) {
    return trimmed;
  }

  return `${base}${trimmed.startsWith('/') ? '' : '/'}${trimmed}`;
};

const getInitials = (name?: string) => {
  if (!name || !name.trim()) return '?';
  const parts = name.trim().split(/\s+/);
  return parts
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
};

export function Avatar({
  name,
  color = colors.primary,
  size = 48,
  online,
  uri,
}: {
  name: string;
  color?: string;
  size?: number;
  online?: boolean;
  uri?: string;
}) {
  const absoluteUri = getAbsoluteUri(uri);

  return (
    <View>
      <View
        style={[
          styles.avatar,
          { width: size, height: size, borderRadius: size / 2, backgroundColor: color },
        ]}
      >
        {absoluteUri ? (
          <Image source={{ uri: absoluteUri }} style={{ width: size, height: size, borderRadius: size / 2 }} />
        ) : (
          <Text style={[styles.avatarText, { fontSize: size * 0.35 }]}>
            {getInitials(name)}
          </Text>
        )}
      </View>
      {online && <View style={styles.online} />}
    </View>
  );
}

export function Pill({
  label,
  selected,
  onPress,
  color,
}: {
  label: string;
  selected?: boolean;
  onPress?: () => void;
  color?: string;
}) {
  const darkMode = useAppStore((state) => state.darkMode);
  return (
    <Pressable
      onPress={onPress}
      disabled={!onPress}
      style={[
        styles.pill,
        darkMode && { backgroundColor: dark.surfaceAlt, borderColor: dark.border },
        selected && {
          backgroundColor: color || colors.primary,
          borderColor: color || colors.primary,
        },
      ]}
    >
      <Text
        style={[styles.pillText, darkMode && { color: dark.muted }, selected && { color: '#fff' }]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

export function PersonCard({ person, onPress }: { person: Person; onPress: () => void }) {
  return (
    <Card onPress={onPress} style={styles.row}>
      <Avatar name={person.name} color={person.avatarColor} online={person.online} uri={person.avatarUrl || undefined} />
      <View style={{ flex: 1, gap: 4 }}>
        <View style={styles.inline}>
          <Text style={[styles.cardTitle, { fontSize: 15, fontWeight: '700' }]}>
            {person.name}, {person.age}
          </Text>
          {person.trusted && <Ionicons name="shield-checkmark" color={colors.info} size={16} />}
        </View>
        <Text style={[styles.muted, { fontSize: 12 }]} numberOfLines={1}>
          @{person.username} · {person.languages.join(', ')}
        </Text>
        <View style={[styles.tags, { marginTop: 6 }]}>
          {person.interests.slice(0, 2).map((interest) => (
            <View
              key={interest}
              style={{
                paddingHorizontal: 8,
                paddingVertical: 3,
                borderRadius: 6,
                backgroundColor: 'rgba(108, 93, 211, 0.06)',
                borderColor: 'rgba(108, 93, 211, 0.12)',
                borderWidth: 0.5,
              }}
            >
              <Text style={{ fontSize: 10, color: colors.primary, fontWeight: '700' }}>
                {interest}
              </Text>
            </View>
          ))}
        </View>
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.muted} style={{ marginLeft: 4 }} />
    </Card>
  );
}

export function PersonGridCard({ person, onPress }: { person: Person; onPress: () => void }) {
  const hasPhoto = !!person.avatarUrl;
  const photoUrl = resolveImageUrl(person.avatarUrl);
  const bgColor = person.avatarColor || '#5B5CE2';
  const initial = (person.name || '?')[0].toUpperCase();

  return (
    <Pressable style={styles.gridCard} onPress={onPress}>
      {/* Full-card image or gradient background */}
      {hasPhoto && photoUrl ? (
        <Image source={{ uri: photoUrl }} style={StyleSheet.absoluteFill} resizeMode="cover" />
      ) : (
        <LinearGradient
          colors={[bgColor, bgColor + 'AA']}
          style={StyleSheet.absoluteFill}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        />
      )}

      {/* Initials shown when no photo */}
      {!hasPhoto && (
        <View style={styles.gridInitialWrapper}>
          <Text style={styles.gridInitial}>{initial}</Text>
        </View>
      )}

      {/* Online indicator */}
      {person.online && (
        <View style={styles.onlineDot}>
          <View style={styles.onlineDotInner} />
        </View>
      )}

      {/* Bottom gradient overlay with user details */}
      <LinearGradient
        colors={['transparent', 'rgba(0,0,0,0.85)']}
        style={styles.gridOverlay}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
      >
        <Text style={styles.gridName} numberOfLines={1}>{person.name}</Text>
        {person.city ? (
          <View style={styles.gridDetailRow}>
            <Ionicons name="location-outline" size={11} color="rgba(255,255,255,0.7)" />
            <Text style={styles.gridDetailText} numberOfLines={1}>{person.city}</Text>
          </View>
        ) : null}
        {/* Interest tags */}
        <View style={styles.gridTags}>
          {(person.interests || []).slice(0, 2).map((tag: string) => (
            <View key={tag} style={styles.gridTag}>
              <Text style={styles.gridTagText} numberOfLines={1}>{tag}</Text>
            </View>
          ))}
        </View>
      </LinearGradient>
    </Pressable>
  );
}

export function CommunityCard({
  community,
  onPress,
}: {
  community: Community;
  onPress: () => void;
}) {
  const joined = useAppStore((s) => s.joinedCommunities.includes(community.id));
  return (
    <Card onPress={onPress}>
      <View style={styles.row}>
        <View style={[styles.communityIcon, { backgroundColor: community.color }]}>
          <Ionicons name="people" size={23} color="#fff" />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.cardTitle}>{community.name}</Text>
          <Text style={styles.muted}>
            {community.category} · {community.members.toLocaleString()} members
          </Text>
        </View>
        {joined && <Pill label="Joined" selected />}
      </View>
      <Text style={[styles.body, { marginTop: 12 }]}>{community.description}</Text>
    </Card>
  );
}

function parseUTCDate(value: string): Date {
  if (!value) return new Date();
  let normalized = value;
  if (!value.endsWith('Z') && !/[+-]\d{2}:\d{2}$/.test(value) && !value.includes('+')) {
    normalized = value.replace(' ', 'T') + 'Z';
  }
  return new Date(normalized);
}

export function formatRelativeDate(dateStr: string): string {
  if (!dateStr) return 'Just now';
  const now = new Date();
  const date = parseUTCDate(dateStr);

  const nowStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const dateStart = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  const oneDay = 24 * 60 * 60 * 1000;
  const diffDays = Math.round((dateStart - nowStart) / oneDay);

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Tomorrow';
  if (diffDays === -1) return 'Yesterday';

  if (diffDays < 0) {
    const daysAgo = Math.abs(diffDays);
    if (daysAgo < 7) {
      return `${daysAgo} day${daysAgo > 1 ? 's' : ''} ago`;
    }
    const weeksAgo = Math.floor(daysAgo / 7);
    if (weeksAgo < 4) {
      return `${weeksAgo} week${weeksAgo > 1 ? 's' : ''} ago`;
    }
    const monthsAgo = Math.floor(daysAgo / 30);
    if (monthsAgo < 12) {
      return `${monthsAgo} month${monthsAgo > 1 ? 's' : ''} ago`;
    }
    const yearsAgo = Math.floor(daysAgo / 365);
    return `${yearsAgo} year${yearsAgo > 1 ? 's' : ''} ago`;
  } else {
    if (diffDays < 7) {
      return `in ${diffDays} day${diffDays > 1 ? 's' : ''}`;
    }
    const weeksIn = Math.floor(diffDays / 7);
    if (weeksIn < 4) {
      return `in ${weeksIn} week${weeksIn > 1 ? 's' : ''}`;
    }
    const monthsIn = Math.floor(diffDays / 30);
    if (monthsIn < 12) {
      return `in ${monthsIn} month${monthsIn > 1 ? 's' : ''}`;
    }
    const yearsIn = Math.floor(diffDays / 365);
    return `in ${yearsIn} year${yearsIn > 1 ? 's' : ''}`;
  }
}

export function PostCard({
  post,
  onPress,
  onAuthorPress,
}: {
  post: Post;
  onPress?: () => void;
  onAuthorPress?: () => void;
}) {
  const { toggleLike, toggleSave, savedPosts } = useAppStore();
  const [imageOpen, setImageOpen] = React.useState(false);
  const [shareOpen, setShareOpen] = React.useState(false);
  const [voting, setVoting] = React.useState('');
  const [editing, setEditing] = React.useState(false);
  const [editBody, setEditBody] = React.useState(post.body);
  const [unlocking, setUnlocking] = React.useState(false);
  const [unlockCelebration, setUnlockCelebration] = React.useState(false);
  const unlockScale = React.useRef(new Animated.Value(1)).current;
  const coinBurst = React.useRef(new Animated.Value(0)).current;
  const [giftsOpen, setGiftsOpen] = React.useState(false);
  const [availableGifts, setAvailableGifts] = React.useState<any[]>([]);
  const [giftsLoading, setGiftsLoading] = React.useState(false);
  const [giftsError, setGiftsError] = React.useState(false);
  const [showSpend, setShowSpend] = React.useState(false);
  const [spendAmount, setSpendAmount] = React.useState(0);
  React.useEffect(() => {
    if (giftsOpen && !availableGifts.length && !giftsLoading) {
      setGiftsLoading(true);
      setGiftsError(false);
      engagementApi.gifts()
        .then(({ data }) => {
          setAvailableGifts(data || []);
          setGiftsError((data || []).length === 0);
        })
        .catch(() => setGiftsError(true))
        .finally(() => setGiftsLoading(false));
    }
  }, [giftsOpen, availableGifts.length, giftsLoading]);
  const sendPostGift = async (gift: any) => {
    try {
      await engagementApi.sendGift({
        gift_id: gift.id,
        recipient_id: post.authorId || '',
        target_type: 'post',
        target_id: post.id,
      });
      setGiftsOpen(false);
      setSpendAmount(gift.coin_price);
      setShowSpend(true);
      Alert.alert('Gift Sent! 🎁', `You sent a ${gift.name} (${gift.coin_price} coins) to ${post.author}.`);
      useAppStore.setState((state) => ({
        posts: state.posts.map((item) =>
          item.id === post.id
            ? {
                ...item,
                tipTotal: (item.tipTotal || 0) + gift.coin_price,
                tipCount: (item.tipCount || 0) + 1,
                gifts: [
                  ...((item as any).gifts || []),
                  {
                    id: Math.random().toString(),
                    gift_id: gift.id,
                    name: gift.name,
                    icon: gift.icon,
                    coin_price: gift.coin_price,
                  },
                ],
              }
            : item,
        ),
      }));
    } catch (error: any) {
      Alert.alert('Gifting failed', error.message || 'Check your balance and try again.');
    }
  };
  const totalVotes = Object.values(post.pollResults || {}).reduce((sum, count) => sum + count, 0);
  const vote = async (option: string) => {
    setVoting(option);
    try {
      const { data } = await contentApi.vote(post.id, option);
      useAppStore.setState((state) => ({
        posts: state.posts.map((item) =>
          item.id === post.id
            ? { ...item, myVote: data.option, pollResults: data.poll_results }
            : item,
        ),
      }));
    } catch (error: any) {
      Alert.alert('Could not submit vote', error.message || 'Please try again.');
    } finally {
      setVoting('');
    }
  };
  const unlockPrivatePost = async () => {
    if (unlocking) return;
    setUnlocking(true);
    Animated.sequence([
      Animated.timing(unlockScale, { toValue: 0.97, duration: 100, useNativeDriver: true }),
      Animated.spring(unlockScale, { toValue: 1, friction: 4, useNativeDriver: true }),
    ]).start();
    try {
      const { data } = await contentApi.unlockPost(post.id);
      Vibration.vibrate(45);
      setUnlockCelebration(true);
      coinBurst.setValue(0);
      Animated.sequence([
        Animated.spring(coinBurst, { toValue: 1, friction: 5, tension: 70, useNativeDriver: true }),
        Animated.delay(750),
        Animated.timing(coinBurst, { toValue: 0, duration: 220, useNativeDriver: true }),
      ]).start(() => setUnlockCelebration(false));
      useAppStore.setState((state) => ({
        posts: state.posts.map((item) =>
          item.id === post.id
            ? {
                ...item,
                body: data.body,
                locked: false,
                pollOptions: data.poll_options,
                pollResults: data.poll_results,
                attachment: data.media_url
                  ? { id: data.id, kind: 'image', uri: data.media_url, name: 'Post image' }
                  : undefined,
              }
            : item,
        ),
      }));
    } catch (error: any) {
      Alert.alert('Unlock failed', error.message || 'Check your coin balance and try again.');
    } finally {
      setUnlocking(false);
    }
  };
  return (
    <>
      <CoinSpendAnimation visible={showSpend} amount={spendAmount} onDone={() => setShowSpend(false)} />
      <Card onPress={onPress} style={styles.postCard}>
        {/* Instagram Header */}
        <View style={styles.instagramHeader}>
          <Pressable onPress={onAuthorPress} disabled={!onAuthorPress || post.anonymous}>
            <Avatar
              name={post.author}
              size={36}
              color={post.anonymous ? colors.muted : colors.primary}
              uri={post.anonymous ? undefined : (post.authorAvatarUrl || undefined)}
            />
          </Pressable>
          <View style={{ flex: 1, marginLeft: 10 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 6 }}>
              <Text style={styles.instagramAuthorName}>{post.author}</Text>
              {!post.anonymous && post.authorUsername && (
                <Text style={{ fontSize: 12, color: colors.accent, fontWeight: '600' }}>
                  @{post.authorUsername}
                </Text>
              )}
              {post.isBoosted && (
                <View style={styles.boostBadge}>
                  <Ionicons name="sparkles" size={10} color="#fff" />
                  <Text style={styles.boostBadgeText}>BOOSTED</Text>
                </View>
              )}
            </View>
            <Text style={styles.instagramSubtitle}>
              {post.community}
            </Text>
          </View>
          <IconButton
            icon="ellipsis-horizontal"
            onPress={() =>
              Alert.alert('Post options', 'Choose an action for this post.', [
                ...(post.mine
                  ? [
                      { text: 'Edit post', onPress: () => setEditing(true) },
                      {
                        text: 'Boost post (50 coins)',
                        onPress: async () => {
                          try {
                            const { data } = await contentApi.boostPost(post.id);
                            setSpendAmount(data.boost_cost || 50);
                            setShowSpend(true);
                            useAppStore.setState((state) => ({
                              posts: state.posts.map((item) =>
                                item.id === post.id
                                  ? {
                                      ...item,
                                      isBoosted: data.is_boosted,
                                      boostedUntil: data.boosted_until,
                                      boostCost: data.boost_cost,
                                    }
                                  : item,
                              ),
                            }));
                            Alert.alert(
                              'Post Boosted! 🚀',
                              'Your post is now pinned to the top of the feed.',
                            );
                          } catch (error: any) {
                            Alert.alert('Boost failed', error.message || 'Please check your coin balance and try again.');
                          }
                        },
                      },
                      {
                        text: 'Delete post',
                        style: 'destructive' as const,
                        onPress: () =>
                          void contentApi.deletePost(post.id).then(() =>
                            useAppStore.setState((state) => ({
                              posts: state.posts.filter((item) => item.id !== post.id),
                            })),
                          ),
                      },
                    ]
                  : []),
                {
                  text: 'Share',
                  onPress: () => setShareOpen(true),
                },
                {
                  text: savedPosts.includes(post.id) ? 'Remove from saved' : 'Save post',
                  onPress: () => toggleSave(post.id),
                },
                {
                  text: 'Report',
                  style: 'destructive',
                  onPress: () =>
                    void safetyApi
                      .report('post', post.id, 'Unsafe or inappropriate content')
                      .then(() =>
                        Alert.alert(
                          'Report submitted',
                          'Thank you. Our safety team will review it.',
                        ),
                      )
                      .catch((error) => Alert.alert('Report failed', error.message)),
                },
                { text: 'Cancel', style: 'cancel' },
              ])
            }
          />
        </View>

        {/* Bounty Banner */}
        {post.bountyAmount && post.bountyAmount > 0 ? (
          <View style={styles.bountyBanner}>
            <View style={styles.bountyHeader}>
              <Ionicons name="trophy" size={16} color="#E65100" />
              <Text style={styles.bountyTitle}>
                ASK & EARN BOUNTY: {post.bountyAmount} COINS
              </Text>
            </View>
            <Text style={styles.bountySubtitle}>
              {post.bountyStatus === 'open'
                ? 'Active bounty! Best answer chosen by author wins the reward.'
                : post.bountyStatus === 'awarded'
                  ? 'Bounty awarded! This question has been solved.'
                  : `Status: ${post.bountyStatus}`}
            </Text>
          </View>
        ) : null}

        {unlockCelebration && (
          <Animated.View
            pointerEvents="none"
            style={[
              styles.coinDeductionToast,
              {
                opacity: coinBurst,
                transform: [
                  {
                    translateY: coinBurst.interpolate({ inputRange: [0, 1], outputRange: [10, 0] }),
                  },
                  { scale: coinBurst.interpolate({ inputRange: [0, 1], outputRange: [0.86, 1] }) },
                ],
              },
            ]}
          >
            <View style={styles.deductionCoin}>
              <Ionicons name="logo-bitcoin" size={18} color="#fff" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.deductionTitle}>Post unlocked</Text>
              <Text style={styles.deductionText}>-{post.coinPrice || 0} coins deducted</Text>
            </View>
            <Ionicons name="checkmark-circle" size={24} color={colors.success} />
          </Animated.View>
        )}

        {/* Media Block (Instagram Full Width) */}
        {post.attachment?.kind === 'image' && (
          <Pressable
            onPress={() => setImageOpen(true)}
            style={({ pressed }) => pressed && { opacity: 0.95 }}
          >
            <Image source={{ uri: post.attachment.uri }} style={styles.instagramPostImage} />
          </Pressable>
        )}

        {post.locked && (
          <Animated.View style={[styles.privatePost, { marginHorizontal: 14, transform: [{ scale: unlockScale }] }]}>
            <LinearGradient colors={['#FFF3F8', '#F4F0FF']} style={styles.privatePostGlow}>
              <View style={styles.privateBadge}>
                <Ionicons name="lock-closed" size={11} color={colors.primary} />
                <Text style={styles.privateBadgeText}>PAID PRIVATE</Text>
              </View>
              <View style={styles.privateLock}>
                <Ionicons name="lock-closed" size={25} color="#fff" />
              </View>
              <Text style={styles.privateTitle}>Exclusive post</Text>
              <Text style={styles.privateCopy}>Unlock once to view this post anytime.</Text>
              <View style={styles.privatePrice}>
                <Ionicons name="logo-bitcoin" size={18} color={colors.accent} />
                <Text style={styles.privatePriceValue}>{post.coinPrice || 0}</Text>
                <Text style={styles.privatePriceLabel}>coins</Text>
              </View>
              <Button
                compact
                title={`Unlock · ${post.coinPrice || 0} coins`}
                loading={unlocking}
                onPress={() => void unlockPrivatePost()}
              />
              <View style={styles.secureUnlock}>
                <Ionicons name="shield-checkmark-outline" size={13} color={colors.success} />
                <Text style={styles.secureUnlockText}>Secure one-time coin payment</Text>
              </View>
            </LinearGradient>
          </Animated.View>
        )}

        {/* Poll Options (With proper padding) */}
        {post.pollOptions && post.pollOptions.length > 0 && (
          <View style={{ paddingHorizontal: 14, marginVertical: 10 }}>
            {post.pollOptions.map((option, index) => {
              const percentage = totalVotes
                ? Math.round(((post.pollResults?.[option] || 0) / totalVotes) * 100)
                : 0;
              return (
                <Pressable
                  key={`${post.id}-${index}-${option}`}
                  disabled={Boolean(voting)}
                  style={({ pressed }) => [
                    styles.pollOption,
                    post.myVote === option && { borderColor: colors.primary },
                    pressed && { opacity: 0.65 },
                  ]}
                  onPress={() => void vote(option)}
                >
                  <View style={[styles.pollProgress, { width: `${percentage}%` }]} />
                  <View style={styles.row}>
                    <Text style={[styles.body, { flex: 1 }]}>{option}</Text>
                    {!!voting && <ActivityIndicator size="small" color={colors.primary} />}
                    <Text style={styles.pollPercentage}>{percentage}%</Text>
                  </View>
                </Pressable>
              );
            })}
            <Text style={styles.muted}>
              {totalVotes} vote{totalVotes === 1 ? '' : 's'}
              {post.myVote ? ' · Tap another option to change your vote' : ''}
            </Text>
          </View>
        )}

        {/* Instagram Footer Area */}
        <View style={styles.instagramFooter}>
          {/* Actions Bar */}
          <View style={styles.instagramActionsRow}>
            <View style={styles.instagramLeftActions}>
              <Pressable onPress={() => toggleLike(post.id)} style={styles.instagramActionBtn}>
                <Ionicons
                  name={post.liked ? 'heart' : 'heart-outline'}
                  size={26}
                  color={post.liked ? '#FF3040' : colors.text}
                />
              </Pressable>
              <Pressable onPress={onPress} style={styles.instagramActionBtn}>
                <Ionicons name="chatbubble-outline" size={23} color={colors.text} />
              </Pressable>
              <Pressable onPress={() => setShareOpen(true)} style={styles.instagramActionBtn}>
                <Ionicons name="paper-plane-outline" size={23} color={colors.text} />
              </Pressable>
              {!post.mine && (
                <Pressable onPress={() => setGiftsOpen(true)} style={styles.instagramActionBtn}>
                  <Ionicons name="gift-outline" size={23} color={colors.text} />
                </Pressable>
              )}
            </View>
              <Pressable onPress={() => toggleSave(post.id)} style={styles.instagramActionBtn}>
              <Ionicons
                name={savedPosts.includes(post.id) ? 'bookmark' : 'bookmark-outline'}
                size={24}
                color={colors.text}
              />
            </Pressable>
          </View>

          {/* Likes & Tips Count */}
          <View style={{ flexDirection: 'column', gap: 2 }}>
            <Text style={styles.instagramLikes}>{post.likes.toLocaleString()} likes</Text>
            {post.tipTotal && post.tipTotal > 0 ? (
              <Text style={[styles.instagramLikes, { color: colors.accent, marginTop: 0 }]}>
                💝 {post.tipTotal} coins tipped ({post.tipCount} tips)
              </Text>
            ) : null}
            {/* Received Gifts visualization */}
            {(post as any).gifts && (post as any).gifts.length > 0 ? (
              <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 4, alignItems: 'center' }}>
                <Text style={{ fontSize: 11, fontWeight: '700', color: colors.muted }}>Gifts:</Text>
                {Object.values(
                  (post as any).gifts.reduce((acc: any, gift: any) => {
                    acc[gift.gift_id] ??= { icon: gift.icon || '🎁', name: gift.name, count: 0 };
                    acc[gift.gift_id].count++;
                    return acc;
                  }, {})
                ).map((item: any, idx: number) => (
                  <View key={idx} style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: '#F3F4F6', borderRadius: 8, paddingHorizontal: 6, paddingVertical: 2, gap: 2 }}>
                    {renderGiftIcon(item.icon, 16)}
                    <Text style={{ fontSize: 9, fontWeight: '800', color: colors.text }}>{item.name} x{item.count}</Text>
                  </View>
                ))}
              </View>
            ) : null}
          </View>

          {/* Caption / Description */}
          {!post.locked && (
            <View style={styles.instagramCaptionRow}>
              {editing ? (
                <View style={{ gap: 8, marginVertical: 6, width: '100%' }}>
                  <TextInput
                    value={editBody}
                    onChangeText={setEditBody}
                    multiline
                    style={styles.field}
                  />
                  <View style={styles.row}>
                    <Button title="Cancel" compact tone="ghost" onPress={() => setEditing(false)} />
                    <Button
                      title="Save"
                      compact
                      disabled={editBody.trim().length < 3}
                      onPress={() =>
                        void contentApi.updatePost(post.id, editBody.trim()).then(({ data }) => {
                          useAppStore.setState((state) => ({
                            posts: state.posts.map((item) =>
                              item.id === post.id ? { ...item, body: data.body } : item,
                            ),
                          }));
                          setEditing(false);
                        })
                      }
                    />
                  </View>
                </View>
              ) : (
                <Text style={styles.instagramCaptionText}>
                  <Text style={styles.instagramCaptionAuthor}>{post.author}</Text>{' '}
                  {post.body}
                </Text>
              )}
            </View>
          )}

          {/* Badges/Metadata */}
          <View style={styles.postBadgeRow}>
            {post.postType && post.postType !== 'Text' && (
              <View style={styles.formatBadge}>
                <Text style={styles.formatBadgeText}>{post.postType.toUpperCase()}</Text>
              </View>
            )}
            {post.visibility === 'private' && (
              <View style={styles.paidBadge}>
                <Ionicons name="lock-closed" size={10} color={colors.accent} />
                <Text style={styles.paidBadgeText}>PRIVATE</Text>
              </View>
            )}
          </View>

          {/* View Comments Link */}
          {post.comments > 0 && (
            <Pressable onPress={onPress}>
              <Text style={styles.instagramCommentsLink}>
                View all {post.comments} comment{post.comments === 1 ? '' : 's'}
              </Text>
            </Pressable>
          )}

          {/* Timestamp */}
          <Text style={styles.instagramTimestamp}>
            {post.createdAt ? formatRelativeDate(post.createdAt).toUpperCase() : 'JUST NOW'}
          </Text>
        </View>
      </Card>
      <Modal
        visible={imageOpen}
        transparent
        animationType="fade"
        onRequestClose={() => setImageOpen(false)}
      >
        <View style={styles.imageModal}>
          <Pressable style={styles.imageModalClose} onPress={() => setImageOpen(false)}>
            <Ionicons name="close" size={28} color="#fff" />
          </Pressable>
          {post.attachment?.uri && (
            <Image
              source={{ uri: post.attachment.uri }}
              style={styles.fullImage}
              resizeMode="contain"
            />
          )}
          <Button
            title="Open / download image"
            icon="download-outline"
            onPress={() => post.attachment?.uri && Linking.openURL(post.attachment.uri)}
          />
        </View>
      </Modal>
      <ShareModal
        visible={shareOpen}
        onClose={() => setShareOpen(false)}
        targetId={post.id}
        type="post"
      />

      <Modal
        visible={giftsOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setGiftsOpen(false)}
      >
        <View style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' }}>
          <View style={{ backgroundColor: dark.surface, borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24, minHeight: 340, gap: 16 }}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={{ fontSize: 18, fontWeight: '800', color: dark.text }}>Send a Virtual Gift 🎁</Text>
              <Pressable onPress={() => setGiftsOpen(false)} style={{ padding: 4 }}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            {giftsLoading ? (
              <ActivityIndicator size="large" color={colors.primary} style={{ marginVertical: 40 }} />
            ) : giftsError || availableGifts.length === 0 ? (
              <View style={{ alignItems: 'center', paddingVertical: 32, gap: 8 }}>
                <Text style={{ fontSize: 40 }}>🎁</Text>
                <Text style={{ fontSize: 14, color: colors.muted, textAlign: 'center' }}>
                  {giftsError ? 'Could not load gifts. Please try again.' : 'No gifts available right now.'}
                </Text>
                {giftsError && (
                  <Pressable
                    onPress={() => { setAvailableGifts([]); setGiftsError(false); setGiftsLoading(false); }}
                    style={{ backgroundColor: colors.primary, borderRadius: 8, paddingHorizontal: 16, paddingVertical: 8, marginTop: 4 }}
                  >
                    <Text style={{ color: '#fff', fontSize: 13, fontWeight: '700' }}>Retry</Text>
                  </Pressable>
                )}
              </View>
            ) : (
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 16, paddingVertical: 8 }}>
                {availableGifts.map((gift) => (
                  <Pressable
                    key={gift.id}
                    onPress={() => void sendPostGift(gift)}
                    style={{
                      width: 100,
                      backgroundColor: '#F9FAFF',
                      borderRadius: 16,
                      borderWidth: 1,
                      borderColor: '#E6E8F2',
                      padding: 12,
                      alignItems: 'center',
                      gap: 6
                    }}
                  >
                    {renderGiftIcon(gift.icon, 52)}
                    <Text style={{ fontSize: 12, fontWeight: '700', color: colors.text, textAlign: 'center' }} numberOfLines={1}>
                      {gift.name}
                    </Text>
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 2, backgroundColor: '#EFEFFF', borderRadius: 8, paddingHorizontal: 6, paddingVertical: 2 }}>
                      <Ionicons name="logo-bitcoin" size={10} color={colors.primary} />
                      <Text style={{ fontSize: 10, fontWeight: '800', color: colors.primary }}>
                        {gift.coin_price}
                      </Text>
                    </View>
                  </Pressable>
                ))}
              </ScrollView>
            )}
            
            <Text style={{ fontSize: 11, color: colors.muted, textAlign: 'center' }}>
              Gifts support the creator and are deducted from your coin balance.
            </Text>
          </View>
        </View>
      </Modal>
    </>
  );
}

export function ShareModal({
  visible,
  onClose,
  targetId,
  type,
}: {
  visible: boolean;
  onClose: () => void;
  targetId: string;
  type: 'post' | 'community';
}) {
  const currentUserId = useAppStore((state) => state.currentUserId);
  const people = useAppStore((state) => state.people);
  const [connections, setConnections] = React.useState<any[]>([]);
  const [query, setQuery] = React.useState('');
  const [loading, setLoading] = React.useState(false);
  const [sentMap, setSentMap] = React.useState<Record<string, boolean>>({});

  React.useEffect(() => {
    if (visible) {
      setLoading(true);
      usersApi
        .connections()
        .then(({ data }) => {
          setConnections(data.filter((item: any) => item.status === 'accepted'));
        })
        .catch(() => {})
        .finally(() => setLoading(false));
      setSentMap({});
      setQuery('');
    }
  }, [visible, currentUserId]);

  const connectedPeople = connections
    .map((item: any) => {
      const targetId = item.requester_id === currentUserId ? item.receiver_id : item.requester_id;
      return people.find((person) => person.id === targetId);
    })
    .filter(Boolean)
    .filter((person: any) => person.name.toLowerCase().includes(query.toLowerCase()));

  // Avoid duplicates
  const uniquePeopleMap = new Map();
  connectedPeople.forEach((p: any) => uniquePeopleMap.set(p.id, p));
  const filteredPeople = Array.from(uniquePeopleMap.values());

  const handleSend = async (userId: string) => {
    setSentMap((prev) => ({ ...prev, [userId]: true }));
    try {
      if (type === 'post') {
        await useAppStore.getState().sharePost(targetId, [userId]);
      } else {
        await useAppStore.getState().shareCommunity(targetId, [userId]);
      }
      onClose();
    } catch (error: any) {
      Alert.alert('Error sharing', error.message || 'Please try again.');
      setSentMap((prev) => ({ ...prev, [userId]: false }));
    }
  };

  const handleSystemShare = () => {
    onClose();
    if (type === 'post') {
      const post = useAppStore.getState().posts.find((p) => p.id === targetId);
      if (post) {
        Share.share({ message: `${post.author}: ${post.body}` });
      }
    } else {
      const community = useAppStore.getState().communities.find((c) => c.id === targetId);
      if (community) {
        Share.share({
          message: `Join community "${community.name}" on VibeCam: ${community.description}`,
        });
      }
    }
  };

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={modalStyles.overlay}>
        <View style={modalStyles.container}>
          <View style={modalStyles.header}>
            <Text style={ui.h2}>Send to friends</Text>
            <IconButton icon="close" onPress={onClose} />
          </View>
          <TextInput
            placeholder="Search connections..."
            placeholderTextColor={colors.muted}
            value={query}
            onChangeText={setQuery}
            style={modalStyles.searchInput}
          />
          {loading ? (
            <ActivityIndicator size="large" color={colors.primary} style={{ marginVertical: 20 }} />
          ) : (
            <ScrollView
              contentContainerStyle={{ gap: 12, paddingBottom: 20 }}
              style={{ maxHeight: 300 }}
            >
              {filteredPeople.length ? (
                filteredPeople.map((person: any) => (
                  <View key={person.id} style={modalStyles.row}>
                    <Avatar name={person.name} color={person.avatarColor} size={40} />
                    <View style={{ flex: 1, marginLeft: 10 }}>
                      <Text style={modalStyles.name}>{person.name}</Text>
                      <Text style={modalStyles.username}>@{person.username}</Text>
                    </View>
                    <Button
                      title={sentMap[person.id] ? 'Sent' : 'Send'}
                      compact
                      disabled={sentMap[person.id]}
                      tone={sentMap[person.id] ? 'secondary' : 'primary'}
                      onPress={() => handleSend(person.id)}
                    />
                  </View>
                ))
              ) : (
                <Text style={[ui.muted, { textAlign: 'center', marginTop: 20 }]}>
                  No connections found.
                </Text>
              )}
            </ScrollView>
          )}
          <View style={{ borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 12 }}>
            <Button
              title="Share externally"
              icon="share-social"
              tone="ghost"
              onPress={handleSystemShare}
            />
          </View>
        </View>
      </View>
    </Modal>
  );
}

const modalStyles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,.5)',
    justifyContent: 'flex-end',
  },
  container: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 16,
    gap: 12,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  searchInput: {
    backgroundColor: colors.bg,
    color: colors.text,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  name: {
    color: colors.text,
    fontSize: 14,
    fontWeight: '700',
  },
  username: {
    color: colors.muted,
    fontSize: 12,
  },
});

export function EmptyState({
  icon = 'search',
  title,
  text,
  action,
  onAction,
}: {
  icon?: string;
  title: string;
  text: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <View style={styles.empty}>
      <View style={styles.emptyIcon}>
        <Ionicons name={icon as any} size={34} color={colors.primary} />
      </View>
      <Text style={styles.sectionTitle}>{title}</Text>
      <Text style={[styles.muted, { textAlign: 'center' }]}>{text}</Text>
      {action && onAction && <Button title={action} compact tone="secondary" onPress={onAction} />}
    </View>
  );
}

export function LoadingState({ title }: { title: string }) {
  return (
    <View style={styles.empty}>
      <ActivityIndicator size="large" color={colors.primary} />
      <Text style={styles.cardTitle}>{title}</Text>
    </View>
  );
}

export const ui = StyleSheet.create({
  title: { color: colors.text, fontSize: 30, fontWeight: '900', lineHeight: 36 },
  h2: { color: colors.text, fontSize: 21, fontWeight: '800' },
  body: { color: colors.text, fontSize: 15, lineHeight: 22 },
  muted: { color: colors.muted, fontSize: 13, lineHeight: 19 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
});

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.bg },
  content: { padding: 18, paddingBottom: 24, gap: 16 },
  header: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 18,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.bg,
  },
  headerTitle: { color: colors.text, fontSize: 24, fontWeight: '900' },
  muted: ui.muted,
  button: {
    minHeight: 52,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: 8,
    paddingHorizontal: 12,
  },
  compactButton: { minHeight: 40, borderRadius: 12 },
  buttonText: { color: '#fff', fontSize: 15, fontWeight: '800' },
  altButtonText: { color: colors.primary, fontSize: 15, fontWeight: '800' },
  secondaryButton: { backgroundColor: colors.surfaceAlt, borderWidth: 1, borderColor: '#DDE1FF' },
  dangerButton: { backgroundColor: 'rgba(239,68,68,0.12)', borderWidth: 1, borderColor: '#FFD5DB' },
  ghostButton: { backgroundColor: 'transparent' },
  iconButton: {
    width: 42,
    height: 42,
    borderRadius: 14,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badge: {
    position: 'absolute',
    top: -3,
    right: -3,
    minWidth: 17,
    height: 17,
    borderRadius: 9,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { color: '#fff', fontSize: 9, fontWeight: '900' },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 20,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
    shadowColor: '#34405C',
    shadowOpacity: 0.05,
    shadowRadius: 14,
    elevation: 2,
  },
  label: { color: colors.text, fontSize: 13, fontWeight: '700' },
  field: {
    minHeight: 52,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 14,
    paddingHorizontal: 12,
    paddingVertical: 13,
    color: colors.text,
    fontSize: 15,
  },
  search: {
    height: 52,
    borderRadius: 16,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
  },
  section: {
    marginTop: 4,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sectionTitle: { color: colors.text, fontSize: 19, fontWeight: '800' },
  link: { color: colors.primary, fontWeight: '800' },
  avatar: { alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: '#fff', fontWeight: '900' },
  online: {
    position: 'absolute',
    right: 0,
    bottom: 1,
    width: 13,
    height: 13,
    borderRadius: 7,
    backgroundColor: colors.success,
    borderWidth: 2,
    borderColor: '#fff',
  },
  pill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 99,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.bg,
  },
  pillText: { color: colors.muted, fontSize: 11, fontWeight: '700' },
  row: ui.row,
  inline: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  cardTitle: { color: colors.text, fontSize: 15, fontWeight: '800' },
  tags: { flexDirection: 'row', flexWrap: 'wrap', gap: 5, marginTop: 4 },
  communityIcon: {
    width: 48,
    height: 48,
    borderRadius: 15,
    alignItems: 'center',
    justifyContent: 'center',
  },
  body: ui.body,
  postActions: {
    flexDirection: 'row',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: 'rgba(108, 93, 211, 0.06)',
    paddingTop: 14,
    gap: 8,
  },
  postCard: {
    padding: 0,
    borderRadius: 0,
    backgroundColor: colors.surface,
    borderWidth: 0,
    shadowColor: 'transparent',
    shadowOpacity: 0,
    shadowRadius: 0,
    elevation: 0,
    marginBottom: 16,
    marginHorizontal: -12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  postHeader: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  postBadgeRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 12 },
  communityBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: 'rgba(255,45,117,0.12)',
  },
  communityBadgeText: { color: colors.primary, fontSize: 10, fontWeight: '700' },
  formatBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: 'rgba(139,92,246,0.12)',
    borderWidth: 1,
    borderColor: 'rgba(139,92,246,0.2)',
  },
  formatBadgeText: {
    color: colors.primaryDark,
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  paidBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: 'rgba(255,122,0,0.12)',
  },
  paidBadgeText: { color: colors.accent, fontSize: 9, fontWeight: '800', letterSpacing: 0.5 },
  postBody: {
    color: colors.text,
    fontSize: 15,
    lineHeight: 22,
    fontWeight: '400',
    marginVertical: 14,
  },
  postActionButton: {
    flex: 1,
    minHeight: 38,
    borderRadius: 12,
    backgroundColor: 'rgba(255,45,117,0.06)',
    borderWidth: 1,
    borderColor: 'rgba(255,45,117,0.10)',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  postActionActive: {
    backgroundColor: 'rgba(255, 107, 107, 0.08)',
    borderColor: 'rgba(255, 107, 107, 0.15)',
  },
  postActionText: { color: colors.muted, fontSize: 11, fontWeight: '700' },
  postActionIcon: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: 'rgba(108, 93, 211, 0.04)',
    borderWidth: 1,
    borderColor: 'rgba(108, 93, 211, 0.08)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  privatePost: {
    marginVertical: 14,
    borderRadius: 20,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#F2D7E5',
  },
  privatePostGlow: { alignItems: 'center', gap: 9, paddingHorizontal: 20, paddingVertical: 20 },
  privateBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 99,
    backgroundColor: 'rgba(255,255,255,.78)',
  },
  privateBadgeText: { color: colors.primary, fontSize: 9, fontWeight: '900', letterSpacing: 0.8 },
  privateLock: {
    width: 50,
    height: 50,
    borderRadius: 18,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: colors.primary,
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 4,
  },
  privateTitle: { color: colors.text, fontSize: 18, fontWeight: '900' },
  privateCopy: { color: colors.muted, fontSize: 12, textAlign: 'center' },
  privatePrice: { flexDirection: 'row', alignItems: 'baseline', gap: 4, marginBottom: 2 },
  privatePriceValue: { color: colors.text, fontSize: 25, fontWeight: '900' },
  privatePriceLabel: { color: colors.muted, fontSize: 11, fontWeight: '700' },
  secureUnlock: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  secureUnlockText: { color: colors.muted, fontSize: 9, fontWeight: '600' },
  coinDeductionToast: {
    marginTop: 12,
    padding: 12,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#CFEDE1',
    backgroundColor: '#F0FBF7',
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
  },
  deductionCoin: {
    width: 36,
    height: 36,
    borderRadius: 12,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  deductionTitle: { color: colors.text, fontSize: 13, fontWeight: '900' },
  deductionText: { color: colors.success, fontSize: 11, fontWeight: '800' },
  action: { flexDirection: 'row', alignItems: 'center', gap: 6, marginRight: 24 },
  postImage: {
    width: '100%',
    height: 300,
    borderRadius: 20,
    backgroundColor: colors.surfaceAlt,
    marginBottom: 14,
  },
  imageModal: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,.96)',
    padding: 18,
    justifyContent: 'center',
    gap: 18,
  },
  imageModalClose: { position: 'absolute', right: 18, top: 52, zIndex: 2, padding: 10 },
  fullImage: { width: '100%', height: '75%' },
  pollOption: {
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 11,
    marginBottom: 8,
  },
  pollProgress: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    left: 0,
    backgroundColor: '#E9EAFF',
  },
  pollPercentage: { minWidth: 38, color: colors.primary, fontWeight: '800', textAlign: 'right' },
  instagramHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  instagramAuthorName: {
    color: colors.text,
    fontSize: 14,
    fontWeight: '700',
  },
  instagramSubtitle: {
    color: colors.muted,
    fontSize: 11,
    marginTop: 1,
  },
  instagramPostImage: {
    width: '100%',
    height: 460,
    backgroundColor: colors.surfaceAlt,
  },
  instagramFooter: {
    paddingHorizontal: 14,
    paddingTop: 10,
    paddingBottom: 14,
  },
  instagramActionsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  instagramLeftActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  instagramActionBtn: {
    padding: 2,
  },
  instagramLikes: {
    color: colors.text,
    fontSize: 14,
    fontWeight: '700',
    marginTop: 4,
  },
  instagramCaptionRow: {
    marginTop: 6,
    flexDirection: 'row',
  },
  instagramCaptionText: {
    color: colors.text,
    fontSize: 14,
    lineHeight: 18,
  },
  instagramCaptionAuthor: {
    fontWeight: '700',
    color: colors.text,
  },
  instagramCommentsLink: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 6,
  },
  instagramTimestamp: {
    color: colors.muted,
    fontSize: 10,
    marginTop: 6,
    fontWeight: '500',
    letterSpacing: 0.1,
  },
  empty: {
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    paddingVertical: 55,
    paddingHorizontal: 35,
  },
  emptyIcon: {
    width: 70,
    height: 70,
    borderRadius: 24,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  boostBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary,
    borderRadius: 8,
    paddingHorizontal: 6,
    paddingVertical: 2,
    marginLeft: 6,
    gap: 2,
  },
  boostBadgeText: {
    color: '#fff',
    fontSize: 9,
    fontWeight: '800',
  },
  bountyBanner: {
    backgroundColor: '#FFF9E6',
    borderWidth: 1,
    borderColor: '#FFE0B2',
    borderRadius: 10,
    padding: 12,
    marginHorizontal: 14,
    marginVertical: 8,
    gap: 4,
  },
  bountyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  bountyTitle: {
    color: '#E65100',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 0.3,
  },
  bountySubtitle: {
    color: '#F57C00',
    fontSize: 11,
    fontWeight: '600',
  },
  gridCard: {
    width: (Dimensions.get('window').width - 18 * 2 - 10) / 2,
    aspectRatio: 3 / 4,
    borderRadius: 18,
    overflow: 'hidden',
    backgroundColor: colors.surfaceAlt,
    position: 'relative',
  },
  gridInitialWrapper: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
  },
  gridInitial: {
    fontSize: 48,
    fontWeight: '900',
    color: 'rgba(255,255,255,0.85)',
  },
  onlineDot: {
    position: 'absolute',
    top: 10,
    right: 10,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2,
  },
  onlineDotInner: {
    width: 9,
    height: 9,
    borderRadius: 4.5,
    backgroundColor: '#22C55E',
  },
  gridOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: 10,
    gap: 3,
    zIndex: 1,
  },
  gridName: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '800',
    textShadowColor: 'rgba(0,0,0,0.5)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
  gridDetailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  gridDetailText: {
    color: 'rgba(255,255,255,0.75)',
    fontSize: 11,
    flex: 1,
  },
  gridTags: {
    flexDirection: 'row',
    gap: 4,
    flexWrap: 'wrap',
    marginTop: 3,
  },
  gridTag: {
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 8,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  gridTagText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
});
