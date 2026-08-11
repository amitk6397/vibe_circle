/**
 * CoinAnimation.tsx — Premium animated coin feedback for VibeCam
 *
 * Exports:
 *   <CoinGainAnimation />  — Shows golden coins raining down (on receive)
 *   <CoinSpendAnimation /> — Shows red minus flash (on spend)
 *   <LowBalanceWarning />  — Pulsing amber alert bar
 *   <GracePeriodTimer />   — Countdown timer with recharge CTA
 *
 * Usage:
 *   import { CoinGainAnimation, CoinSpendAnimation } from '@/components/CoinAnimation';
 *
 *   // In your component:
 *   const [showGain, setShowGain] = useState(false);
 *   <CoinGainAnimation visible={showGain} amount={50} onDone={() => setShowGain(false)} />
 */

import React, { useEffect, useRef, useState } from 'react';
import {
  Animated,
  Easing,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  Dimensions,
} from 'react-native';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

interface CoinGainAnimationProps {
  visible: boolean;
  amount?: number;
  onDone?: () => void;
}

interface CoinSpendAnimationProps {
  visible: boolean;
  amount?: number;
  onDone?: () => void;
}

interface LowBalanceWarningProps {
  balance: number;
  minutesLeft: number;
  onRecharge: () => void;
}

interface GracePeriodTimerProps {
  graceSeconds: number;
  onRecharge: () => void;
  onExpired: () => void;
}

// ─────────────────────────────────────────────
// Coin Particle (for rain animation)
// ─────────────────────────────────────────────

function CoinParticle({ delay, startX }: { delay: number; startX: number }) {
  const translateY = useRef(new Animated.Value(-60)).current;
  const opacity = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(0.4)).current;
  const rotate = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.sequence([
      Animated.delay(delay),
      Animated.parallel([
        Animated.timing(opacity, { toValue: 1, duration: 150, useNativeDriver: true }),
        Animated.timing(scale, { toValue: 1, duration: 200, useNativeDriver: true }),
        Animated.timing(translateY, {
          toValue: 280,
          duration: 1000,
          easing: Easing.in(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(rotate, {
          toValue: 1,
          duration: 1000,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.sequence([
          Animated.delay(700),
          Animated.timing(opacity, { toValue: 0, duration: 300, useNativeDriver: true }),
        ]),
      ]),
    ]).start();
  }, []);

  const spin = rotate.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '360deg'] });

  return (
    <Animated.Text
      style={[
        styles.coinParticle,
        {
          left: startX,
          transform: [{ translateY }, { scale }, { rotate: spin }],
          opacity,
        },
      ]}
    >
      🪙
    </Animated.Text>
  );
}

// ─────────────────────────────────────────────
// Coin Gain Animation (golden rain)
// ─────────────────────────────────────────────

export function CoinGainAnimation({ visible, amount = 0, onDone }: CoinGainAnimationProps) {
  const labelOpacity = useRef(new Animated.Value(0)).current;
  const labelTranslateY = useRef(new Animated.Value(0)).current;
  const labelScale = useRef(new Animated.Value(0.5)).current;

  const particles = Array.from({ length: 8 }, (_, i) => ({
    id: i,
    delay: i * 80,
    startX: 20 + Math.random() * (SCREEN_WIDTH - 60),
  }));

  useEffect(() => {
    if (!visible) return;
    // Animate label: pop up and fade out
    Animated.sequence([
      Animated.parallel([
        Animated.timing(labelOpacity, { toValue: 1, duration: 250, useNativeDriver: true }),
        Animated.timing(labelScale, { toValue: 1, duration: 300, easing: Easing.out(Easing.back(2)), useNativeDriver: true }),
        Animated.timing(labelTranslateY, { toValue: -60, duration: 800, easing: Easing.out(Easing.quad), useNativeDriver: true }),
      ]),
      Animated.timing(labelOpacity, { toValue: 0, duration: 400, useNativeDriver: true }),
    ]).start(() => onDone?.());
  }, [visible]);

  if (!visible) return null;

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      {/* Falling coin particles */}
      {particles.map((p) => (
        <CoinParticle key={p.id} delay={p.delay} startX={p.startX} />
      ))}
      {/* +N coins label */}
      <Animated.View
        style={[
          styles.gainLabel,
          {
            opacity: labelOpacity,
            transform: [{ translateY: labelTranslateY }, { scale: labelScale }],
          },
        ]}
      >
        <Text style={styles.gainLabelText}>+{amount} 🪙</Text>
      </Animated.View>
    </View>
  );
}

