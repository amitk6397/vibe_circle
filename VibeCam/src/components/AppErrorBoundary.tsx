import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Button } from './ui';
import { colors } from '../theme';

type State = { failed: boolean };

export class AppErrorBoundary extends React.Component<React.PropsWithChildren, State> {
  state: State = { failed: false };

  static getDerivedStateFromError(): State {
    return { failed: true };
  }

  componentDidCatch(error: Error) {
    if (__DEV__) console.error('Uncaught application error', error);
  }

  render() {
    if (!this.state.failed) return this.props.children;
    return (
      <View style={styles.page}>
        <Text style={styles.title}>Something went wrong</Text>
        <Text style={styles.body}>Your data is safe. Try loading the app again.</Text>
        <Button title="Try again" onPress={() => this.setState({ failed: false })} />
      </View>
    );
  }
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 14,
    padding: 28,
    backgroundColor: colors.bg,
  },
  title: { fontSize: 24, fontWeight: '800', color: colors.text },
  body: { color: colors.muted, textAlign: 'center' },
});
