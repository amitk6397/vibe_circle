import React, { useState } from 'react';
import {
  Alert,
  Image,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Avatar, Button, Header, IconButton, Screen, ui } from '../../../components/ui';
import { colors } from '../../../theme';
import { useAppStore } from '../../../store/useAppStore';
import { useCommunityChatViewModel } from '../viewmodels/useCommunityChatViewModel';
import { LocalAttachment } from '../../../types';
import { formatFileSize, pickDocument, pickImage } from '../../../services/mediaPicker';
import { ChatSkeleton } from '../../../components/ChatSkeleton';
import { useCommunityRealtime } from '../viewmodels/useCommunityRealtime';

export default function CommunityChatScreen({ navigation, route }: any) {
  const [text, setText] = useState('');
  const [attachment, setAttachment] = useState<LocalAttachment | null>(null);
  const viewModel = useCommunityChatViewModel(route.params.communityId);
  const realtime = useCommunityRealtime(route.params.communityId, viewModel.joined);
  const people = useAppStore((state) => state.people);

  if (!viewModel.community) {
    return (
      <Screen>
        <Header title="Community chat" onBack={() => navigation.goBack()} />
        <Text style={ui.muted}>This community is unavailable. Refresh and try again.</Text>
      </Screen>
    );
  }
  const community = viewModel.community;

  const send = () => {
    if (!text.trim() && !attachment) return;
    if (text.trim().length > 1000) {
      Alert.alert('Message too long', 'Community messages can contain up to 1,000 characters.');
      return;
    }
    viewModel.sendMessage(text, attachment || undefined);
    realtime.sendTyping(false);
    setText('');
    setAttachment(null);
  };

  if (!viewModel.joined) {
    return (
      <Screen>
        <Header title="Community chat" onBack={() => navigation.goBack()} />
        <View style={styles.joinGate}>
          <View style={[styles.largeIcon, { backgroundColor: viewModel.community.color }]}>
            <Ionicons name="chatbubbles" size={42} color="#fff" />
          </View>
          <Text style={ui.h2}>Join to enter the conversation</Text>
          <Text style={[ui.muted, styles.center]}>
            Read the rules, join the community, and then message its members.
          </Text>
          <Button title="Join community" onPress={viewModel.join} />
        </View>
      </Screen>
    );
  }

  return (
    <Screen scroll={false}>
      <KeyboardAvoidingView
        style={styles.page}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <View style={styles.headerWrap}>
          <Header
            title={community.name}
            subtitle={`${viewModel.community.members.toLocaleString()} members · ${
              realtime.typing
                ? 'Someone is typing...'
                : realtime.connected
                  ? 'Live chat'
                  : 'Reconnecting...'
            }`}
            onBack={() => navigation.goBack()}
            right={
              <IconButton
                icon="people-outline"
                onPress={() =>
                  navigation.navigate('CommunityMembers', {
                    communityId: community.id,
                  })
                }
              />
            }
          />
        </View>

        <View style={styles.safetyNotice}>
          <Ionicons name="shield-checkmark" size={18} color={colors.success} />
          <Text style={styles.safetyText}>
            Be respectful. Avoid sharing phone numbers or private information.
          </Text>
        </View>

        <ScrollView
          style={styles.messages}
          contentContainerStyle={styles.messageContent}
          showsVerticalScrollIndicator={false}
        >
          <Text style={styles.dayLabel}>TODAY</Text>
          {!!realtime.error && !!viewModel.messages.length && (
            <Pressable style={styles.inlineError} onPress={() => void realtime.retry()}>
              <Ionicons name="cloud-offline-outline" color={colors.danger} />
              <Text style={styles.inlineErrorText}>{realtime.error} · Tap to retry</Text>
            </Pressable>
          )}
          {realtime.loading && !viewModel.messages.length && <ChatSkeleton />}
          {!!realtime.error && !viewModel.messages.length && (
            <View style={styles.errorCard}>
              <Text style={styles.errorText}>{realtime.error}</Text>
              <Button
                title="Try again"
                compact
                tone="secondary"
                onPress={() => void realtime.retry()}
              />
            </View>
          )}
          {viewModel.messages.map((message) => {
            const person = people.find((item) => item.id === message.authorId);
            return (
              <View
                key={message.id}
                style={[styles.messageRow, message.mine && styles.myMessageRow]}
              >
                {!message.mine && (
                  <Pressable
                    onPress={() =>
                      person && navigation.navigate('PublicProfile', { personId: person.id })
                    }
                  >
                    <Avatar
                      name={message.author}
                      color={person?.avatarColor}
                      online={person?.online}
                      size={38}
                    />
                  </Pressable>
                )}
                <View style={[styles.messageBlock, message.mine && styles.myMessageBlock]}>
                  {!message.mine && (
                    <View style={styles.authorRow}>
                      <Text style={styles.author}>{message.author}</Text>
                      {message.role === 'moderator' && <Text style={styles.role}>MOD</Text>}
                    </View>
                  )}
                  <View style={[styles.bubble, message.mine && styles.myBubble]}>
                    {message.attachment && (
                      <Pressable
                        onPress={() =>
                          navigation.navigate('MediaPreview', { attachment: message.attachment })
                        }
                        style={styles.attachment}
                      >
                        {message.attachment.kind === 'image' ? (
                          <Image
                            source={{ uri: message.attachment.uri }}
                            style={styles.attachmentImage}
                          />
                        ) : (
                          <View style={styles.fileRow}>
                            <Ionicons
                              name="document-text"
                              size={24}
                              color={message.mine ? '#fff' : colors.primary}
                            />
                            <View style={{ flex: 1 }}>
                              <Text
                                style={[styles.fileName, message.mine && styles.myMessageText]}
                                numberOfLines={1}
                              >
                                {message.attachment.name}
                              </Text>
                              <Text style={[styles.time, message.mine && styles.myTime]}>
                                {formatFileSize(message.attachment.size)}
                              </Text>
                            </View>
                          </View>
                        )}
                      </Pressable>
                    )}
                    {!!message.text && (
                      <Text style={[styles.messageText, message.mine && styles.myMessageText]}>
                        {message.text}
                      </Text>
                    )}
                    <Text style={[styles.time, message.mine && styles.myTime]}>{message.time}</Text>
                  </View>
                </View>
              </View>
            );
          })}
        </ScrollView>

        {attachment && (
          <View style={styles.pendingAttachment}>
            {attachment.kind === 'image' ? (
              <Image source={{ uri: attachment.uri }} style={styles.pendingImage} />
            ) : (
              <Ionicons name="document-text" size={27} color={colors.primary} />
            )}
            <View style={{ flex: 1 }}>
              <Text style={styles.fileName} numberOfLines={1}>
                {attachment.name}
              </Text>
              <Text style={styles.time}>{formatFileSize(attachment.size)} · Ready to send</Text>
            </View>
            <IconButton icon="close" onPress={() => setAttachment(null)} />
          </View>
        )}

        <View style={styles.composer}>
          <IconButton
            icon="add"
            onPress={() =>
              Alert.alert('Add attachment', 'Choose what you want to share.', [
                { text: 'Cancel', style: 'cancel' },
                { text: 'Photo', onPress: async () => setAttachment(await pickImage()) },
                { text: 'File', onPress: async () => setAttachment(await pickDocument()) },
              ])
            }
          />
          <View style={styles.inputWrap}>
            <TextInput
              value={text}
              onChangeText={(value) => {
                setText(value);
                realtime.sendTyping(Boolean(value.trim()));
              }}
              placeholder="Message the community..."
              placeholderTextColor={colors.muted}
              multiline
              maxLength={1000}
              style={styles.input}
            />
            {!!text.length && <Text style={styles.counter}>{text.length}/1000</Text>}
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Send community message"
            onPress={send}
            disabled={!text.trim() && !attachment}
            style={[styles.send, !text.trim() && !attachment && styles.sendDisabled]}
          >
            <Ionicons name="send" size={20} color="#fff" />
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1 },
  headerWrap: { paddingHorizontal: 12, backgroundColor: colors.surface },
  safetyNotice: {
    marginHorizontal: 12,
    marginVertical: 9,
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 12,
    backgroundColor: colors.surfaceAlt,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  safetyText: { flex: 1, color: '#28775A', fontSize: 11, lineHeight: 16 },
  messages: { flex: 1 },
  messageContent: { paddingHorizontal: 12, paddingVertical: 14, paddingBottom: 24, gap: 14 },
  dayLabel: { textAlign: 'center', color: colors.muted, fontSize: 10, fontWeight: '800' },
  messageRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 9 },
  myMessageRow: { justifyContent: 'flex-end' },
  messageBlock: { maxWidth: '78%', gap: 4 },
  myMessageBlock: { alignItems: 'flex-end' },
  authorRow: { flexDirection: 'row', alignItems: 'center', gap: 7, paddingLeft: 3 },
  author: { color: colors.text, fontSize: 12, fontWeight: '800' },
  role: {
    color: colors.primary,
    fontSize: 8,
    fontWeight: '900',
    backgroundColor: '#E9EAFF',
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 5,
  },
  bubble: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 17,
    borderBottomLeftRadius: 5,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  myBubble: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
    borderBottomLeftRadius: 17,
    borderBottomRightRadius: 5,
  },
  messageText: { color: colors.text, fontSize: 14, lineHeight: 20 },
  myMessageText: { color: '#fff' },
  time: { color: colors.muted, fontSize: 9, marginTop: 4, textAlign: 'right' },
  myTime: { color: 'rgba(255,255,255,.7)' },
  attachment: { marginBottom: 7 },
  attachmentImage: {
    width: 220,
    height: 145,
    borderRadius: 12,
    backgroundColor: colors.border,
  },
  fileRow: { minWidth: 210, flexDirection: 'row', alignItems: 'center', gap: 9 },
  fileName: { color: colors.text, fontSize: 12, fontWeight: '800' },
  pendingAttachment: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: colors.surfaceAlt,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  pendingImage: { width: 48, height: 48, borderRadius: 11 },
  composer: {
    padding: 10,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.surface,
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 8,
  },
  inputWrap: {
    flex: 1,
    minHeight: 44,
    maxHeight: 110,
    backgroundColor: colors.bg,
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  input: { color: colors.text, fontSize: 14, minHeight: 30, maxHeight: 78, padding: 0 },
  counter: { color: colors.muted, fontSize: 8, textAlign: 'right' },
  send: {
    width: 44,
    height: 44,
    borderRadius: 15,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendDisabled: { backgroundColor: '#B9BDCA' },
  joinGate: { alignItems: 'center', gap: 14, paddingHorizontal: 12, paddingTop: 70 },
  largeIcon: {
    width: 92,
    height: 92,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
  },
  center: { textAlign: 'center' },
  errorCard: { padding: 14, borderRadius: 14, backgroundColor: 'rgba(239,68,68,0.12)', gap: 10 },
  errorText: { color: colors.danger, fontSize: 12 },
  inlineError: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    padding: 10,
    borderRadius: 12,
    backgroundColor: 'rgba(239,68,68,0.12)',
  },
  inlineErrorText: { flex: 1, color: colors.danger, fontSize: 11 },
});
