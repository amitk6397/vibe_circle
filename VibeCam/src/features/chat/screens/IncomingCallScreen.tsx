import React, { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Avatar } from '../../../components/ui';
import { callApi } from '../services/callApi';

export default function IncomingCallScreen({ navigation, route }: any) {
  const [answering, setAnswering] = useState(false);
  const params = route.params;

  const decline = () => {
    if (answering) return;
    setAnswering(true);
    void callApi
      .action(params.callId, 'reject')
      .catch(() => undefined)
      .finally(() => navigation.goBack());
  };

  const accept = () => {
    if (answering) return;
    setAnswering(true);
    void callApi
      .action(params.callId, 'accept')
      .then(() =>
        navigation.replace(params.callType === 'video' ? 'VideoCall' : 'AudioCall', params),
      )
      .catch((error) => {
        setAnswering(false);
        Alert.alert('Call unavailable', error.message);
      });
  };

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.person}>
        <Text style={styles.eyebrow}>INCOMING {params.callType.toUpperCase()} CALL</Text>
        <Avatar name={params.name} size={116} color="#7879EA" />
        <Text style={styles.name}>{params.name}</Text>
        <Text style={styles.subtitle}>VibeCircle secure call</Text>
      </View>
      <View style={styles.actions}>
        <Action icon="close" label="Decline" danger disabled={answering} onPress={decline} />
        <Action icon="call" label="Accept" disabled={answering} onPress={accept} />
      </View>
    </SafeAreaView>
  );
}

function Action({ icon, label, danger, disabled, onPress }: any) {
  return (
    <Pressable disabled={disabled} onPress={onPress} style={styles.actionWrap}>
      <View style={[styles.action, danger && styles.danger, disabled && styles.disabled]}>
        <Ionicons name={icon} size={28} color="#fff" />
      </View>
      <Text style={styles.actionLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#101326', justifyContent: 'space-between', padding: 28 },
  person: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 14 },
  eyebrow: { color: '#AEB3CA', fontSize: 12, fontWeight: '900', letterSpacing: 1.2 },
  name: { color: '#fff', fontSize: 30, fontWeight: '900' },
  subtitle: { color: '#AEB3CA', fontSize: 14 },
  actions: { flexDirection: 'row', justifyContent: 'space-around', paddingBottom: 28 },
  actionWrap: { alignItems: 'center', gap: 9 },
  action: {
    width: 68,
    height: 68,
    borderRadius: 34,
    backgroundColor: '#35B779',
    alignItems: 'center',
    justifyContent: 'center',
  },
  danger: { backgroundColor: '#F04464' },
  disabled: { opacity: 0.55 },
  actionLabel: { color: '#fff', fontSize: 13, fontWeight: '800' },
});
