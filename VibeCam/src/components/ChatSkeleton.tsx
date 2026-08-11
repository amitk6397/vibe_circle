import React, { useEffect, useRef } from 'react';
import { Animated, StyleSheet, View } from 'react-native';
import { colors } from '../theme';

export function ChatSkeleton({ rows = 5 }: { rows?: number }) {
  const opacity = useRef(new Animated.Value(0.35)).current;
  useEffect(() => {
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, { toValue: 0.85, duration: 700, useNativeDriver: true }),
        Animated.timing(opacity, { toValue: 0.35, duration: 700, useNativeDriver: true }),
      ]),
    );
    animation.start();
    return () => animation.stop();
  }, [opacity]);
  return (
    <View style={styles.container}>
      {Array.from({ length: rows }).map((_, index) => (
        <Animated.View
          key={index}
          style={[
            styles.row,
            index % 2 ? styles.right : styles.left,
            { opacity, width: index % 3 === 0 ? '62%' : '76%' },
          ]}
        >
          <View style={styles.line} />
          <View style={styles.shortLine} />
        </Animated.View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, gap: 14 },
  row: { backgroundColor: colors.surfaceAlt, borderRadius: 17, padding: 14, gap: 8 },
  left: { alignSelf: 'flex-start', borderBottomLeftRadius: 5 },
  right: { alignSelf: 'flex-end', borderBottomRightRadius: 5 },
  line: { height: 10, borderRadius: 5, backgroundColor: colors.border },
  shortLine: { width: '42%', height: 8, borderRadius: 4, backgroundColor: colors.border },
});
