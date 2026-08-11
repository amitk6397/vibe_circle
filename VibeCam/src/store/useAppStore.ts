import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import {
  Chat,
  Comment,
  Community,
  CommunityMessage,
  LocalAttachment,
  Message,
  Post,
  Person,
  Purpose,
} from '../types';
import {
  ApiUser,
  authApi,
  chatApi,
  contentApi,
  discoveryApi,
  uploadAttachment,
  usersApi,
  notificationsApi,
  safetyApi,
} from '../services/api';
import { realtimeService } from '../services/realtimeSocket';
import { unregisterPushNotifications } from '../services/pushNotifications';

type Profile = {
  name: string;
  age: string;
  email: string;
  username: string;
  bio: string;
  city: string;
  interests: string[];
  languages: string[];
  dateOfBirth?: string;
  gender?: string;
  preferredLanguage?: string;
  conversationTopics: string[];
  avatarUri?: string;
  vibeStatus?: string;
  vibeExpiresAt?: string;
};
type AppState = {
  authenticated: boolean;
  currentUserId: string | null;
  sessionReady: boolean;
  loading: boolean;
  apiError: string | null;
  selectedPurpose: Purpose;
  anonymousMode: boolean;
  darkMode: boolean;
  profile: Profile;
  people: Person[];
  chats: Chat[];
  messages: Message[];
  communityMessages: CommunityMessage[];
  posts: Post[];
  comments: Comment[];
  communities: Community[];
  joinedCommunities: string[];
  blockedUsers: string[];
  savedPosts: string[];
  notifications: number;
  searchFilters: {
    purpose: Purpose;
    language: string;
    minAge: number;
    maxAge: number;
    onlineOnly: boolean;
    gender: string;
    city: string;
  };
  setSearchFilters: (filters: Partial<AppState['searchFilters']>) => void;
  setDarkMode: (value: boolean) => void;
  bootstrap: () => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  register: (payload: {
    name: string;
    age: number;
    email: string;
    password: string;
    avatar_url?: string | null;
    referral_code?: string;
  }) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (value: Partial<Profile>) => void;
  selectPurpose: (purpose: Purpose) => void;
  setAnonymousMode: (value: boolean) => void;
  sendMessage: (
    chatId: string,
    text: string,
    attachment?: LocalAttachment,
    replyTo?: Message,
  ) => void;
  sendCommunityMessage: (communityId: string, text: string, attachment?: LocalAttachment) => void;
  createPost: (
    body: string,
    anonymous: boolean,
    options?: Pick<Post, 'postType' | 'pollOptions' | 'attachment' | 'visibility' | 'bountyAmount' | 'coinPrice'> & {
      communityId?: string;
    },
  ) => Promise<void>;
  addComment: (postId: string, body: string) => void;
  createCommunity: (
    value: Partial<Community> & Pick<Community, 'name' | 'description' | 'category'>,
  ) => Promise<string>;
  toggleLike: (postId: string) => void;
  toggleSave: (postId: string) => void;
  toggleCommunity: (communityId: string) => Promise<void>;
  deleteCommunity: (communityId: string) => Promise<void>;
  deletePost: (postId: string) => Promise<void>;
  sharePost: (postId: string, userIds: string[]) => Promise<number>;
  shareCommunity: (communityId: string, userIds: string[]) => Promise<number>;
  blockUser: (personId: string) => void;
  unblockUser: (personId: string) => void;
  markNotificationsRead: () => void;
};

const profileFromApi = (user: ApiUser): Profile => ({
  name: user.name,
  age: String(user.age),
  email: user.email || '',
  username: user.username || '',
  bio: user.bio,
  city: user.city,
  interests: user.interests,
  languages: user.languages,
  dateOfBirth: user.date_of_birth || undefined,
  gender: user.gender || undefined,
  preferredLanguage: user.preferred_language || undefined,
  conversationTopics: user.conversation_topics || [],
  avatarUri: user.avatar_url || undefined,
  vibeStatus: user.vibe_status || undefined,
  vibeExpiresAt: user.vibe_expires_at || undefined,
});