// ─────────────────────────────────────────────
// Coin Spend Animation (red minus flash)
// ─────────────────────────────────────────────

export function CoinSpendAnimation({ visible, amount = 0, onDone }: CoinSpendAnimationProps) {
  const opacity = useRef(new Animated.Value(0)).current;
  const translateY = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(0.8)).current;

  useEffect(() => {
    if (!visible) return;
    opacity.setValue(0);
    translateY.setValue(0);
    scale.setValue(0.8);

    Animated.sequence([
      Animated.parallel([
        Animated.timing(opacity, { toValue: 1, duration: 150, useNativeDriver: true }),
        Animated.timing(scale, { toValue: 1.2, duration: 200, easing: Easing.out(Easing.back(1.5)), useNativeDriver: true }),
        Animated.timing(translateY, { toValue: -40, duration: 600, easing: Easing.out(Easing.quad), useNativeDriver: true }),
      ]),
      Animated.timing(opacity, { toValue: 0, duration: 300, useNativeDriver: true }),
    ]).start(() => onDone?.());
  }, [visible]);

  if (!visible) return null;

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <Animated.View
        style={[
          styles.spendLabel,
          {
            opacity,
            transform: [{ translateY }, { scale }],
          },
        ]}
      >
        <Text style={styles.spendLabelText}>-{amount} 🪙</Text>
      </Animated.View>
    </View>
  );
}

// ─────────────────────────────────────────────
// Low Balance Warning Bar
// ─────────────────────────────────────────────

export function LowBalanceWarning({ balance, minutesLeft, onRecharge }: LowBalanceWarningProps) {
  const pulse = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    const anim = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1.04, duration: 600, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 1, duration: 600, useNativeDriver: true }),
      ])
    );
    anim.start();
    return () => anim.stop();
  }, []);

  return (
    <Animated.View style={[styles.lowBalanceBar, { transform: [{ scale: pulse }] }]}>
      <Text style={styles.lowBalanceIcon}>⚠️</Text>
      <View style={styles.lowBalanceTextContainer}>
        <Text style={styles.lowBalanceTitle}>Low Balance!</Text>
        <Text style={styles.lowBalanceSubtitle}>
          {balance} coins left · ~{minutesLeft.toFixed(1)} min
        </Text>
      </View>
      <TouchableOpacity style={styles.rechargeButton} onPress={onRecharge} activeOpacity={0.8}>
        <Text style={styles.rechargeButtonText}>Recharge</Text>
      </TouchableOpacity>
    </Animated.View>
  );
}

// ─────────────────────────────────────────────
// Grace Period Timer (countdown + CTA)
// ─────────────────────────────────────────────

export function GracePeriodTimer({ graceSeconds, onRecharge, onExpired }: GracePeriodTimerProps) {
  const [remaining, setRemaining] = useState(graceSeconds);
  const shake = useRef(new Animated.Value(0)).current;

  // Countdown
  useEffect(() => {
    if (remaining <= 0) {
      onExpired();
      return;
    }
    const timer = setTimeout(() => setRemaining((r) => r - 1), 1000);
    return () => clearTimeout(timer);
  }, [remaining]);

  // Shake animation every 3 seconds
  useEffect(() => {
    const doShake = () => {
      Animated.sequence([
        Animated.timing(shake, { toValue: 8, duration: 80, useNativeDriver: true }),
        Animated.timing(shake, { toValue: -8, duration: 80, useNativeDriver: true }),
        Animated.timing(shake, { toValue: 6, duration: 60, useNativeDriver: true }),
        Animated.timing(shake, { toValue: -6, duration: 60, useNativeDriver: true }),
        Animated.timing(shake, { toValue: 0, duration: 60, useNativeDriver: true }),
      ]).start();
    };
    doShake();
    const interval = setInterval(doShake, 3000);
    return () => clearInterval(interval);
  }, []);

  // Progress bar
  const progress = remaining / graceSeconds;

  return (
    <Animated.View style={[styles.graceContainer, { transform: [{ translateX: shake }] }]}>
      <Text style={styles.graceIcon}>🚨</Text>
      <Text style={styles.graceTitle}>Call ending in {remaining}s</Text>
      <Text style={styles.graceSubtitle}>Recharge now to continue the call</Text>

      {/* Progress bar */}
      <View style={styles.graceProgressTrack}>
        <View style={[styles.graceProgressFill, { width: `${progress * 100}%` }]} />
      </View>

      <TouchableOpacity style={styles.graceRechargeButton} onPress={onRecharge} activeOpacity={0.85}>
        <Text style={styles.graceRechargeText}>⚡ Recharge Now</Text>
      </TouchableOpacity>
    </Animated.View>
  );
}

