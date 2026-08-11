import React, { useRef, useState } from 'react';
import {
  Alert,
  Animated,
  Dimensions,
  Image,
  Pressable,
  ScrollView,
  Text,
  View,
  StyleSheet,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  Card,
  EmptyState,
  Header,
  IconButton,
  ui,
  formatRelativeDate,
} from '../../../components/ui';
import { colors } from '../../../theme';
import { useAppStore } from '../../../store/useAppStore';
import { styles } from '../../shared-views/styles';

export function MyCreationsScreen({ navigation }: any) {
  const { posts, communities, deletePost, deleteCommunity } = useAppStore();
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [tab, setTab] = useState<'posts' | 'communities'>('posts');
  const slideAnim = useRef(new Animated.Value(0)).current;
  const [fabOpen, setFabOpen] = useState(false);
  const fabAnim = useRef(new Animated.Value(0)).current;
  const insets = useSafeAreaInsets();

  // Only my own posts and communities (no circles)
  const myPosts = posts.filter((p) => p.authorId === currentUserId || p.mine);
  const myCommunities = communities.filter((c) => c.isOwner && c.kind !== 'circle');

  const switchTab = (next: 'posts' | 'communities') => {
    const toValue = next === 'posts' ? 0 : 1;
    Animated.spring(slideAnim, {
      toValue,
      useNativeDriver: true,
      tension: 180,
      friction: 14,
    }).start();
    setTab(next);
  };

  const toggleFab = () => {
    const open = !fabOpen;
    setFabOpen(open);
    Animated.spring(fabAnim, {
      toValue: open ? 1 : 0,
      useNativeDriver: true,
      tension: 200,
      friction: 12,
    }).start();
  };

  const { width: screenWidth } = Dimensions.get('window');
  const translateX = slideAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, -screenWidth],
  });

  const handleDeletePost = (id: string) => {
    Alert.alert('Delete post?', 'This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => deletePost(id).catch((err: any) => Alert.alert('Error', err.message)),
      },
    ]);
  };

  const handleDeleteCommunity = (id: string, isCircle: boolean) => {
    Alert.alert(
      isCircle ? 'Delete circle?' : 'Delete community?',
      `This will delete the ${isCircle ? 'circle' : 'community'} and all its content. This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => deleteCommunity(id).catch((err: any) => Alert.alert('Error', err.message)),
        },
      ],
    );
  };

  const tabIndicatorTranslateX = slideAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, screenWidth / 2],
  });

  // Single FAB: only one context-aware sub-button
  const fabSubScale = fabAnim.interpolate({ inputRange: [0, 1], outputRange: [0.5, 1] });
  const fabSubTranslateY = fabAnim.interpolate({ inputRange: [0, 1], outputRange: [0, -76] });
  const fabSubOpacity = fabAnim;
  const fabRotate = fabAnim.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '45deg'] });

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg, paddingTop: insets.top }}>
      {/* Header */}
      <View style={{ paddingHorizontal: 12, paddingBottom: 12 }}>
        <Header
          title="My Creations"
          subtitle="Your posts & communities"
          onBack={() => navigation.goBack()}
        />
      </View>

      {/* Animated Tab Bar */}
      <View style={styles.creationsTabBar}>
        <Pressable style={styles.creationsTab} onPress={() => switchTab('posts')}>
          <Text style={[styles.creationsTabText, tab === 'posts' && styles.creationsTabTextActive]}>
            Posts ({myPosts.length})
          </Text>
        </Pressable>
        <Pressable style={styles.creationsTab} onPress={() => switchTab('communities')}>
          <Text
            style={[
              styles.creationsTabText,
              tab === 'communities' && styles.creationsTabTextActive,
            ]}
          >
            Communities ({myCommunities.length})
          </Text>
        </Pressable>
        <Animated.View
          style={[
            styles.creationsTabIndicator,
            { transform: [{ translateX: tabIndicatorTranslateX }] },
          ]}
        />
      </View>

      {/* Sliding Content Wrapper */}
      <View style={{ flex: 1, overflow: 'hidden' }}>
        <Animated.View
          style={{
            flex: 1,
            flexDirection: 'row',
            width: screenWidth * 2,
            transform: [{ translateX }],
          }}
        >
          {/* Posts Tab */}
          <ScrollView
            style={{ width: screenWidth }}
            contentContainerStyle={{ padding: 12, paddingBottom: 120, gap: 12 }}
            showsVerticalScrollIndicator={false}
          >
            {myPosts.length ? (
              myPosts.map((post) => (
                <Card key={post.id}>
                  {/* Image preview for image posts */}
                  {post.postType === 'Image' && post.attachment?.uri ? (
                    <Image
                      source={{ uri: post.attachment.uri }}
                      style={styles.creationsPostImage}
                      resizeMode="cover"
                    />
                  ) : null}
                  <View
                    style={{
                      flexDirection: 'row',
                      alignItems: 'flex-start',
                      gap: 10,
                      marginTop: post.postType === 'Image' && post.attachment?.uri ? 10 : 0,
                    }}
                  >
                    <View
                      style={[
                        styles.creationsPostIcon,
                        post.postType === 'Poll' && { backgroundColor: '#FFF0E6' },
                        post.postType === 'Image' && { backgroundColor: '#E6F0FF' },
                      ]}
                    >
                      <Ionicons
                        name={
                          post.postType === 'Poll'
                            ? 'bar-chart'
                            : post.postType === 'Image'
                              ? 'image'
                              : 'document-text'
                        }
                        size={18}
                        color={
                          post.postType === 'Poll'
                            ? '#F97316'
                            : post.postType === 'Image'
                              ? '#3B82F6'
                              : colors.primary
                        }
                      />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.smallMuted}>
                        {post.community} ·{' '}
                        {post.createdAt ? formatRelativeDate(post.createdAt) : 'Just now'}
                      </Text>
                      <Text style={[ui.body, { marginTop: 6 }]} numberOfLines={3}>
                        {post.body}
                      </Text>
                      <View style={{ flexDirection: 'row', gap: 16, marginTop: 8 }}>
                        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                          <Ionicons name="heart-outline" size={14} color={colors.muted} />
                          <Text style={styles.smallMuted}>{post.likes ?? 0}</Text>
                        </View>
                        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                          <Ionicons name="chatbubble-outline" size={14} color={colors.muted} />
                          <Text style={styles.smallMuted}>{post.comments ?? 0}</Text>
                        </View>
                        {post.postType ? (
                          <View style={styles.creationsPostTypeBadge}>
                            <Text style={styles.creationsPostTypeText}>{post.postType}</Text>
                          </View>
                        ) : null}
                      </View>
                    </View>
                    <IconButton icon="trash-outline" onPress={() => handleDeletePost(post.id)} />
                  </View>
                </Card>
              ))
            ) : (
              <EmptyState
                icon="document-text-outline"
                title="No posts yet"
                text="Tap + to create your first post."
              />
            )}
          </ScrollView>

          {/* Communities & Circles Tab */}
          <ScrollView
            style={{ width: screenWidth }}
            contentContainerStyle={{ padding: 12, paddingBottom: 120, gap: 12 }}
            showsVerticalScrollIndicator={false}
          >
            {myCommunities.length > 0 ? (
              myCommunities.map((community) => (
                <Card key={community.id} style={{ padding: 0, overflow: 'hidden' }}>
                  <View
                    style={[
                      styles.creationsCommunityHeader,
                      { backgroundColor: community.color || colors.primary },
                    ]}
                  >
                    {community.coverUrl ? (
                      <Image
                        source={{ uri: community.coverUrl }}
                        style={StyleSheet.absoluteFillObject as any}
                        resizeMode="cover"
                      />
                    ) : null}
                    {community.logoUrl ? (
                      <Image
                        source={{ uri: community.logoUrl }}
                        style={styles.creationsCommunityLogo}
                      />
                    ) : (
                      <View
                        style={[
                          styles.creationsCommunityLogo,
                          {
                            backgroundColor: 'rgba(255,255,255,0.25)',
                            alignItems: 'center',
                            justifyContent: 'center',
                          },
                        ]}
                      >
                        <Ionicons name="people" size={22} color="#fff" />
                      </View>
                    )}
                    <View style={{ flex: 1, marginLeft: 10 }}>
                      <Text style={{ color: '#fff', fontWeight: '900', fontSize: 15 }}>
                        {community.name}
                      </Text>
                      <Text style={{ color: 'rgba(255,255,255,0.8)', fontSize: 11, marginTop: 2 }}>
                        {community.category}
                      </Text>
                    </View>
                  </View>
                  <View
                    style={{
                      flexDirection: 'row',
                      gap: 6,
                      padding: 10,
                      justifyContent: 'space-between',
                    }}
                  >
                    <Text style={{ color: 'rgba(0,0,0,0.8)', fontSize: 11, marginTop: 2 }}>
                      {community.members} members
                    </Text>

                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                      <IconButton
                        icon="eye-outline"
                        onPress={() =>
                          navigation.navigate('CommunityDetails', { communityId: community.id })
                        }
                      />
                      <IconButton
                        icon="trash-outline"
                        onPress={() => handleDeleteCommunity(community.id, false)}
                      />
                    </View>
                  </View>
                </Card>
              ))
            ) : (
              <EmptyState
                icon="people-circle-outline"
                title="No communities yet"
                text="Tap + to create your first community."
              />
            )}
          </ScrollView>
        </Animated.View>
      </View>

      {/* FAB — single context-aware button */}
      <View
        style={[styles.creationsFabContainer, { bottom: insets.bottom + 24 }]}
        pointerEvents="box-none"
      >
        {/* One sub-button changes based on active tab */}
        <Animated.View
          style={[
            styles.creationsFabSubRow,
            {
              transform: [{ translateY: fabSubTranslateY }, { scale: fabSubScale }],
              opacity: fabSubOpacity,
            },
          ]}
          pointerEvents={fabOpen ? 'auto' : 'none'}
        >
          <Text style={styles.creationsFabSubLabel}>
            {tab === 'posts' ? 'New Post' : 'New Community'}
          </Text>
          <Pressable
            style={[
              styles.creationsFabSubCircle,
              { backgroundColor: tab === 'posts' ? colors.success : colors.primary },
            ]}
            onPress={() => {
              toggleFab();
              navigation.navigate(tab === 'posts' ? 'CreatePost' : 'CreateCommunity');
            }}
          >
            <Ionicons name={tab === 'posts' ? 'document-text' : 'people'} size={20} color="#fff" />
          </Pressable>
        </Animated.View>

        {/* Main FAB */}
        <Pressable style={styles.creationsFab} onPress={toggleFab}>
          <Animated.View style={{ transform: [{ rotate: fabRotate }] }}>
            <Ionicons name="add" size={28} color="#fff" />
          </Animated.View>
        </Pressable>
      </View>
    </View>
  );
}

export default MyCreationsScreen;
