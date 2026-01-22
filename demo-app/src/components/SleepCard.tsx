//
//  SleepCard.tsx
//  Component for displaying sleep data with animations
//

import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';

interface SleepCardProps {
  sleepHours: number | null;
  animated?: boolean;
}

const SleepCard: React.FC<SleepCardProps> = ({
  sleepHours,
  animated = false,
}) => {
  const animatedValue = useRef(new Animated.Value(sleepHours || 0)).current;

  useEffect(() => {
    if (animated && sleepHours !== null) {
      Animated.timing(animatedValue, {
        toValue: sleepHours,
        duration: 500,
        useNativeDriver: false,
      }).start();
    } else if (sleepHours !== null) {
      animatedValue.setValue(sleepHours);
    }
  }, [sleepHours, animated]);

  const getSleepQuality = (hours: number | null): { text: string; color: string } => {
    if (hours === null) return { text: 'No data', color: '#9C27B0' };
    if (hours < 6) return { text: 'Insufficient', color: '#F44336' };
    if (hours < 7) return { text: 'Below optimal', color: '#FF9800' };
    if (hours <= 9) return { text: 'Optimal', color: '#4CAF50' };
    return { text: 'Excessive', color: '#9C27B0' };
  };

  const quality = getSleepQuality(sleepHours);

  return (
    <View style={[styles.card, { borderLeftColor: quality.color }]}>
      <View style={styles.header}>
        <Text style={styles.icon}>😴</Text>
        <Text style={styles.title}>Sleep</Text>
      </View>
      {sleepHours !== null ? (
        <>
          {animated ? (
            <Animated.Text style={styles.value}>
              {((animatedValue as any).__getValue() || 0).toFixed(1)}
            </Animated.Text>
          ) : (
            <Text style={styles.value}>{sleepHours.toFixed(1)}</Text>
          )}
          <Text style={styles.label}>Hours (Last Night)</Text>
          <View style={styles.qualityBadge}>
            <Text style={styles.qualityText}>{quality.text}</Text>
          </View>
          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                {
                  width: `${Math.min((sleepHours / 9) * 100, 100)}%`,
                  backgroundColor: quality.color,
                },
              ]}
            />
          </View>
          <Text style={styles.recommendationText}>
            Recommended: 7-9 hours
          </Text>
        </>
      ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>No data available</Text>
          <Text style={styles.emptySubtext}>
            Sleep data will appear here when available
          </Text>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#1a1a1a', // ONVY dark card background
    borderRadius: 16,
    padding: 20,
    margin: 16,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
    borderLeftWidth: 4,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  icon: {
    fontSize: 24,
    marginRight: 8,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: 'white',
  },
  value: {
    fontSize: 48,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 4,
  },
  label: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 8,
  },
  qualityBadge: {
    alignSelf: 'flex-start',
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
    marginBottom: 12,
  },
  qualityText: {
    fontSize: 12,
    fontWeight: '600',
    color: 'white',
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    borderRadius: 4,
  },
  recommendationText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  emptyState: {
    paddingVertical: 20,
  },
  emptyText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 4,
  },
  emptySubtext: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
});

export default SleepCard;
