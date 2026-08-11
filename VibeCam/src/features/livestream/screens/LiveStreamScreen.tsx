import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Image,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors } from '../../../theme';
import { useAppStore } from '../../../store/useAppStore';
import { livestreamApi } from '../../../services/api';

const CATEGORIES = ['All', 'Gaming', 'Music', 'Fitness', 'Talk', 'Art', 'Education'];

function StreamCard({ stream, onPress }: { stream: any; onPress: () => void }) {
  const avatarUrl = stream.host?.avatar_url;
  const initial = (stream.host?.name || '?')[0].toUpperCase();
  return (
    <Pressable style={styles.streamCard} onPress={onPress}>
      {/* Thumbnail / gradient bg */}
      <LinearGradient
        colors={['#3B3F9A', '#7C3AED']}
        style={styles.streamThumb}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        {avatarUrl ? (
          <Image source={{ uri: avatarUrl }} style={StyleSheet.absoluteFill} resizeMode="cover" />
        ) : (
          <Text style={styles.streamThumbInitial}>{initial}</Text>
        )}
        {/* LIVE badge */}
        <View style={styles.liveBadge}>
          <View style={styles.liveDot} />
          <Text style={styles.liveBadgeText}>LIVE</Text>
        </View>
        {/* Viewer count */}
        <View style={styles.viewerBadge}>
          <Ionicons name="eye" size={12} color="#fff" />
          <Text style={styles.viewerText}>{stream.current_viewers ?? 0}</Text>
        </View>
      </LinearGradient>

      {/* Info row */}
      <View style={styles.streamInfo}>
        {/* Avatar */}
        <View style={styles.streamHostAvatar}>
          {avatarUrl ? (
            <Image source={{ uri: avatarUrl }} style={styles.streamHostAvatarImg} />
          ) : (
            <Text style={styles.streamHostAvatarText}>{initial}</Text>
          )}
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.streamTitle} numberOfLines={1}>{stream.title}</Text>
          <Text style={styles.streamHost} numberOfLines={1}>{stream.host?.name}</Text>
        </View>
        <View style={styles.categoryPill}>
          <Text style={styles.categoryPillText}>{stream.category}</Text>
        </View>
      </View>
    </Pressable>
  );
}