// ─────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────

const styles = StyleSheet.create({
  // CoinParticle
  coinParticle: {
    position: 'absolute',
    top: 0,
    fontSize: 28,
  },
  // Gain label
  gainLabel: {
    position: 'absolute',
    alignSelf: 'center',
    top: '40%',
    backgroundColor: 'rgba(255, 215, 0, 0.15)',
    borderRadius: 24,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderWidth: 2,
    borderColor: '#FFD700',
  },
  gainLabelText: {
    fontSize: 28,
    fontWeight: '800',
    color: '#FFD700',
    textShadowColor: 'rgba(255, 165, 0, 0.8)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 8,
  },
  // Spend label
  spendLabel: {
    position: 'absolute',
    alignSelf: 'center',
    top: '45%',
    backgroundColor: 'rgba(255, 60, 60, 0.12)',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderWidth: 1.5,
    borderColor: '#FF3C3C',
  },
  spendLabelText: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FF4444',
    textShadowColor: 'rgba(255, 0, 0, 0.5)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  // Low balance warning bar
  lowBalanceBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A1A00',
    borderRadius: 16,
    marginHorizontal: 16,
    marginVertical: 8,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderWidth: 1.5,
    borderColor: '#F59E0B',
    shadowColor: '#F59E0B',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 12,
    elevation: 8,
  },
  lowBalanceIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  lowBalanceTextContainer: {
    flex: 1,
  },
  lowBalanceTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#F59E0B',
  },
  lowBalanceSubtitle: {
    fontSize: 12,
    color: '#D97706',
    marginTop: 2,
  },
  rechargeButton: {
    backgroundColor: '#F59E0B',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  rechargeButtonText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#1A0F00',
  },
  // Grace period timer
  graceContainer: {
    backgroundColor: '#1A0000',
    borderRadius: 20,
    marginHorizontal: 16,
    marginVertical: 8,
    paddingVertical: 20,
    paddingHorizontal: 20,
    borderWidth: 2,
    borderColor: '#EF4444',
    alignItems: 'center',
    shadowColor: '#EF4444',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.5,
    shadowRadius: 16,
    elevation: 12,
  },
  graceIcon: {
    fontSize: 36,
    marginBottom: 8,
  },
  graceTitle: {
    fontSize: 22,
    fontWeight: '900',
    color: '#EF4444',
    textAlign: 'center',
  },
  graceSubtitle: {
    fontSize: 13,
    color: '#FCA5A5',
    marginTop: 4,
    textAlign: 'center',
  },
  graceProgressTrack: {
    width: '100%',
    height: 6,
    backgroundColor: '#3F0000',
    borderRadius: 3,
    marginVertical: 16,
    overflow: 'hidden',
  },
  graceProgressFill: {
    height: 6,
    backgroundColor: '#EF4444',
    borderRadius: 3,
  },
  graceRechargeButton: {
    backgroundColor: '#EF4444',
    borderRadius: 14,
    paddingHorizontal: 32,
    paddingVertical: 14,
    width: '100%',
    alignItems: 'center',
  },
  graceRechargeText: {
    fontSize: 16,
    fontWeight: '900',
    color: '#FFFFFF',
    letterSpacing: 0.5,
  },
});