const messageOf = (error: unknown) =>
  error instanceof Error ? error.message : 'Something went wrong.';

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      authenticated: false,
      currentUserId: null,
      sessionReady: false,
      loading: false,
      apiError: null,
      selectedPurpose: 'Talk',
      anonymousMode: false,
      darkMode: true,
      profile: {
        name: '',
        age: '',
        email: '',
        username: '',
        bio: '',
        city: '',
        interests: [],
        languages: [],
        conversationTopics: [],
      },
      people: [],
      chats: [],
      messages: [],
      communityMessages: [],
      posts: [],
      comments: [],
      communities: [],
      joinedCommunities: [],
      blockedUsers: [],
      savedPosts: [],
      notifications: 0,
      searchFilters: {
        purpose: 'Talk',
        language: 'English',
        minAge: 18,
        maxAge: 35,
        onlineOnly: false,
        gender: 'Any',
        city: '',
      },
      setSearchFilters: (filters) =>
        set((state) => ({ searchFilters: { ...state.searchFilters, ...filters } })),
      setDarkMode: (darkMode) => set({ darkMode }),
      bootstrap: async () => {
        set({ loading: true, apiError: null });
        try {
          const user = await authApi.restore();
          if (!user) {
            set({ authenticated: false, sessionReady: true, loading: false });
            return;
          }
          const [people, communities, posts, notifications] = await Promise.all([
            discoveryApi.users(),
            discoveryApi.communities(),
            discoveryApi.posts(),
            notificationsApi.list(),
          ]);
          set({
            authenticated: true,
            currentUserId: user.id,
            sessionReady: true,
            loading: false,
            profile: profileFromApi(user),
            people: people.data.map((item, index) => ({
              id: item.id,
              name: item.name,
              age: item.age,
              username: item.username || '',
              bio: item.bio,
              city: item.city,
              languages: item.languages,
              interests: item.interests,
              conversationTopics: item.conversation_topics,
              performanceRating: item.performance_rating,
              reviewCount: item.review_count,
              completedSessions: item.completed_sessions,
              performanceTier: item.performance_tier,
              online: item.is_online,
              avatarUrl: item.avatar_url,
              avatarColor: ['#5B5CE2', '#2FB67C', '#FF6B6B', '#8B6BD9'][index % 4],
            })),
            communities: communities.data.map((item) => ({
              id: item.id,
              name: item.name,
              category: item.category,
              description: item.description,
              members: item.member_count,
              color: item.color,
              joined: item.joined,
              privacy: item.privacy,
              rules: item.rules,
              logoUrl: item.logo_url,
              coverUrl: item.cover_url,
              tags: item.tags,
              location: item.location,
              language: item.language,
              isOwner: item.is_owner,
              joinPending: item.join_pending,
              premiumPrice: item.premium_price || 0,
              kind: item.kind,
              maxMembers: item.max_members,
            })),
            posts: posts.data.map((item) => ({
              id: item.id,
              author: item.author_name,
              authorId: item.author_id,
              authorUsername: item.author_username || undefined,
              mine: item.mine,
              community: item.community_name,
              body: item.body,
              likes: item.like_count,
              comments: item.comment_count,
              anonymous: item.anonymous,
              authorAvatarUrl: item.author_avatar_url,
              liked: item.liked,
              saved: item.saved,
              postType: `${item.type[0].toUpperCase()}${item.type.slice(1)}` as Post['postType'],
              pollOptions: item.poll_options,
              pollResults: item.poll_results,
              myVote: item.my_vote,
              createdAt: item.created_at,
              visibility: item.visibility,
              coinPrice: item.coin_price,
              locked: item.locked,
              attachment: item.media_url
                ? { id: item.id, kind: 'image', uri: item.media_url, name: 'Post image' }
                : undefined,
              tipCount: item.tip_count,
              tipTotal: item.tip_total,
              isBoosted: item.is_boosted,
              boostedUntil: item.boosted_until,
              boostCost: item.boost_cost,
              bountyAmount: item.bounty_amount,
              bountyStatus: item.bounty_status,
              bountyWinnerCommentId: item.bounty_winner_comment_id,
              gifts: item.gifts,
            })),
            joinedCommunities: communities.data
              .filter((item) => item.joined)
              .map((item) => item.id),
            notifications: notifications.data.filter((item) => !item.is_read).length,
          });
        } catch (error) {
          set({
            authenticated: false,
            sessionReady: true,
            loading: false,
            apiError: messageOf(error),
          });
        }
      },
      login: async (email, password) => {
        set({ loading: true, apiError: null });
        try {
          const user = await authApi.login(email, password);
          set({
            authenticated: true,
            currentUserId: user.id,
            sessionReady: true,
            loading: false,
            profile: profileFromApi(user),
          });
          await get().bootstrap();
        } catch (error) {
          set({ loading: false, apiError: messageOf(error) });
          throw error;
        }
      },
      register: async (payload) => {
        set({ loading: true, apiError: null });
        try {
          const user = await authApi.register(payload);
          set({
            authenticated: true,
            currentUserId: user.id,
            sessionReady: true,
            loading: false,
            profile: profileFromApi(user),
          });
          await get().bootstrap();
        } catch (error) {
          set({ loading: false, apiError: messageOf(error) });
          throw error;
        }
      },
      logout: async () => {
        try {
          await unregisterPushNotifications();
          await authApi.logout();
        } finally {
          set({ authenticated: false, currentUserId: null, sessionReady: true });
        }
      },
      updateProfile: (value) => {
        set((state) => ({ profile: { ...state.profile, ...value } }));
        const profilePayload = {
          name: value.name,
          username: value.username,
          bio: value.bio,
          city: value.city,
          avatar_url: value.avatarUri,
          date_of_birth: value.dateOfBirth,
          gender: value.gender,
          preferred_language: value.preferredLanguage,
        };
        const preferencePayload = {
          interests: value.interests,
          languages: value.languages,
          conversation_topics: value.conversationTopics,
        };
        void usersApi
          .updateProfile(profilePayload)
          .catch((error) => set({ apiError: messageOf(error) }));
        if (value.interests || value.languages || value.conversationTopics)
          void usersApi
            .updatePreferences(preferencePayload)
            .catch((error) => set({ apiError: messageOf(error) }));
      },
      selectPurpose: (selectedPurpose) => set({ selectedPurpose }),
      setAnonymousMode: (anonymousMode) => set({ anonymousMode }),
      sendMessage: (chatId, text, attachment, replyTo) => {
        const clean = text.trim();
        if (!clean && !attachment) return;
        const message: Message = {
          id: String(Date.now()),
          chatId,
          text: clean,
          attachment,
          mine: true,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          status: 'sending',
          replyToId: replyTo?.id,
          replyPreview: replyTo?.text || replyTo?.attachment?.name,
        };
        set((state) => ({
          messages: [...state.messages, message],
          chats: state.chats.map((chat) =>
            chat.id === chatId
              ? { ...chat, preview: clean || `Sent ${attachment?.kind}`, time: 'Now', unread: 0 }
              : chat,
          ),
        }));
        void (async () => {
          const uploaded = attachment ? await uploadAttachment(attachment) : null;
          const payload = {
            text: clean,
            type: uploaded?.kind || 'text',
            media_url: uploaded?.url,
            media_name: uploaded?.name,
            mime_type: uploaded?.mime_type,
            reply_to_id: replyTo?.id,
          };
          const sentBySocket = realtimeService.privateChannel(chatId).send({
            event: 'message',
            client_id: message.id,
            data: payload,
          });
          if (!sentBySocket) {
            const { data } = await chatApi.send(chatId, payload);
            set((state) => ({
              messages: state.messages.map((item) =>
                item.id === message.id ? { ...item, id: data.id, status: 'delivered' } : item,
              ),
            }));
          }
        })().catch((error) =>
          set((state) => ({
            apiError: messageOf(error),
            messages: state.messages.map((item) =>
              item.id === message.id ? { ...item, status: 'failed' } : item,
            ),
          })),
        );
      },
      sendCommunityMessage: (communityId, text, attachment) => {
        const clean = text.trim();
        if (!clean && !attachment) return;
        const state = get();
        const message: CommunityMessage = {
          id: String(Date.now()),
          communityId,
          authorId: 'me',
          author: state.profile.name,
          text: clean,
          attachment,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          mine: true,
          role: 'member',
        };
        set({ communityMessages: [...state.communityMessages, message] });
        void (async () => {
          const uploaded = attachment ? await uploadAttachment(attachment) : null;
          const payload = {
            text: clean,
            media_url: uploaded?.url,
            media_name: uploaded?.name,
            mime_type: uploaded?.mime_type,
          };
          const sentBySocket = realtimeService.communityChannel(communityId).send({
            event: 'message',
            client_id: message.id,
            data: payload,
          });
          if (!sentBySocket) await contentApi.sendCommunityMessage(communityId, payload);
        })().catch((error) => set({ apiError: messageOf(error) }));
      },
      createPost: async (body, anonymous, options) => {
        try {
          const uploaded = options?.attachment ? await uploadAttachment(options.attachment) : null;
          const { data } = await contentApi.createPost({
            body,
            anonymous,
            type: options?.postType?.toLowerCase() || 'text',
            media_url: uploaded?.url,
            poll_options: options?.pollOptions || [],
            community_id: options?.communityId,
            visibility: options?.visibility || 'public',
            bounty_amount: (options as any)?.bountyAmount,
            coin_price: (options as any)?.coinPrice,
          });
          const community = get().communities.find((item) => item.id === options?.communityId);
          set((state) => ({
            posts: [
              {
                id: data.id,
                author: anonymous ? 'Anonymous member' : state.profile.name,
                authorId: state.currentUserId || undefined,
                authorUsername: anonymous ? 'anonymous' : state.profile.username || undefined,
                mine: true,
                community: community?.name || 'Discover',
                body: data.body,
                likes: data.like_count,
                comments: data.comment_count,
                anonymous: data.anonymous,
                createdAt: data.created_at,
                visibility: data.visibility,
                coinPrice: data.coin_price,
                locked: false,
                tipCount: data.tip_count,
                tipTotal: data.tip_total,
                isBoosted: data.is_boosted,
                boostedUntil: data.boosted_until,
                boostCost: data.boost_cost,
                bountyAmount: data.bounty_amount,
                bountyStatus: data.bounty_status,
                bountyWinnerCommentId: data.bounty_winner_comment_id,
                gifts: [],
                ...options,
              },
              ...state.posts,
            ],
          }));
        } catch (error) {
          set({ apiError: messageOf(error) });
          throw error;
        }
      },
      addComment: (postId, body) =>
        set((state) => {
          void contentApi
            .addComment(postId, body.trim())
            .catch((error) => set({ apiError: messageOf(error) }));
          return {
            comments: [
              ...state.comments,
              {
                id: String(Date.now()),
                postId,
                author: state.profile.name,
                body: body.trim(),
                time: 'Now',
              },
            ],
            posts: state.posts.map((post) =>
              post.id === postId ? { ...post, comments: post.comments + 1 } : post,
            ),
          };
        }),
      createCommunity: async (value) => {
        try {
          const { data } = await contentApi.createCommunity({
            name: value.name,
            category: value.category,
            description: value.description,
            privacy: value.privacy || 'public',
            rules: value.rules || ['Be kind', 'Stay on topic', 'No spam'],
            color: value.color || '#5B5CE2',
            logo_url: value.logoUrl,
            cover_url: value.coverUrl,
            tags: value.tags || [],
            location: value.location,
            language: value.language,
            kind: value.kind || 'community',
            max_members: value.maxMembers || 500,
            premium_price: value.premiumPrice || 0,
          });
          const item: Community = {
            ...value,
            id: data.id,
            members: data.member_count,
            joined: true,
            color: data.color,
            isOwner: true,
            kind: data.kind,
            maxMembers: data.max_members,
            premiumPrice: data.premium_price || 0,
          };
          set((state) => ({
            communities: [item, ...state.communities],
            joinedCommunities: [data.id, ...state.joinedCommunities],
          }));
          return data.id as string;
        } catch (error) {
          set({ apiError: messageOf(error) });
          throw error;
        }
      },
      toggleLike: (postId) => {
        const previous = get().posts;
        set({
          posts: previous.map((post) =>
            post.id === postId
              ? { ...post, liked: !post.liked, likes: post.likes + (post.liked ? -1 : 1) }
              : post,
          ),
        });
        void contentApi
          .toggleLike(postId)
          .catch((error) => set({ posts: previous, apiError: messageOf(error) }));
      },
      toggleSave: (postId) => {
        const previous = get().savedPosts;
        set({
          savedPosts: previous.includes(postId)
            ? previous.filter((id) => id !== postId)
            : [...previous, postId],
        });
        void contentApi
          .toggleSave(postId)
          .catch((error) => set({ savedPosts: previous, apiError: messageOf(error) }));
      },
      toggleCommunity: async (communityId) => {
        const previous = get().joinedCommunities;
        const joining = !previous.includes(communityId);
        try {
          const { data } = joining
            ? await contentApi.joinCommunity(communityId)
            : await contentApi.leaveCommunity(communityId);
          const pending = joining && data?.status === 'pending';
          set((state) => ({
            joinedCommunities: pending
              ? previous
              : joining
                ? [...previous, communityId]
                : previous.filter((id) => id !== communityId),
            communities: state.communities.map((item) =>
              item.id === communityId
                ? { ...item, joined: joining && !pending, joinPending: pending }
                : item,
            ),
            apiError: null,
          }));
        } catch (error) {
          set({ joinedCommunities: previous, apiError: messageOf(error) });
          throw error;
        }
      },
      deleteCommunity: async (communityId) => {
        const previousCommunities = get().communities;
        const previousJoined = get().joinedCommunities;
        set((state) => ({
          communities: state.communities.filter((item) => item.id !== communityId),
          joinedCommunities: state.joinedCommunities.filter((id) => id !== communityId),
          posts: state.posts.filter((post) => (post as any).communityId !== communityId),
        }));
        try {
          await contentApi.deleteCommunity(communityId);
        } catch (error) {
          set({
            communities: previousCommunities,
            joinedCommunities: previousJoined,
            apiError: messageOf(error),
          });
          throw error;
        }
      },
      deletePost: async (postId) => {
        const previous = get().posts;
        set((state) => ({ posts: state.posts.filter((post) => post.id !== postId) }));
        try {
          await contentApi.deletePost(postId);
        } catch (error) {
          set({ posts: previous, apiError: messageOf(error) });
          throw error;
        }
      },
      sharePost: async (postId, userIds) => {
        try {
          const { data } = await contentApi.sharePost(postId, userIds);
          return (data as any).sent as number;
        } catch (error) {
          set({ apiError: messageOf(error) });
          throw error;
        }
      },
      shareCommunity: async (communityId, userIds) => {
        try {
          const { data } = await contentApi.shareCommunity(communityId, userIds);
          return (data as any).sent as number;
        } catch (error) {
          set({ apiError: messageOf(error) });
          throw error;
        }
      },
      blockUser: (personId) => {
        const previous = get().blockedUsers;
        const previousChats = get().chats;
        const previousMessages = get().messages;
        const blockedChatIds = previousChats
          .filter((chat) => chat.personId === personId)
          .map((chat) => chat.id);
        set({
          blockedUsers: previous.includes(personId) ? previous : [...previous, personId],
          chats: previousChats.filter((chat) => chat.personId !== personId),
          messages: previousMessages.filter((message) => !blockedChatIds.includes(message.chatId)),
        });
        void safetyApi.block(personId).catch((error) =>
          set({
            blockedUsers: previous,
            chats: previousChats,
            messages: previousMessages,
            apiError: messageOf(error),
          }),
        );
      },
      unblockUser: (personId) => {
        const previous = get().blockedUsers;
        set({ blockedUsers: previous.filter((id) => id !== personId) });
        void safetyApi
          .unblock(personId)
          .catch((error) => set({ blockedUsers: previous, apiError: messageOf(error) }));
      },
      markNotificationsRead: () => {
        set({ notifications: 0 });
        void notificationsApi.markAllRead().catch((error) => set({ apiError: messageOf(error) }));
      },
    }),
    {
      name: 'vibecircle-state-v3',
      version: 3,
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        selectedPurpose: state.selectedPurpose,
        anonymousMode: state.anonymousMode,
        darkMode: state.darkMode,
        profile: state.profile,
        blockedUsers: state.blockedUsers,
        savedPosts: state.savedPosts,
      }),
    },
  ),
);