export function LiveStreamScreen({ navigation }: any) {
  const insets = useSafeAreaInsets();
  const profile = useAppStore((s) => s.profile);
  const dark = useAppStore((s) => s.darkMode);

  const [streams, setStreams] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [activeCategory, setActiveCategory] = useState('All');

  const load = useCallback(async (isRefresh = false) => {
    if (!isRefresh) setLoading(true);
    try {
      const { data } = await livestreamApi.active();
      setStreams(data || []);
    } catch {
      // ignore
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useFocusEffect(useCallback(() => {
    void load();
  }, [load]));

  const filtered = activeCategory === 'All'
    ? streams
    : streams.filter((s) => s.category === activeCategory);

  return (
    <View style={[styles.root, dark && { backgroundColor: '#0D1020' }, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={[styles.eyebrow, dark && { color: '#AAB0C5' }]}>VIBECAM</Text>
          <Text style={[styles.title, dark && { color: '#F5F7FF' }]}>Live Streams</Text>
        </View>
        {/* Go Live CTA */}
        <Pressable
          style={styles.goLiveBtn}
          onPress={() => navigation.navigate('GoLive')}
        >
          <LinearGradient
            colors={['#7C3AED', '#5B5CE2']}
            style={styles.goLiveBtnGrad}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
          >
            <Ionicons name="radio" size={18} color="#fff" />
            <Text style={styles.goLiveBtnText}>Go Live</Text>
          </LinearGradient>
        </Pressable>
      </View>

      {/* Category Filter */}
      <FlatList
        data={CATEGORIES}
        keyExtractor={(c) => c}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={{ flexGrow: 0, maxHeight: 46 }}
        contentContainerStyle={styles.categoryList}
        renderItem={({ item }) => (
          <Pressable
            style={[styles.catPill, activeCategory === item && styles.catPillActive]}
            onPress={() => setActiveCategory(item)}
          >
            <Text style={[styles.catPillText, activeCategory === item && styles.catPillTextActive]}>
              {item}
            </Text>
          </Pressable>
        )}
      />

      {/* Streams Grid */}
      {loading ? (
        <View style={styles.loadingState}>
          <ActivityIndicator size="large" color={colors.primary} />
          <Text style={[styles.loadingText, dark && { color: '#AAB0C5' }]}>Finding live streams…</Text>
        </View>
      ) : filtered.length === 0 ? (
        <View style={styles.emptyState}>
          <LinearGradient
            colors={['rgba(92,92,226,0.15)', 'rgba(124,58,237,0.15)']}
            style={styles.emptyIcon}
          >
            <Ionicons name="radio-outline" size={48} color={colors.primary} />
          </LinearGradient>
          <Text style={[styles.emptyTitle, dark && { color: '#F5F7FF' }]}>No live streams right now</Text>
          <Text style={[styles.emptySubtitle, dark && { color: '#AAB0C5' }]}>
            Be the first to go live and earn coins from your audience!
          </Text>
          <Pressable
            style={styles.emptyGoLiveBtn}
            onPress={() => navigation.navigate('GoLive')}
          >
            <LinearGradient
              colors={['#7C3AED', '#5B5CE2']}
              style={styles.emptyGoLiveBtnGrad}
            >
              <Ionicons name="radio" size={18} color="#fff" />
              <Text style={styles.goLiveBtnText}>Start Streaming</Text>
            </LinearGradient>
          </Pressable>
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(s) => s.id}
          numColumns={2}
          columnWrapperStyle={styles.gridRow}
          contentContainerStyle={styles.gridContent}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => { setRefreshing(true); void load(true); }}
              tintColor={colors.primary}
            />
          }
          renderItem={({ item }) => (
            <StreamCard
              stream={item}
              onPress={() => navigation.navigate('WatchStream', { streamId: item.id, title: item.title })}
            />
          )}
        />
      )}

      {/* Earn info banner */}
      <View style={[styles.earnBanner, dark && { backgroundColor: '#232A45' }, { paddingBottom: Math.max(insets.bottom, 8) }]}>
        <Ionicons name="gift-outline" size={18} color="#F59E0B" />
        <Text style={[styles.earnText, dark && { color: '#AAB0C5' }]}>
          Viewers can send you gifts. Every gift earns you real coins!
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 8,
  },
  eyebrow: { fontSize: 11, fontWeight: '800', color: colors.primary, letterSpacing: 1.5 },
  title: { fontSize: 26, fontWeight: '900', color: colors.text, marginTop: 2 },
  goLiveBtn: { borderRadius: 22, overflow: 'hidden' },
  goLiveBtnGrad: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 22,
  },
  goLiveBtnText: { color: '#fff', fontWeight: '800', fontSize: 14 },
  categoryList: { paddingHorizontal: 16, gap: 8, paddingBottom: 12 },
  catPill: {
    paddingHorizontal: 16,
    paddingVertical: 7,
    borderRadius: 20,
    backgroundColor: colors.surfaceAlt,
    borderWidth: 1,
    borderColor: colors.border,
  },
  catPillActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  catPillText: { color: colors.muted, fontWeight: '700', fontSize: 13 },
  catPillTextActive: { color: '#fff' },
  gridRow: { gap: 10, paddingHorizontal: 16 },
  gridContent: { gap: 10, paddingBottom: 70 },
  streamCard: { flex: 1, borderRadius: 16, overflow: 'hidden', backgroundColor: colors.surface },
  streamThumb: {
    width: '100%',
    aspectRatio: 9 / 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  streamThumbInitial: { fontSize: 40, fontWeight: '900', color: '#fff' },
  liveBadge: {
    position: 'absolute',
    top: 8,
    left: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#EF4444',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 10,
  },
  liveDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: '#fff' },
  liveBadgeText: { color: '#fff', fontSize: 10, fontWeight: '800', letterSpacing: 0.5 },
  viewerBadge: {
    position: 'absolute',
    top: 8,
    right: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: 'rgba(0,0,0,0.55)',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 10,
  },
  viewerText: { color: '#fff', fontSize: 11, fontWeight: '700' },
  streamInfo: { flexDirection: 'row', alignItems: 'center', gap: 8, padding: 10 },
  streamHostAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  streamHostAvatarImg: { width: '100%', height: '100%' },
  streamHostAvatarText: { color: '#fff', fontWeight: '800', fontSize: 13 },
  streamTitle: { color: colors.text, fontWeight: '700', fontSize: 12, lineHeight: 16 },
  streamHost: { color: colors.muted, fontSize: 11 },
  categoryPill: {
    backgroundColor: colors.surfaceAlt,
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 8,
  },
  categoryPillText: { color: colors.muted, fontSize: 10, fontWeight: '700' },
  loadingState: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 14 },
  loadingText: { color: colors.muted, fontSize: 15 },
  emptyState: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16, paddingHorizontal: 36 },
  emptyIcon: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyTitle: { color: colors.text, fontSize: 20, fontWeight: '900', textAlign: 'center' },
  emptySubtitle: { color: colors.muted, fontSize: 14, textAlign: 'center', lineHeight: 20 },
  emptyGoLiveBtn: { borderRadius: 22, overflow: 'hidden', marginTop: 4 },
  emptyGoLiveBtnGrad: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 24,
    paddingVertical: 13,
    borderRadius: 22,
  },
  earnBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: colors.surface,
    paddingHorizontal: 16,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  earnText: { flex: 1, color: colors.muted, fontSize: 12, lineHeight: 17 },
});

export default LiveStreamScreen;
