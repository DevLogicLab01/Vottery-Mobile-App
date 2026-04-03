// src/components/ui/ScreenContainer.tsx
// Base screen wrapper — dark background, safe area, scrollable option
import React from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  type ViewStyle,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors } from '../../config/theme';

interface ScreenContainerProps {
  children: React.ReactNode;
  scrollable?: boolean;
  style?: ViewStyle;
  padded?: boolean;
}

export const ScreenContainer: React.FC<ScreenContainerProps> = ({
  children,
  scrollable = false,
  style,
  padded = true,
}) => {
  const ContentWrapper = scrollable ? ScrollView : View;

  return (
    <SafeAreaView style={styles.container}>
      <ContentWrapper
        style={[styles.inner, !scrollable && padded && styles.padded, style]}
        {...(scrollable
          ? {
              contentContainerStyle: [styles.scrollContent, padded && styles.padded],
              keyboardShouldPersistTaps: 'handled',
              showsVerticalScrollIndicator: false,
            }
          : {})}
      >
        {children}
      </ContentWrapper>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.backgroundDark,
  },
  inner: {
    flex: 1,
  },
  padded: {
    paddingHorizontal: 16,
  },
  scrollContent: {
    flexGrow: 1,
  },
});
